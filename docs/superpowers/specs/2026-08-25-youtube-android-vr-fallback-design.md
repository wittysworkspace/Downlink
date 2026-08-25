# YouTube Android VR Client Fallback Design

## Goal

Make YouTube downloads work more reliably without requiring cookies, a PO-token provider, a browser, or another runtime dependency.

## Scope

For a YouTube URL, Downlink will explicitly ask yt-dlp to use the `android_vr` player client during both link checking and downloading. This client currently supplies the selected audio stream for the failing example without a PO token.

The change applies to `youtube.com`, `youtu.be`, and their subdomains only. All other extractors retain their current yt-dlp arguments.

## Behavior

- Video, audio, and image checks for a YouTube URL include:
  `--extractor-args youtube:player_client=android_vr`
- Video and audio downloads for a YouTube URL include the same argument.
- No cookies, browser automation, PO-token provider, or new bundled executable is added.
- Stream selection and post-processing remain unchanged.

## Errors

This is a best-effort compatibility workaround. If YouTube later requires a PO token for `android_vr`, the download can still fail; that separate case needs an explicit PO-token solution rather than silently falling back to cookies.

## Tests

Add unit coverage that verifies the player-client argument is present for both scan and download commands for `youtu.be`, and absent for a non-YouTube URL. Run the focused test suite and the existing offline media-pipeline QA.
