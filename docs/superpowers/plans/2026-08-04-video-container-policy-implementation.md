# Video Container Policy Implementation Plan

**Spec:** `docs/superpowers/specs/2026-08-04-video-container-policy-design.md`

**Objective:** Keep every checked resolution selectable. Produce compatible H.264/HEVC + AAC in MP4 and MOV, while MKV stream-copies the selected source video and converts audio to FLAC.

**Method:** Each behavior follows RED → GREEN → REFACTOR. Run the focused XCTest after every cycle, `swift test` after each task, and the complete release/E2E checks at the end.

## Task 1: Represent source codecs and processing policy

**Files:**

- Modify `Sources/Downlink/main.swift`
- Modify `Tests/DownlinkTests/DownloadCommandBuilderTests.swift`

1. Add a failing catalog test showing 2160p VP9 + Opus remains selectable for MP4, MOV, and MKV.
2. Add a failing test showing MP4 and MOV select the same source IDs and request HEVC/AAC processing.
3. Add a failing test showing MKV selects the same highest-bitrate source video but requests video copy + FLAC audio.
4. Verify each failure is caused by the current compatibility filter or missing policy.
5. Add a small value model for target container, video action, audio action, source codec, and source bitrate.
6. Make catalog selection rank all streams by the existing bitrate/size/preference rules before deriving processing policy.
7. Run focused tests and the full suite.

## Task 2: Build deterministic yt-dlp/FFmpeg post-processing arguments

**Files:**

- Modify `Sources/Downlink/main.swift`
- Modify `Tests/DownlinkTests/DownloadCommandBuilderTests.swift`

1. Add failing tests for compatible H.264/AAC stream copy into MP4 and MOV.
2. Add failing tests for VP9/AV1 conversion into HEVC/AAC MP4 and MOV, including `hvc1`, spatial AQ, bitrate floor, AAC 320 kbps, and software allowance.
3. Add failing tests for MKV video copy + FLAC audio.
4. Verify commands force an intermediate container when post-processing must run, while avoiding video conversion for already compatible sources.
5. Pass the selected processing policy through `DownloadConfiguration` into `DownloadCommandBuilder`.
6. Implement only the arguments needed for the tests, using yt-dlp's `VideoConvertor+ffmpeg_o` postprocessor arguments.
7. Refactor argument construction into policy-specific helpers and run all tests.

## Task 3: Expose conversion state and preserve cancellation semantics

**Files:**

- Modify `Sources/Downlink/main.swift`
- Modify `Tests/DownlinkTests/DownloadCommandBuilderTests.swift`

1. Add failing localization tests for a semantic `Converting` status in English, Simplified Chinese, Traditional Chinese, and Thai.
2. Add a failing log-classification test for yt-dlp VideoConvertor/FFmpeg conversion output.
3. Add a failing state-translation test confirming language changes preserve converting status.
4. Implement conversion-log detection and update status without changing layout.
5. Confirm cancellation still terminates the active process controller and does not mark the job finished.
6. Run focused and full tests.

## Task 4: Validate real post-processing behavior

**Files:**

- Add or modify test fixtures only when they are small and license-safe
- Modify implementation/tests only after a reproducing failure

1. Exercise bundled yt-dlp and FFmpeg against short H.264, VP9, and AV1 samples.
2. Validate MP4 and MOV with `ffprobe`: actual container, H.264/HEVC video, AAC audio, selected dimensions, frame rate, color metadata, title metadata, MP4 artwork, MOV's visibly disabled artwork control, and subtitle sidecars.
3. Validate MKV with `ffprobe`: selected source video codec/dimensions unchanged and FLAC audio.
4. Compare encoded video packet hashes before and after MKV processing to prove stream copy.
5. Test cancellation and an induced conversion failure; confirm no partial final filename remains.
6. Write a failing regression test before fixing any issue discovered in this task.

## Task 5: Release build, installed-app QA, and repository audit

**Files:**

- Modify `README.md` or `THIRD_PARTY_NOTICES.md` only when audit evidence requires it
- Do not touch unrelated untracked files

1. Run `swift test` and Release build.
2. Ensure the worktree has the required universal bundled FFmpeg and FFprobe for packaging.
3. Validate app version 26.0, build 2600, architectures, signature, and dependency discovery.
4. Install a recoverable candidate at `/Applications/Downlink.app`, open it, and verify only one Spotlight result.
5. Manually verify Check → quality selection → MP4/MOV/MKV download using representative URLs.
6. Verify Quick Look/QuickTime for MP4 and MOV; import into installed Premiere Pro and DaVinci Resolve when available.
7. Audit tracked files and documentation for secrets, machine-specific paths, accidental artifacts, bundled-binary notices, and README accuracy.
8. Run the `requesting-code-review` skill, address release-blocking findings with failing tests, and rerun verification.
9. Commit implementation and documentation to `codex/video-container-policy`. Do not push or publish.
