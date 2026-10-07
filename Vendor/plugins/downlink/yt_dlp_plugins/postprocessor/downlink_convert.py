import os
import re
import subprocess
import threading
import time

from yt_dlp.postprocessor.ffmpeg import FFmpegPostProcessor, FFmpegPostProcessorError
from yt_dlp.utils import PostProcessingError, prepend_extension, replace_extension


class DownlinkConvertPP(FFmpegPostProcessor):
    """Apply Downlink's codec policy even when source and target extensions match."""

    _VIDEO_ACTIONS = {"copy", "copy_hevc", "hevc"}
    _AUDIO_ACTIONS = {"none", "copy", "aac", "flac"}
    _CONTAINERS = {"mp4", "mov", "mkv"}

    def __init__(
        self,
        downloader=None,
        container=None,
        video_action=None,
        video_bitrate=None,
        audio_action=None,
        audio_bitrate=None,
        audio_stream_index=None,
        **_kwargs,
    ):
        super().__init__(downloader)
        if container not in self._CONTAINERS:
            raise PostProcessingError(f"Unsupported Downlink container: {container}")
        if video_action not in self._VIDEO_ACTIONS:
            raise PostProcessingError(f"Unsupported Downlink video action: {video_action}")
        if audio_action not in self._AUDIO_ACTIONS:
            raise PostProcessingError(f"Unsupported Downlink audio action: {audio_action}")

        self._duration = None
        self.container = container
        self.video_action = video_action
        self.video_bitrate = self._positive_int(video_bitrate, "video bitrate")
        self.audio_action = audio_action
        self.audio_bitrate = self._positive_int(audio_bitrate, "audio bitrate")
        self.audio_stream_index = self._nonnegative_int(
            audio_stream_index, "audio stream index"
        )

    @staticmethod
    def _positive_int(value, label):
        if value is None:
            return None
        try:
            parsed = int(value)
        except (TypeError, ValueError) as error:
            raise PostProcessingError(f"Invalid Downlink {label}: {value}") from error
        if parsed <= 0:
            raise PostProcessingError(f"Invalid Downlink {label}: {value}")
        return parsed

    @staticmethod
    def _nonnegative_int(value, label):
        if value is None:
            return None
        try:
            parsed = int(value)
        except (TypeError, ValueError) as error:
            raise PostProcessingError(f"Invalid Downlink {label}: {value}") from error
        if parsed < 0:
            raise PostProcessingError(f"Invalid Downlink {label}: {value}")
        return parsed

    def _options(self):
        options = [
            *self.stream_copy_opts(ext=self.container),
            "-map_metadata",
            "0",
            "-map_chapters",
            "0",
        ]

        if self.audio_stream_index is not None:
            options.extend([
                "-map",
                "-0:a",
                "-map",
                f"0:a:{self.audio_stream_index}",
            ])

        if self.video_action == "copy_hevc":
            options.extend(["-c:v:0", "copy", "-tag:v:0", "hvc1"])
        elif self.video_action == "hevc":
            if self.video_bitrate is None:
                raise PostProcessingError("Missing Downlink HEVC bitrate")
            maximum_bitrate = (self.video_bitrate * 14 + 9) // 10
            options.extend([
                "-c:v:0",
                "hevc_videotoolbox",
                "-allow_sw",
                "1",
                "-prio_speed",
                "1",
                "-spatial_aq",
                "1",
                "-b:v:0",
                f"{self.video_bitrate}k",
                "-maxrate:v:0",
                f"{maximum_bitrate}k",
                "-bufsize:v:0",
                f"{self.video_bitrate * 2}k",
                "-tag:v:0",
                "hvc1",
            ])

        if self.audio_action == "none":
            options.append("-an")
        elif self.audio_action == "aac":
            if self.audio_bitrate is None:
                raise PostProcessingError("Missing Downlink AAC bitrate")
            options.extend(["-c:a", "aac", "-b:a", f"{self.audio_bitrate}k"])
        elif self.audio_action == "flac":
            options.extend(["-c:a", "flac"])

        if self.container in {"mp4", "mov"}:
            options.extend(["-c:s", "mov_text"])

        return options

    @staticmethod
    def _format_clock(seconds):
        seconds = max(int(seconds), 0)
        return f"{seconds // 3600}:{seconds % 3600 // 60:02d}:{seconds % 60:02d}"

    def _report_progress(self, out_seconds, speed):
        duration = self._duration
        if not duration:
            return
        fraction = min(max(out_seconds / duration, 0.0), 1.0)
        message = f"Progress {fraction * 100:.1f}%"
        if speed and speed > 0:
            message += f" ETA {self._format_clock((duration - out_seconds) / speed)}"
        self.to_screen(message)

    def real_run_ffmpeg(self, input_path_opts, output_path_opts, *, expected_retcodes=(0,)):
        """Run ffmpeg like yt-dlp does, but stream `-progress` output for the UI."""
        self.check_version()

        cmd = [self.executable, "-y", "-loglevel", "repeat+info", "-nostats", "-progress", "pipe:1"]
        for kind, path_opts in (("i", input_path_opts), ("o", output_path_opts)):
            for index, (path, opts) in enumerate(path_opts, start=1):
                if not path:
                    continue
                args = list(opts)
                if kind == "i" and self.video_action == "hevc":
                    # Hardware decode is best effort; ffmpeg falls back to software.
                    args += ["-hwaccel", "videotoolbox"]
                keys = [f"_{kind}{index}", f"_{kind}"]
                if kind == "o":
                    args += ["-movflags", "+faststart"]
                    if index == 1:
                        keys.append("")
                args += self._configuration_args(self.basename, keys)
                if kind == "i":
                    args.append("-i")
                cmd += args + [self._ffmpeg_filename_argument(path)]

        self.write_debug(f"ffmpeg command line: {cmd}")
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            stdin=subprocess.DEVNULL,
            text=True,
            errors="replace",
        )
        stderr_lines = []

        def drain_stderr():
            for line in process.stderr:
                stderr_lines.append(line)
                if not self._duration:
                    match = re.search(r"Duration: (\d+):(\d{2}):(\d{2}(?:\.\d+)?)", line)
                    if match:
                        hours, minutes, seconds = match.groups()
                        self._duration = int(hours) * 3600 + int(minutes) * 60 + float(seconds)

        stderr_thread = threading.Thread(target=drain_stderr, daemon=True)
        stderr_thread.start()

        out_seconds = 0.0
        speed = None
        last_report = 0.0
        for line in process.stdout:
            key, _, value = line.strip().partition("=")
            if key in ("out_time_us", "out_time_ms"):
                try:
                    out_seconds = int(value) / 1_000_000
                except ValueError:
                    pass
            elif key == "speed":
                try:
                    speed = float(value.rstrip("x"))
                except ValueError:
                    speed = None
            elif key == "progress":
                now = time.monotonic()
                if value == "end" or now - last_report >= 1.0:
                    last_report = now
                    self._report_progress(out_seconds, speed)

        returncode = process.wait()
        stderr_thread.join()
        stderr = "".join(stderr_lines)
        if returncode not in expected_retcodes:
            self.write_debug(stderr)
            lines = stderr.strip().splitlines()
            raise FFmpegPostProcessorError(lines[-1] if lines else f"ffmpeg exited with code {returncode}")
        return stderr

    def _failure_kind(self, error):
        message = str(error).lower()
        if any(marker in message for marker in (
            "no space left on device",
            "disk quota exceeded",
            "permission denied",
            "read-only file system",
        )):
            return "storage"
        if self.video_action == "hevc" or any(marker in message for marker in (
            "encoder not found",
            "error while opening encoder",
            "failed to initialise encoder",
            "failed to initialize encoder",
        )):
            return "encoder"
        return "output"

    def _postprocessing_error(self, error):
        return PostProcessingError(
            f"[DownlinkError:{self._failure_kind(error)}] {error}"
        )

    def run(self, info):
        source_path = info["filepath"]
        source_extension = info["ext"].lower()
        final_path = replace_extension(source_path, self.container, source_extension)
        same_path = final_path == source_path
        converted_path = prepend_extension(final_path, "downlink.temp") if same_path else final_path

        self._duration = info.get("duration")
        self.to_screen(
            f"Applying {self.container.upper()} codec policy; Destination: {final_path}"
        )
        try:
            self.run_ffmpeg(source_path, converted_path, self._options())
        except Exception as error:
            if same_path and os.path.exists(converted_path):
                try:
                    os.remove(converted_path)
                except OSError:
                    pass
            raise self._postprocessing_error(error) from error

        files_to_delete = [source_path]
        if same_path:
            original_path = prepend_extension(source_path, "downlink.orig")
            try:
                os.replace(source_path, original_path)
                os.replace(converted_path, final_path)
            except Exception as error:
                if not os.path.exists(source_path) and os.path.exists(original_path):
                    try:
                        os.replace(original_path, source_path)
                    except OSError:
                        pass
                if os.path.exists(converted_path):
                    try:
                        os.remove(converted_path)
                    except OSError:
                        pass
                raise self._postprocessing_error(error) from error
            files_to_delete = [original_path]

        info["filepath"] = final_path
        info["format"] = info["ext"] = self.container
        return files_to_delete, info


__all__ = ["DownlinkConvertPP"]
