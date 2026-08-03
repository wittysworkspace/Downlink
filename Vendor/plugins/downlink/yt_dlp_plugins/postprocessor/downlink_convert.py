import os

from yt_dlp.postprocessor.ffmpeg import FFmpegPostProcessor
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
                "0",
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
