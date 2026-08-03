# Downlink 26.0 Public Release Hardening Design

## Goal

Prepare the first public release of Downlink 26.0 so every visible control has a truthful effect, every listed format produces the advertised output, and common failures are safe and understandable.

## Supported Formats

- Video: MP4, MKV, MOV.
- Audio: MP3, M4A, WAV, FLAC, OPUS.
- Remove WEBM from the public menu because the current highest-bitrate stream selection can choose codecs that WEBM cannot contain without transcoding.
- Remove AAC from the public menu because M4A already carries AAC audio with better metadata support, while yt-dlp may produce `.m4a` for the AAC choice and contradict the advertised `.aac` filename.

## Metadata, Artwork, and Subtitles

### Video mode

- `Embed metadata` is always checked and disabled.
- `Embed artwork` is an independent, user-selectable checkbox.
- `Download subtitles when available` remains user-selectable.
- Every video download includes `--embed-metadata`.
- `--embed-thumbnail` is included only when `Embed artwork` is enabled.

### Audio mode

- `Embed metadata` is always checked and disabled.
- `Embed artwork` is visible, unchecked, and disabled.
- `Download subtitles when available` is visible, unchecked, and disabled.
- Every audio download includes `--embed-metadata`.
- Audio downloads never include `--embed-thumbnail` or subtitle arguments in 26.0.
- WAV must complete successfully because artwork embedding is no longer attempted.

### Image mode

- Do not show metadata, artwork, or subtitle controls.
- Image files remain in their discovered source format where available.

When switching modes, disabled controls must display the effective value for that mode rather than a stale checked value from another mode. Returning to Video mode may restore the user's Video artwork and subtitle choices during the current app session.

## Check Flow

- Pasting one valid URL and pressing Return starts Check.
- Changing output format, quality, artwork, subtitles, or destination after a successful Check does not require another Check.
- The visible Check button after Ready performs a real refresh, replacing cached metadata and format availability.
- Editing the URL or changing mode invalidates the previous Check.
- Cancelling or replacing a Check must terminate its downloader subprocess. A 90-second timeout prevents an extractor from running forever and returns a clear timeout message.

## Download Safety and Errors

- If a downloader process cannot start, the transfer finishes as Error, never Finished.
- A failed download shows a concise user-facing reason. Raw diagnostics may remain internal, but the UI must not show only the word `Error` when an actionable reason is available.
- Changing the interface language must translate the current semantic state without changing Downloading, Cancelled, Finished, or Error into Ready.
- Cancelling an image download cancels the active network task and checks cancellation again before writing to disk.
- Image downloads never overwrite an existing file silently. Use a collision-safe filename such as `name (2).jpg`.
- Multi-image preview filenames must match the numbered filenames that will actually be saved.

## Packaged Dependencies

- Dependency checks must verify that bundled `gallery-dl` can actually run, not merely that its wrapper script is executable.
- If a usable Python runtime is unavailable, Instagram Image mode must show a specific missing-dependency message instead of generic Unavailable.
- Bundling a standalone Python runtime is outside this hardening change unless an existing portable runtime is already present in the repository.

## Documentation

Update README behavior to match the release:

- One URL at a time.
- Explicit Check before Download; Return also starts Check.
- Dynamic qualities discovered from the source.
- Supported Video and Audio format lists above.
- Audio output names use the original title and selected extension without a bracketed format suffix.
- Clarify that M4A commonly contains AAC audio.

## Testing

Add automated coverage before implementation for:

- Public format lists exclude WEBM and AAC.
- Metadata is always included for Video and Audio.
- Video artwork adds thumbnail embedding only when enabled.
- Audio never requests artwork or subtitles; WAV arguments remain valid.
- Mode-specific control states are truthful.
- Ready-state Check refreshes rather than returning early.
- Process-start failure records Error.
- Language changes preserve the current semantic status.
- Image cancellation prevents a post-cancel write.
- Image filename collisions produce a new path without overwriting.
- Multi-image preview filenames match saved filenames.

Run the complete Swift test suite, build the release app, verify its signature and version/build values, and perform small end-to-end downloads for each remaining Video and Audio format.

## Release Acceptance

The release is ready when all automated tests pass, every remaining advertised format produces a decodable file with the advertised extension, Cancel cannot save an image after cancellation, existing images are not overwritten, and the installed app remains version 26.0 build 2600.
