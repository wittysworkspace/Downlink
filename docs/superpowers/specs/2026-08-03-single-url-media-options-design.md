# Single-URL Media Options Design

## Status

Approved in conversation on 2026-08-03. This document defines the behavior to implement before production code changes begin.

## Goal

Make Downlink check one URL once, expose the output choices that can be fulfilled for that media, and let the user change Format or Quality without another network check. Downloads should default to the best available source, use accurate names and estimates, and leave no cache files behind.

## Scope

- Accept one URL at a time.
- Change Check so it discovers and retains available media options in memory.
- Keep the existing Video output containers: MP4, MKV, WEBM, and MOV.
- Populate Video Quality from resolutions found during Check.
- Select the highest-bitrate video stream at the chosen resolution and the best available audio stream.
- Keep Audio Quality visible but disabled with the value `Best`.
- Remove bracketed format descriptors from all Audio filenames.
- Prevent Image mode from showing source-video size as image download size.
- Change the user-visible version to `26.0` and the internal build number to `2600`.

## User Flow

1. The user selects Video, Audio, or Image mode.
2. The user enters one URL and presses Check.
3. Downlink fetches metadata and available streams once for the current URL and mode.
4. After a successful Check:
   - Video enables Format and Quality selection.
   - Audio enables Format selection and shows a disabled Quality value of `Best`.
   - Image shows its original-image behavior.
5. The user changes Format or Quality without repeating Check.
6. The checked summary, estimated size, and output filename update locally.
7. The user presses Download.

Changing URL, Mode, or cookie configuration invalidates the checked result. Changing Format, Quality, or output directory does not.

## Single-URL Input

The model stores one trimmed URL string rather than a queue of URLs. Empty input cannot be checked. Input containing more than one non-empty URL is rejected as invalid rather than silently downloading only the first item.

The interface may retain the current visual treatment, but it must behave as a single-URL field and must not advertise multi-link support.

## In-Memory Checked Options

`CheckedMediaOptions` represents the successful Check result for the current URL and mode. It contains:

- normalized source URL and the mode used for the check;
- source title, creator, duration, preview, and extractor information;
- discovered video formats, audio formats, and image items;
- known byte sizes or approximate byte sizes supplied by the source;
- the current Video resolution choice and the format IDs needed to download it;
- the best available audio format ID.

This object exists only in memory. It is replaced when a new Check begins and disappears when the app closes. No metadata cache file, cleanup command, or cache-management UI is required.

## Video Selection

Check reads all downloadable video formats without applying the user's previous Quality preset. Numeric heights are deduplicated and sorted from highest to lowest. The highest discovered resolution is selected by default.

For the selected height, Downlink selects the candidate with the highest reported total bitrate. When bitrate is missing or tied, it uses the best available size and format preference as deterministic tie-breakers. A video-only stream is combined with the best available audio stream. If the source only provides a combined stream at that height, the best combined stream is used.

Download uses the selected format IDs so the delivered resolution matches the checked selection. If those IDs are no longer available when Download starts, the download fails with a concise instruction to Check again; Downlink must not silently substitute a different resolution.

Sources that do not expose a numeric height may offer a single `Best` quality choice. Their output filename uses `[Best]` rather than inventing a resolution.

## Output Containers

Video Format remains an output-container choice: MP4, MKV, WEBM, or MOV. It does not expose extractor format IDs, codecs, or stream internals to the user. The existing ffmpeg merge/remux workflow remains responsible for producing the selected container.

Changing the output container after Check does not trigger another metadata request.

## Audio Behavior and Naming

Audio mode always selects the best available audio stream. The selected Audio Format controls conversion to MP3, M4A, WAV, FLAC, OPUS, or AAC.

The Quality control remains visible for layout consistency, displays `Best`, and is disabled. It must not show a video resolution or imply that changing video height affects audio.

Every Audio output template uses the original media title followed only by the converted extension:

- `Original title.mp3`
- `Original title.wav`
- `Original title.flac`

Bracketed descriptors such as `[WAV]` and `[MP3]` are removed from the checked summary, download history, and saved filename.

## Summary and Estimated Size

The checked summary is derived from the current in-memory selection:

- Video filename uses the selected delivered height, such as `Original title [720p].mp4`.
- Video estimated size combines the selected video and audio sizes only when the relevant size data is available; otherwise it shows `--`.
- Audio filename uses `Original title.ext` and its estimate uses the selected source audio size when available.
- Image filename retains its `[Image]` descriptor.
- Image estimated size sums the discovered image-item sizes only when those sizes are available. It never uses source-video format size. If the image size is unavailable, it shows `--`.

Changing Video Format or Quality recomputes the summary locally and does not repeat Check.

## Error Handling

- Invalid or multiple URL input: show an unavailable/validation state and do not run an extractor.
- No downloadable options for the selected mode: show Unavailable.
- Missing required tool: retain the existing Missing tools behavior.
- Selected format disappears between Check and Download: show an error that asks the user to Check again.
- Missing size metadata: show `--`; this is not an error.
- Missing numeric video height: expose `Best` rather than a guessed resolution.

## Versioning

- `AppMetadata.version`: `26.0`
- `CFBundleShortVersionString`: `26.0`
- `CFBundleVersion`: `2600`
- Build script output and version tests use the same values.

Future yearly releases may use `27.0` with build numbers beginning at `2700`.

## Test-Driven Implementation

Production changes begin only after corresponding tests fail for the expected reason. Tests cover:

1. one-URL validation and rejection of multiple URLs;
2. extraction, deduplication, and descending sorting of available heights;
3. highest resolution as the default selection;
4. highest-bitrate format selection within an exact height;
5. best-audio selection and combined-stream fallback;
6. selection changes that preserve the successful Check state;
7. Video filenames that use the selected delivered resolution;
8. Audio filenames without bracketed descriptors;
9. Audio Quality represented as disabled `Best` behavior;
10. Image size that is image-only or unknown;
11. version `26.0` and build `2600`;
12. existing command, image, history, localization, and layout regressions.

After automated tests pass, manual QA covers Video, Audio, and Image checks and downloads, selection changes without rechecking, invalid input, Thai localization, and compact layout.

## Acceptance Criteria

- One URL can be checked; multiple URLs cannot start a check.
- A successful Video Check lists the source's discovered resolutions and selects the highest by default.
- Selecting another available resolution updates the summary without network activity.
- Download uses the highest-bitrate stream at the selected resolution and best available audio.
- Saved Video filenames identify the selected delivered resolution.
- Audio Quality is visible, disabled, and reads `Best`.
- Saved Audio filenames contain only the original title and extension.
- Image size never comes from unrelated video formats.
- No Check cache file is created.
- The app and packaged build report version `26.0` with build `2600`.
