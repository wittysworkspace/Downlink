import XCTest
@testable import Downlink

final class DownloadCommandBuilderTests: XCTestCase {
    func testAppTypographyUsesDBHelvethaicaX() {
        XCTAssertEqual(AppTypography.primaryFontFamily, "DB Helvethaica X")
        XCTAssertEqual(AppTypography.monospacedFontFamily, "DB HelvethaicaMon X")
    }

    func testAppTypographyUsesReadableProductScale() {
        XCTAssertEqual(AppTypography.editorSize, 17)
        XCTAssertEqual(AppTypography.bodySize, 16)
        XCTAssertEqual(AppTypography.controlSize, 16)
        XCTAssertEqual(AppTypography.sectionTitleSize, 18)
        XCTAssertEqual(AppTypography.brandTitleSize, 26)
    }

    func testCompactMenuWidthSupportsLongestFormatLabels() {
        XCTAssertGreaterThanOrEqual(AppControlMetrics.compactMenuWidth, 150)
    }

    func testPublicReleaseOnlyListsSupportedVideoFormats() {
        XCTAssertEqual(VideoFormat.allCases.map(\.rawValue), ["mp4", "mkv", "mov"])
    }

    func testPublicReleaseOnlyListsSupportedAudioFormats() {
        XCTAssertEqual(AudioFormat.allCases.map(\.rawValue), ["mp3", "m4a", "wav", "flac", "opus"])
    }

    func testAppVersionUsesCalendarYearTwentySix() {
        XCTAssertEqual(AppMetadata.version, "26.1")
    }

    func testProductMotionUsesFastStateTransitions() {
        XCTAssertEqual(AppMotion.fastDuration(reduceMotion: true), 0)
        XCTAssertEqual(AppMotion.stateDuration(reduceMotion: true), 0)
        XCTAssertLessThanOrEqual(AppMotion.fastDuration(reduceMotion: false), 0.18)
        XCTAssertLessThanOrEqual(AppMotion.stateDuration(reduceMotion: false), 0.24)
    }

    func testCheckingMotionDoesNotMoveLayout() {
        XCTAssertEqual(AppMotion.activityTransitionStyle(isChecking: true, reduceMotion: false), .fade)
        XCTAssertEqual(AppMotion.summaryPlaceholderTransitionStyle(isChecking: true, reduceMotion: false), .fade)
        XCTAssertEqual(AppMotion.activityTransitionStyle(isChecking: true, reduceMotion: true), .identity)
    }

    func testVideoSettingsShowIncludeAudioBeforeMetadata() {
        let rows = SettingsLayout.rows(for: .video, showsCookies: false)

        XCTAssertLessThan(
            rows.firstIndex(of: .includeAudio)!,
            rows.firstIndex(of: .metadata)!
        )
    }

    func testIncludeAudioSettingOnlyShowsForVideo() {
        XCTAssertTrue(SettingsLayout.rows(for: .video, showsCookies: false).contains(.includeAudio))
        XCTAssertFalse(SettingsLayout.rows(for: .audio, showsCookies: false).contains(.includeAudio))
        XCTAssertFalse(SettingsLayout.rows(for: .image, showsCookies: false).contains(.includeAudio))
    }

    func testImageSettingsDoNotShowMetadataControls() {
        XCTAssertFalse(SettingsLayout.rows(for: .image, showsCookies: false).contains(.metadata))
    }

    func testMetadataLabelDoesNotPromiseArtwork() {
        XCTAssertEqual(AppLanguage.english.metadata, "Embed metadata")
    }

    func testSettingsCheckboxRowsShareControlColumn() {
        XCTAssertEqual(SettingsLayout.checkboxControlColumnX, 102)
    }

    func testImagePreviewLayoutFitsInsideSummaryPreviewFrame() {
        let usedHeight = ImagePreviewLayout.headerHeight + ImagePreviewLayout.verticalSpacing + ImagePreviewLayout.tileHeight
        let usedWidth = CGFloat(ImagePreviewLayout.visibleTileCount) * ImagePreviewLayout.multiImageTileWidth
            + CGFloat(ImagePreviewLayout.visibleTileCount - 1) * ImagePreviewLayout.tileSpacing

        XCTAssertLessThanOrEqual(usedHeight, ImagePreviewLayout.summaryPreviewHeight)
        XCTAssertLessThanOrEqual(usedWidth, ImagePreviewLayout.summaryPreviewWidth)
        XCTAssertLessThanOrEqual(ImagePreviewLayout.multiImageTileWidth, ImagePreviewLayout.singleImageTileWidth)
    }

    func testImagePreviewPagerClampsVisibleRange() {
        let items = (1...5).map { index in
            ImageDownloadItem(
                url: URL(string: "https://cdn.example.com/\(index).jpg")!,
                title: "Image \(index)",
                id: "\(index)",
                fileExtension: "jpg",
                httpHeaders: [:]
            )
        }

        let visibleItems = ImagePreviewPager.visibleItems(from: items, startIndex: 4)

        XCTAssertEqual(visibleItems.map(\.id), ["3", "4", "5"])
    }

    func testImagePreviewPagerMovesWithinBounds() {
        XCTAssertEqual(ImagePreviewPager.nextIndex(from: 0, itemCount: 5), 1)
        XCTAssertEqual(ImagePreviewPager.nextIndex(from: 2, itemCount: 5), 2)
        XCTAssertEqual(ImagePreviewPager.previousIndex(from: 2), 1)
        XCTAssertEqual(ImagePreviewPager.previousIndex(from: 0), 0)
    }

    func testImagePreviewPagerButtonHitBoxMatchesVisibleButton() {
        XCTAssertEqual(ImagePreviewLayout.pagerButtonHitSize, ImagePreviewLayout.pagerButtonSize)
        XCTAssertGreaterThanOrEqual(ImagePreviewLayout.pagerButtonHitSize, 32)
    }

    func testDownloadHistoryPrependsLatestAndRemovesItems() {
        let first = DownloadHistoryItem(
            title: "First",
            source: "instagram.com",
            outputFilename: "First.jpg",
            estimatedSize: "--",
            previewImageURL: nil,
            sourceURLs: ["https://example.com/first"],
            kind: .image,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: true,
            outputDirectory: "/tmp"
        )
        let second = DownloadHistoryItem(
            title: "Second",
            source: "youtube.com",
            outputFilename: "Second.mp4",
            estimatedSize: "12 MB",
            previewImageURL: nil,
            sourceURLs: ["https://example.com/second"],
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: true,
            outputDirectory: "/tmp"
        )

        let history = DownloadHistoryList.removing(
            id: first.id,
            from: DownloadHistoryList.prepending(second, to: DownloadHistoryList.prepending(first, to: []))
        )

        XCTAssertEqual(history.map(\.title), ["Second"])
    }

    func testDownloadHistoryRetainsCheckedVideoSelectionForExactRepeat() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "video-720", "height": 720, "vcodec": "avc1", "acodec": "none", "tbr": 2_000],
                ["format_id": "audio-best", "vcodec": "none", "acodec": "opus", "abr": 192]
            ]
        ])
        let item = DownloadHistoryItem(
            title: "Video",
            source: "example.com",
            outputFilename: "Video [720p].mp4",
            estimatedSize: "--",
            previewImageURL: nil,
            sourceURLs: ["https://example.com/video"],
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p720,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: true,
            outputDirectory: "/tmp",
            checkedMediaFormatCatalog: catalog,
            selectedVideoQuality: VideoQualityOption(height: 720),
            checkedSignature: "checked-signature"
        )

        let restoredSelection = try XCTUnwrap(
            item.checkedMediaFormatCatalog?.videoSelection(
                height: item.selectedVideoQuality.height,
                includeAudio: item.includeVideoAudio
            )
        )

        XCTAssertEqual(restoredSelection.selector, "video-720+audio-best")
        XCTAssertEqual(item.checkedSignature, "checked-signature")
    }

    @MainActor
    func testRepeatDownloadCannotMutateActiveTransferState() {
        let model = DownloadModel()
        model.urls = "https://example.com/active"
        model.isRunning = true
        let item = DownloadHistoryItem(
            title: "Other",
            source: "example.com",
            outputFilename: "Other.mp3",
            estimatedSize: "--",
            previewImageURL: nil,
            sourceURLs: ["https://example.com/other"],
            kind: .audio,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: true,
            outputDirectory: "/tmp"
        )

        model.repeatDownload(item)

        XCTAssertEqual(model.urls, "https://example.com/active")
        XCTAssertEqual(model.kind, .video)
    }

    func testTitlebarDoubleClickPolicyOnlyAcceptsWindowChromeRow() {
        XCTAssertTrue(TitlebarDoubleClickPolicy.isInTitlebarRow(locationY: 785, windowHeight: 800))
        XCTAssertFalse(TitlebarDoubleClickPolicy.isInTitlebarRow(locationY: 735, windowHeight: 800))
        XCTAssertFalse(TitlebarDoubleClickPolicy.isInTitlebarRow(locationY: 785, windowHeight: 0))
    }

    func testLinkCheckSignatureIgnoresOutputDirectory() {
        let first = LinkCheckSignature.make(
            urls: ["https://www.instagram.com/p/example/"],
            kind: .image,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: true,
            cookieSource: .file,
            cookieFilePath: "/tmp/cookies.txt"
        )
        let second = LinkCheckSignature.make(
            urls: ["https://www.instagram.com/p/example/"],
            kind: .image,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: true,
            cookieSource: .file,
            cookieFilePath: "/tmp/cookies.txt"
        )

        XCTAssertEqual(first, second)
    }

    func testLinkCheckSignatureIgnoresOutputSelectionsAfterCheck() {
        let first = LinkCheckSignature.make(
            urls: ["https://example.com/video"],
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: true,
            cookieSource: .none,
            cookieFilePath: ""
        )
        let second = LinkCheckSignature.make(
            urls: ["https://example.com/video"],
            kind: .video,
            videoFormat: .mov,
            audioFormat: .flac,
            quality: .p480,
            includeVideoAudio: false,
            includeSubtitles: true,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: ""
        )

        XCTAssertEqual(first, second)
    }

    @MainActor
    func testDownloadModelDefaultsCookieSourceToCookiesFile() {
        XCTAssertEqual(DownloadModel().cookieSource, .file)
    }

    @MainActor
    func testAudioQualityControlIsVisibleAsDisabledBestState() {
        let model = DownloadModel()
        model.kind = .audio

        XCTAssertEqual(model.qualityControlTitle, "Best")
        XCTAssertFalse(model.isQualityControlEnabled)
    }

    @MainActor
    func testArtworkControlIsDisabledForMOVOnly() {
        let model = DownloadModel()
        model.kind = .video

        model.videoFormat = .mp4
        XCTAssertTrue(model.isArtworkControlEnabled)

        model.videoFormat = .mkv
        XCTAssertTrue(model.isArtworkControlEnabled)

        model.videoFormat = .mov
        XCTAssertFalse(model.isArtworkControlEnabled)
    }

    @MainActor
    func testDownloadModelShowsActivityWhileChecking() {
        let model = DownloadModel()

        model.linkScanState = .checking

        XCTAssertGreaterThan(model.displayedProgress, 0)
    }

    @MainActor
    func testChangingLanguagePreservesDownloadingStatus() {
        let model = DownloadModel()
        model.status = AppLanguage.english.downloading

        model.language = .thai

        XCTAssertEqual(model.status, AppLanguage.thai.downloading)
    }

    @MainActor
    func testChangingLanguagePreservesConvertingStatus() {
        let model = DownloadModel()
        model.status = AppLanguage.english.converting

        model.language = .thai

        XCTAssertEqual(model.status, AppLanguage.thai.converting)
    }

    func testVideoConvertorOutputIsRecognizedAsConversionPhase() {
        XCTAssertTrue(
            DownloadLogPhase.isConverting(
                "[VideoConvertor] Converting video from mkv to mp4; Destination: Clip.mp4"
            )
        )
        XCTAssertTrue(
            DownloadLogPhase.isConverting(
                "[DownlinkConvert] Applying MP4 codec policy; Destination: Clip.mp4"
            )
        )
        XCTAssertFalse(DownloadLogPhase.isConverting("[download] 100% of 10.00MiB"))
        XCTAssertFalse(DownloadLogPhase.isConverting("[Merger] Merging formats into Clip.mkv"))
    }

    @MainActor
    func testConversionOutputUpdatesVisibleStatusAndKeepsProgressBelowFinished() {
        let model = DownloadModel()
        model.isRunning = true
        model.progressFraction = 1

        model.consumeDownloaderOutput(
            "[download] 100% of 10.00MiB\n[VideoConvertor] Converting video from mkv to mp4\n"
        )

        XCTAssertEqual(model.status, model.language.converting)
        XCTAssertEqual(model.progressFraction, 0.98)
        XCTAssertTrue(model.logText.contains("[VideoConvertor]"))
    }

    @MainActor
    func testConversionOutputCanBeDetectedAcrossProcessChunks() {
        let model = DownloadModel()
        model.isRunning = true

        model.consumeDownloaderOutput("[DownlinkCon")
        model.consumeDownloaderOutput("vert] Applying MP4 codec policy\n")

        XCTAssertEqual(model.status, AppLanguage.english.converting)
    }

    func testDownloadFailureKindClassifiesActionablePostProcessingErrors() {
        XCTAssertEqual(
            DownloadFailureKind.detect(in: "VideoToolbox encoder failed to initialise"),
            .encoder
        )
        XCTAssertEqual(
            DownloadFailureKind.detect(in: "No space left on device"),
            .storage
        )
        XCTAssertEqual(
            DownloadFailureKind.detect(in: "Could not write header: codec not supported in container"),
            .output
        )
        XCTAssertEqual(DownloadFailureKind.detect(in: "HTTP Error 403"), .generic)
        XCTAssertEqual(
            DownloadFailureKind.detect(in: "ERROR: Postprocessing: [DownlinkError:encoder] Conversion failed!"),
            .encoder
        )
        XCTAssertEqual(
            DownloadFailureKind.detect(in: "ERROR: Postprocessing: [DownlinkError:output] Invalid argument"),
            .output
        )
        XCTAssertEqual(
            DownloadFailureKind.detect(in: "-c:v:0 hevc_videotoolbox -b:v:0 20000k"),
            .generic
        )
        XCTAssertEqual(
            DownloadFailureKind.storage.message(in: .thai),
            "พื้นที่จัดเก็บไม่เพียงพอหรือไม่สามารถเขียนไฟล์ได้ โปรดตรวจสอบโฟลเดอร์ปลายทาง"
        )
    }

    @MainActor
    func testChangingLanguagePreservesCancelledAndErrorStatuses() {
        let model = DownloadModel()
        model.status = AppLanguage.english.cancelled
        model.language = .thai
        XCTAssertEqual(model.status, AppLanguage.thai.cancelled)

        model.status = AppLanguage.thai.error
        model.language = .traditionalChinese
        XCTAssertEqual(model.status, AppLanguage.traditionalChinese.error)
    }

    @MainActor
    func testProcessStartFailureFinishesQueueAsError() {
        let model = DownloadModel()

        model.failToStart(NSError(domain: "DownlinkTests", code: 1))
        model.finishQueue()

        XCTAssertEqual(model.status, model.language.error)
        XCTAssertEqual(model.completedJobCount, 0)
        XCTAssertTrue(model.userFacingErrorMessage?.contains("DownlinkTests") == true)
    }

    @MainActor
    func testCancelKeepsTransferReservedUntilWorkerFinishes() {
        let model = DownloadModel()
        model.isRunning = true

        model.cancelDownload()

        XCTAssertTrue(model.isRunning)
        XCTAssertEqual(model.status, model.language.cancelled)
        model.finishQueue()
        XCTAssertFalse(model.isRunning)
        XCTAssertEqual(model.status, model.language.cancelled)
    }

    func testCancelledProcessControllerCannotLaunchProcessAfterCancel() throws {
        let controller = CheckProcessController()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/true")

        controller.stop(.cancelled)

        XCTAssertFalse(try controller.start(process))
        XCTAssertFalse(process.isRunning)
    }

    @MainActor
    func testDownloadModelRejectsMultipleURLs() {
        let model = DownloadModel()
        model.urls = "https://example.com/first\nhttps://example.com/second"
        model.resetLinkScan()

        XCTAssertFalse(model.canUsePrimaryButton)
        XCTAssertEqual(model.linkScanState, .unavailable)
    }

    @MainActor
    func testDownloadModelRejectsMultipleURLsOnOneLineAndInvalidText() {
        let model = DownloadModel()

        model.urls = "https://example.com/first https://example.com/second"
        model.resetLinkScan()
        XCTAssertFalse(model.canUsePrimaryButton)
        XCTAssertEqual(model.linkScanState, .unavailable)

        model.urls = "not a URL"
        model.resetLinkScan()
        XCTAssertFalse(model.canUsePrimaryButton)
        XCTAssertEqual(model.linkScanState, .unavailable)
    }

    @MainActor
    func testInstagramCheckRequiresCookiesFileWhenFileSourceIsSelected() {
        let model = DownloadModel()
        model.urls = "https://www.instagram.com/p/example/"
        model.cookieSource = .file
        model.cookieFilePath = ""

        model.checkLinks()

        XCTAssertEqual(model.linkScanState, .unavailable)
        XCTAssertTrue(model.logText.contains("Choose a cookies.txt file first."))
    }

    func testCookieSourceChoicesOnlyOfferNoneAndCookiesFile() {
        XCTAssertEqual(CookieSource.allCases, [.none, .file])
    }

    func testCookiePickerOnlyShowsForInstagramLinks() {
        XCTAssertTrue(CookiePickerVisibility.shouldShow(for: "https://www.instagram.com/p/example/"))
        XCTAssertTrue(CookiePickerVisibility.shouldShow(for: "https://instagram.com/reel/example/"))
        XCTAssertFalse(CookiePickerVisibility.shouldShow(for: "https://www.youtube.com/watch?v=example"))
        XCTAssertFalse(CookiePickerVisibility.shouldShow(for: ""))
    }

    func testURLInputCommandsTreatReturnAndKeypadEnterAsSubmit() {
        XCTAssertTrue(URLInputCommand.isSubmit(NSSelectorFromString("insertNewline:")))
        XCTAssertTrue(URLInputCommand.isSubmit(NSSelectorFromString("insertNewlineIgnoringFieldEditor:")))
        XCTAssertFalse(URLInputCommand.isSubmit(NSSelectorFromString("insertTab:")))
    }

    func testURLSubmitPolicyChecksOnlyValidUncheckedIdleInput() {
        XCTAssertEqual(
            URLSubmitPolicy.action(
                hasValidURL: true,
                isRunning: false,
                scanState: .needsCheck(count: 1),
                hasCheckedOptions: false
            ),
            .check
        )
        XCTAssertEqual(
            URLSubmitPolicy.action(
                hasValidURL: false,
                isRunning: false,
                scanState: .unavailable,
                hasCheckedOptions: false
            ),
            .none
        )
        XCTAssertEqual(
            URLSubmitPolicy.action(
                hasValidURL: true,
                isRunning: true,
                scanState: .needsCheck(count: 1),
                hasCheckedOptions: false
            ),
            .none
        )
        XCTAssertEqual(
            URLSubmitPolicy.action(
                hasValidURL: true,
                isRunning: false,
                scanState: .checking,
                hasCheckedOptions: false
            ),
            .none
        )
        XCTAssertEqual(
            URLSubmitPolicy.action(
                hasValidURL: true,
                isRunning: false,
                scanState: .ready(totalBytes: nil, count: 1, previewImageURL: nil),
                hasCheckedOptions: true
            ),
            .none
        )
    }

    func testForcedLinkRefreshDoesNotReuseValidCachedCheck() {
        XCTAssertTrue(LinkCheckCachePolicy.shouldReuse(hasValidCheck: true, forceRefresh: false))
        XCTAssertFalse(LinkCheckCachePolicy.shouldReuse(hasValidCheck: true, forceRefresh: true))
        XCTAssertFalse(LinkCheckCachePolicy.shouldReuse(hasValidCheck: false, forceRefresh: false))
    }

    func testLinkScannerTimeoutTerminatesExtractorProcess() async {
        let clock = ContinuousClock()
        let startedAt = clock.now

        let result = await LinkScanner.scanWithMetadata(
            ytDlpPath: "/bin/sh",
            argumentGroups: [["-c", "exec sleep 10"]],
            timeout: .milliseconds(50)
        )

        XCTAssertEqual(result.state, .unavailable)
        XCTAssertTrue(result.diagnosticLog.contains("timed out"))
        XCTAssertEqual(LinkCheckFailure.detect(in: result.diagnosticLog), .timedOut)
        XCTAssertEqual(
            LinkCheckFailure.timedOut.message(for: .thai),
            "การตรวจสอบลิงก์ใช้เวลานานเกินไป โปรดลองอีกครั้ง"
        )
        XCTAssertLessThan(startedAt.duration(to: clock.now), .seconds(2))
    }

    func testCancellingLinkScannerTerminatesExtractorProcess() async {
        let clock = ContinuousClock()
        let startedAt = clock.now
        let task = Task {
            await LinkScanner.scanWithMetadata(
                ytDlpPath: "/bin/sh",
                argumentGroups: [["-c", "exec sleep 10"]]
            )
        }

        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()
        let result = await task.value

        XCTAssertEqual(result.state, .unavailable)
        XCTAssertLessThan(startedAt.duration(to: clock.now), .seconds(2))
    }

    func testGalleryScannerTimeoutTerminatesRuntimeProcess() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let executable = directory.appendingPathComponent("gallery-dl-stub")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("#!/bin/sh\nexec sleep 10\n".utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let clock = ContinuousClock()
        let startedAt = clock.now
        let result = await GalleryDLImageScanner.scan(
            galleryDLPath: executable.path,
            urls: ["https://www.instagram.com/p/example/"],
            cookieFilePath: "/tmp/cookies.txt",
            timeout: .milliseconds(50)
        )

        XCTAssertTrue(result.itemsByURL.isEmpty)
        XCTAssertTrue(result.diagnosticLog.contains("timed out"))
        XCTAssertLessThan(startedAt.duration(to: clock.now), .seconds(2))
    }

    func testLinkCheckFailureRecognizesUnavailableVideoDiagnostic() {
        let diagnostic = "ERROR: [youtube] IgHuyYnexzg: Video unavailable\n"

        XCTAssertEqual(LinkCheckFailure.detect(in: diagnostic), .videoUnavailable)
        XCTAssertEqual(
            LinkCheckFailure.videoUnavailable.message(for: .english),
            "This video is unavailable. It may have been removed, made private, or restricted."
        )
        XCTAssertEqual(
            LinkCheckFailure.videoUnavailable.message(for: .thai),
            "วิดีโอนี้ไม่พร้อมใช้งาน อาจถูกลบ ตั้งเป็นส่วนตัว หรือจำกัดการเข้าถึง"
        )
    }

    func testLinkCheckFailureIgnoresUnknownOrMissingDiagnostics() {
        XCTAssertNil(LinkCheckFailure.detect(in: "WARNING: transient extractor warning\n"))
        XCTAssertNil(LinkCheckFailure.detect(in: ""))
    }

    func testLinkCheckFailureRecognizesMissingGalleryRuntime() {
        let diagnostic = "python3 not found; install Python 3 to run gallery-dl\n"

        XCTAssertEqual(LinkCheckFailure.detect(in: diagnostic), .galleryRuntimeUnavailable)
        XCTAssertEqual(
            LinkCheckFailure.galleryRuntimeUnavailable.message(for: .english),
            "Instagram Image mode requires a working Python 3 runtime for gallery-dl."
        )
    }

    func testGalleryDLImageScanOutputParsesImageURLsAndDiagnostics() {
        let output = GalleryDLImageScanner.parseOutput(
            """
            [instagram][warning] test warning
            https://cdn.example.com/first.jpg?token=1
            https://cdn.example.com/second.webp
            """,
            sourceURL: "https://www.instagram.com/p/example/"
        )

        XCTAssertEqual(output.items.map(\.url.absoluteString), [
            "https://cdn.example.com/first.jpg?token=1",
            "https://cdn.example.com/second.webp"
        ])
        XCTAssertEqual(output.items.map(\.fileExtension), ["jpg", "webp"])
        XCTAssertEqual(output.diagnosticLog, "[instagram][warning] test warning\n")
    }

    func testMetadataScanOutputKeepsDownloaderErrorsWhenNoJSONMetadataExists() {
        let output = MetadataScanOutput.parse("ERROR: [Errno 1] Operation not permitted: 'Cookies.binarycookies'\n")

        XCTAssertTrue(output.items.isEmpty)
        XCTAssertEqual(output.diagnosticLog, "ERROR: [Errno 1] Operation not permitted: 'Cookies.binarycookies'\n")
    }

    func testMetadataScanOutputIgnoresJSONLinesInDiagnostics() {
        let output = MetadataScanOutput.parse("""
        WARNING: cookies failed
        {"id":"abc","title":"Example"}
        """)

        XCTAssertEqual(output.items.first?["id"] as? String, "abc")
        XCTAssertEqual(output.diagnosticLog, "WARNING: cookies failed\n")
    }

    func testDownloadKindOrderDefaultsToVideoAudioImage() {
        XCTAssertEqual(DownloadKind.allCases.map(\.rawValue), ["video", "audio", "image"])
    }

    func testDependenciesRequireFFprobeForReliablePostProcessing() {
        let complete = DependencyStatus(
            ytDlpPath: "/app/bin/yt-dlp",
            ffmpegPath: "/app/bin/ffmpeg",
            ffprobePath: "/app/bin/ffprobe",
            galleryDLPath: nil
        )
        let missingFFprobe = DependencyStatus(
            ytDlpPath: "/app/bin/yt-dlp",
            ffmpegPath: "/app/bin/ffmpeg",
            ffprobePath: nil,
            galleryDLPath: nil
        )

        XCTAssertTrue(complete.isReady)
        XCTAssertFalse(missingFFprobe.isReady)
    }

    func testImageModeDoesNotUseVideoFormatQualityControls() {
        XCTAssertTrue(DownloadKind.video.usesFormatAndQualityControls)
        XCTAssertTrue(DownloadKind.audio.usesFormatAndQualityControls)
        XCTAssertFalse(DownloadKind.image.usesFormatAndQualityControls)
    }

    func testImageArgumentsDownloadThumbnailWithoutMediaConversion() {
        let configuration = DownloadConfiguration(
            kind: .image,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: true,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [Image].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://www.instagram.com/p/example/",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        XCTAssertTrue(arguments.contains("--write-thumbnail"))
        XCTAssertTrue(arguments.contains("--skip-download"))
        XCTAssertTrue(arguments.contains("--ignore-no-formats-error"))
        XCTAssertFalse(arguments.contains("--extract-audio"))
        XCTAssertFalse(arguments.contains("--merge-output-format"))
        XCTAssertEqual(arguments.last, "https://www.instagram.com/p/example/")
    }

    func testDownloadArgumentsDisableYtDlpUpdateWarnings() {
        let configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: true,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [1080p].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://www.youtube.com/watch?v=example",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        XCTAssertTrue(arguments.contains("--no-update"))
    }

    func testDownloadUsesIsolatedTemporaryDirectory() {
        var configuration = makeVideoConfiguration(format: .mp4)
        configuration.temporaryDirectory = "/private/tmp/Downlink-test-job"

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        XCTAssertTrue(
            zip(arguments, arguments.dropFirst()).contains { argument, value in
                argument == "--paths" && value == "temp:/private/tmp/Downlink-test-job"
            }
        )
    }

    func testTemporaryDirectoryOnlyManagesItsOwnJobPaths() throws {
        let managedPath = DownloadTemporaryDirectory.make()
        try FileManager.default.createDirectory(
            atPath: managedPath,
            withIntermediateDirectories: true
        )

        XCTAssertTrue(DownloadTemporaryDirectory.isManaged(managedPath))
        XCTAssertFalse(DownloadTemporaryDirectory.isManaged(FileManager.default.temporaryDirectory.path))
        XCTAssertFalse(DownloadTemporaryDirectory.isManaged(
            FileManager.default.temporaryDirectory.appendingPathComponent("Downlink-unrelated").path
        ))

        DownloadTemporaryDirectory.remove(managedPath)
        XCTAssertFalse(FileManager.default.fileExists(atPath: managedPath))
    }

    func testScanArgumentsDisableYtDlpUpdateWarnings() {
        let configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: true,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [1080p].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.scanArguments(
            for: "https://www.youtube.com/watch?v=example",
            configuration: configuration
        )

        XCTAssertTrue(arguments.contains("--no-update"))
    }

    func testYouTubeCommandsUseAndroidVRPlayerClientOnly() {
        let configuration = DownloadConfiguration(
            kind: .audio,
            videoFormat: .mp4,
            audioFormat: .wav,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s.%(ext)s"
        )
        let playerClient = "youtube:player_client=android_vr"
        let youtubeDownloadArguments = DownloadCommandBuilder.arguments(
            for: "https://youtu.be/example",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )
        let youtubeScanArguments = DownloadCommandBuilder.scanArguments(
            for: "https://youtu.be/example",
            configuration: configuration
        )
        let otherDownloadArguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/audio",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        for arguments in [youtubeDownloadArguments, youtubeScanArguments] {
            let extractorArgumentsIndex = arguments.firstIndex(of: "--extractor-args")
            XCTAssertEqual(extractorArgumentsIndex.map { arguments[$0 + 1] }, playerClient)
        }
        XCTAssertFalse(otherDownloadArguments.contains(playerClient))
    }

    func testVideoScanDoesNotPreselectQuality() {
        let configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p720,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [720p].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.scanArguments(
            for: "https://example.com/video",
            configuration: configuration
        )

        XCTAssertFalse(arguments.contains("--format"))
    }

    func testAudioSummaryUsesOriginalTitleWithoutFormatDescriptor() throws {
        let summary = try XCTUnwrap(MediaSummary.make(
            metadataGroups: [[[
                "title": "Original title",
                "extractor": "example"
            ]]],
            fallbackURLs: ["https://example.com/audio"],
            kind: .audio,
            videoFormat: .mp4,
            audioFormat: .wav,
            quality: .p1080,
            totalBytes: nil,
            previewImageURL: nil
        ))

        XCTAssertEqual(summary.outputFilename, "Original title.wav")
    }

    func testImageSummaryDoesNotUseSourceVideoEstimatedSize() throws {
        let summary = try XCTUnwrap(MediaSummary.make(
            metadataGroups: [[[
                "title": "Thumbnail",
                "extractor": "example"
            ]]],
            fallbackURLs: ["https://example.com/video"],
            kind: .image,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            totalBytes: 500_000,
            previewImageURL: nil
        ))

        XCTAssertEqual(summary.estimatedSize, "--")
    }

    func testMediaFormatCatalogListsRealVideoHeightsHighestFirst() {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "v720", "height": 720, "vcodec": "avc1", "acodec": "none", "tbr": 1_500],
                ["format_id": "v1080", "height": 1080, "vcodec": "avc1", "acodec": "none", "tbr": 2_800],
                ["format_id": "a", "vcodec": "none", "acodec": "opus", "abr": 160]
            ]
        ])

        XCTAssertEqual(catalog.videoQualities.map(\.height), [1080, 720])
        XCTAssertEqual(catalog.videoQualities.map(\.label), ["1080p", "720p"])
    }

    func testMediaFormatCatalogSelectsHighestBitrateAtExactHeightAndBestAudio() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "v1080-low", "height": 1080, "vcodec": "avc1", "acodec": "none", "tbr": 1_600, "filesize": 10_000_000],
                ["format_id": "v1080-high", "height": 1080, "vcodec": "vp9", "acodec": "none", "tbr": 3_200, "filesize": 20_000_000],
                ["format_id": "v720", "height": 720, "vcodec": "avc1", "acodec": "none", "tbr": 4_000],
                ["format_id": "a-low", "vcodec": "none", "acodec": "aac", "abr": 96, "filesize": 1_000_000],
                ["format_id": "a-best", "vcodec": "none", "acodec": "opus", "abr": 192, "filesize": 2_000_000]
            ]
        ])

        let selection = try XCTUnwrap(catalog.videoSelection(height: 1080, includeAudio: true))

        XCTAssertEqual(selection.videoFormatID, "v1080-high")
        XCTAssertEqual(selection.audioFormatID, "a-best")
        XCTAssertEqual(selection.selector, "v1080-high+a-best")
        XCTAssertEqual(selection.estimatedBytes, 22_000_000)
    }

    func testMP4AndMOVSelectTheSameHighestBitrateSourceStreams() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "vp9-high", "height": 1080, "vcodec": "vp9", "acodec": "none", "tbr": 4_000],
                ["format_id": "h264-compatible", "height": 1080, "vcodec": "avc1.640028", "acodec": "none", "tbr": 2_000],
                ["format_id": "opus-high", "vcodec": "none", "acodec": "opus", "abr": 192],
                ["format_id": "aac-compatible", "vcodec": "none", "acodec": "mp4a.40.2", "abr": 128]
            ]
        ])

        let movSelection = try XCTUnwrap(catalog.videoSelection(
            height: 1080,
            includeAudio: true,
            outputFormat: .mov
        ))
        let mp4Selection = try XCTUnwrap(catalog.videoSelection(
            height: 1080,
            includeAudio: true,
            outputFormat: .mp4
        ))

        XCTAssertEqual(movSelection.selector, "vp9-high+opus-high")
        XCTAssertEqual(mp4Selection.selector, movSelection.selector)
        XCTAssertEqual(catalog.compatibleVideoQualities(outputFormat: .mov, includeAudio: true).map(\.height), [1080])
        XCTAssertEqual(catalog.compatibleVideoQualities(outputFormat: .mp4, includeAudio: true).map(\.height), [1080])
    }

    func testMOVKeepsVP94KQualitySelectableForConversion() {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "vp9", "height": 2160, "vcodec": "vp9", "acodec": "none", "tbr": 8_000],
                ["format_id": "opus", "vcodec": "none", "acodec": "opus", "abr": 192]
            ]
        ])

        XCTAssertEqual(
            catalog.compatibleVideoQualities(outputFormat: .mov, includeAudio: true).map(\.height),
            [2160]
        )
    }

    func testMP4KeepsVP94KQualityAndSelectsHighestBitrateStreamsForConversion() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "vp9-4k", "height": 2160, "vcodec": "vp9", "acodec": "none", "tbr": 8_000],
                ["format_id": "av1-4k", "height": 2160, "vcodec": "av01.0.12M.08", "acodec": "none", "tbr": 4_000],
                ["format_id": "h264-1080", "height": 1080, "vcodec": "avc1.640028", "acodec": "none", "tbr": 2_000],
                ["format_id": "opus-high", "vcodec": "none", "acodec": "opus", "abr": 192],
                ["format_id": "aac-compatible", "vcodec": "none", "acodec": "mp4a.40.2", "abr": 128]
            ]
        ])

        let selection = try XCTUnwrap(catalog.videoSelection(
            height: 2160,
            includeAudio: true,
            outputFormat: .mp4
        ))

        XCTAssertEqual(selection.selector, "vp9-4k+opus-high")
        XCTAssertEqual(
            catalog.compatibleVideoQualities(outputFormat: .mp4, includeAudio: true).map(\.height),
            [2160, 1080]
        )
    }

    func testMP4VP94KSelectionRequestsHEVCAndAACAtQualityFloor() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "vp9-4k", "height": 2160, "vcodec": "vp9", "acodec": "none", "tbr": 8_000],
                ["format_id": "opus", "vcodec": "none", "acodec": "opus", "abr": 192]
            ]
        ])

        let selection = try XCTUnwrap(catalog.videoSelection(
            height: 2160,
            includeAudio: true,
            outputFormat: .mp4
        ))

        XCTAssertEqual(
            selection.processingPlan,
            VideoProcessingPlan(
                container: .mp4,
                videoAction: .hevc(targetBitrateKbps: 20_000),
                audioAction: .aac(bitRateKbps: 320)
            )
        )
    }

    func testHEV1SelectionForMP4ForcesHVC1RetagWithoutReencoding() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "hevc", "height": 2160, "vcodec": "hev1.1.6.L153", "acodec": "none", "vbr": 12_000],
                ["format_id": "aac", "vcodec": "none", "acodec": "mp4a.40.2", "abr": 192]
            ]
        ])

        let selection = try XCTUnwrap(catalog.videoSelection(
            height: 2160,
            includeAudio: true,
            outputFormat: .mp4
        ))

        XCTAssertEqual(selection.processingPlan.videoAction, .copyHEVCWithHVC1Tag)

        var configuration = makeVideoConfiguration(format: .mp4)
        configuration.selectedVideoProcessingPlan = selection.processingPlan
        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/Applications/Downlink.app/Contents/Resources/bin/ffmpeg",
            configuration: configuration
        )
        let postprocessorIndex = try XCTUnwrap(arguments.firstIndex(of: "--use-postprocessor"))
        XCTAssertTrue(arguments[postprocessorIndex + 1].contains("video_action=copy_hevc"))
    }

    func testMediaFormatCatalogUsesVideoOnlySelectorWhenAudioIsDisabled() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "video", "height": 720, "vcodec": "avc1", "acodec": "none", "tbr": 2_000],
                ["format_id": "audio", "vcodec": "none", "acodec": "opus", "abr": 160]
            ]
        ])

        let selection = try XCTUnwrap(catalog.videoSelection(height: 720, includeAudio: false))

        XCTAssertEqual(selection.selector, "video")
        XCTAssertNil(selection.audioFormatID)
    }

    func testMediaFormatCatalogChoosesHighestBitrateVideoAndAudioIndependently() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "combined", "height": 1080, "vcodec": "avc1", "acodec": "aac", "tbr": 5_100, "vbr": 5_000, "abr": 100],
                ["format_id": "video-only", "height": 1080, "vcodec": "vp9", "acodec": "none", "tbr": 4_000],
                ["format_id": "best-audio", "vcodec": "none", "acodec": "opus", "abr": 192]
            ]
        ])

        let selection = try XCTUnwrap(catalog.videoSelection(height: 1080, includeAudio: true))

        XCTAssertEqual(selection.selector, "combined+best-audio")
        XCTAssertEqual(selection.audioFormatID, "best-audio")
        XCTAssertEqual(selection.processingPlan.selectedAudioStreamIndex, 1)
    }

    func testMediaFormatCatalogKeepsHigherBitrateEmbeddedAudio() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "combined", "height": 1080, "vcodec": "avc1", "acodec": "aac", "vbr": 5_000, "abr": 256],
                ["format_id": "audio-only", "vcodec": "none", "acodec": "opus", "abr": 128]
            ]
        ])

        let selection = try XCTUnwrap(catalog.videoSelection(height: 1080, includeAudio: true))

        XCTAssertEqual(selection.selector, "combined")
        XCTAssertNil(selection.audioFormatID)
        XCTAssertNil(selection.processingPlan.selectedAudioStreamIndex)
    }

    func testCombinedTotalBitrateSubtractsAudioBeforeVideoRanking() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "combined", "height": 1080, "vcodec": "avc1", "acodec": "aac", "tbr": 5_000, "abr": 1_500],
                ["format_id": "video-only", "height": 1080, "vcodec": "vp9", "acodec": "none", "tbr": 4_000],
                ["format_id": "audio-only", "vcodec": "none", "acodec": "opus", "abr": 192]
            ]
        ])

        let selection = try XCTUnwrap(catalog.videoSelection(height: 1080, includeAudio: true))

        XCTAssertEqual(selection.videoFormatID, "video-only")
    }

    func testMediaFormatCatalogUsesCombinedStreamWhenNoSeparateAudioExists() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "combined", "height": 1080, "vcodec": "avc1", "acodec": "aac", "tbr": 3_000],
                ["format_id": "video-only", "height": 1080, "vcodec": "vp9", "acodec": "none", "tbr": 4_000]
            ]
        ])

        let selection = try XCTUnwrap(catalog.videoSelection(height: 1080, includeAudio: true))

        XCTAssertEqual(selection.selector, "combined")
    }

    func testMediaFormatCatalogFailsWhenRequestedAudioStateCannotBeFulfilled() {
        let videoOnly = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "video", "height": 720, "vcodec": "avc1", "acodec": "none", "tbr": 2_000]
            ]
        ])
        let combinedOnly = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "combined", "height": 720, "vcodec": "avc1", "acodec": "aac", "tbr": 2_000]
            ]
        ])

        XCTAssertNil(videoOnly.videoSelection(height: 720, includeAudio: true))
        XCTAssertNil(combinedOnly.videoSelection(height: 720, includeAudio: false))
        XCTAssertTrue(CheckedSelectionReadiness.hasVideoOptions(combinedOnly))
        XCTAssertTrue(CheckedSelectionReadiness.isFulfillable(
            kind: .video,
            catalog: combinedOnly,
            selectedVideoHeight: 720,
            includeVideoAudio: true
        ))
        XCTAssertFalse(CheckedSelectionReadiness.isFulfillable(
            kind: .video,
            catalog: combinedOnly,
            selectedVideoHeight: 720,
            includeVideoAudio: false
        ))
    }

    func testMediaFormatCatalogRanksVideoByVideoBitrateBeforeTotalBitrate() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "higher-vbr", "height": 720, "vcodec": "avc1", "acodec": "none", "tbr": 2_000, "vbr": 1_900],
                ["format_id": "higher-total", "height": 720, "vcodec": "vp9", "acodec": "none", "tbr": 2_500, "vbr": 1_500]
            ]
        ])

        let selection = try XCTUnwrap(catalog.videoSelection(height: 720, includeAudio: false))

        XCTAssertEqual(selection.videoFormatID, "higher-vbr")
    }

    func testQualityRefreshPreservesUserSelectionWhenNewOptionsCannotFulfillIt() {
        let selected = VideoQualityOption(height: 2160)
        let available = [VideoQualityOption(height: 1080), VideoQualityOption(height: 720)]

        XCTAssertEqual(
            VideoQualitySelection.afterRefresh(current: selected, available: available),
            selected
        )
        XCTAssertEqual(VideoQualitySelection.initial(available: available), available.first)
    }

    func testMediaFormatCatalogExposesCheckedBestAudioID() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "audio-low", "vcodec": "none", "acodec": "aac", "abr": 96],
                ["format_id": "audio-best", "vcodec": "none", "acodec": "opus", "abr": 192]
            ]
        ])

        XCTAssertEqual(try XCTUnwrap(catalog.bestAudioSelection).formatID, "audio-best")
    }

    func testMediaFormatCatalogRetainsAudioIDSelectedByCheck() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "format_id": "audio-checked",
            "vcodec": "none",
            "acodec": "aac",
            "abr": 128,
            "formats": [
                ["format_id": "audio-checked", "vcodec": "none", "acodec": "aac", "abr": 128],
                ["format_id": "audio-ranked-higher", "vcodec": "none", "acodec": "opus", "abr": 192]
            ]
        ])

        XCTAssertEqual(try XCTUnwrap(catalog.checkedAudioSelection).formatID, "audio-checked")
    }

    func testMediaFormatCatalogUsesFormatPreferenceAfterBitrateAndSizeTie() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "less-preferred", "height": 720, "vcodec": "avc1", "acodec": "none", "tbr": 2_000, "filesize": 10_000, "preference": 1],
                ["format_id": "preferred", "height": 720, "vcodec": "avc1", "acodec": "none", "tbr": 2_000, "filesize": 10_000, "preference": 5]
            ]
        ])

        let selection = try XCTUnwrap(catalog.videoSelection(height: 720, includeAudio: false))

        XCTAssertEqual(selection.videoFormatID, "preferred")
    }

    func testMediaFormatCatalogDoesNotReportPartialSizeForVideoWithAudio() throws {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "video", "height": 720, "vcodec": "avc1", "acodec": "none", "tbr": 2_000, "filesize": 10_000],
                ["format_id": "audio", "vcodec": "none", "acodec": "opus", "abr": 160]
            ]
        ])

        let selection = try XCTUnwrap(catalog.videoSelection(height: 720, includeAudio: true))

        XCTAssertNil(selection.estimatedBytes)
    }

    func testMediaFormatCatalogFallsBackToBestWhenHeightsAreUnavailable() {
        let catalog = MediaFormatCatalog.make(metadata: [
            "formats": [
                ["format_id": "video", "vcodec": "avc1", "acodec": "none", "tbr": 2_000]
            ]
        ])

        XCTAssertEqual(catalog.videoQualities, [.best])
    }

    func testVideoDownloadUsesCheckedExactFormatSelector() throws {
        var configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [1080p].%(ext)s"
        )
        configuration.selectedVideoFormatSelector = "v1080+a-best"

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        let formatIndex = try XCTUnwrap(arguments.firstIndex(of: "--format"))
        XCTAssertEqual(arguments[formatIndex + 1], "v1080+a-best")
    }

    func testVP94KMP4UsesHEVCAndAACPostProcessing() throws {
        var configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p2160,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [2160p].%(ext)s"
        )
        configuration.selectedVideoFormatSelector = "vp9+opus"
        configuration.selectedVideoProcessingPlan = VideoProcessingPlan(
            container: .mp4,
            videoAction: .hevc(targetBitrateKbps: 20_000),
            audioAction: .aac(bitRateKbps: 320)
        )
        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        let mergeIndex = try XCTUnwrap(arguments.firstIndex(of: "--merge-output-format"))
        let postprocessorIndex = try XCTUnwrap(arguments.firstIndex(of: "--use-postprocessor"))
        let postprocessorArguments = arguments[postprocessorIndex + 1]

        XCTAssertEqual(arguments[mergeIndex + 1], "mkv")
        XCTAssertTrue(postprocessorArguments.contains("container=mp4"))
        XCTAssertTrue(postprocessorArguments.contains("video_action=hevc"))
        XCTAssertTrue(postprocessorArguments.contains("video_bitrate=20000"))
        XCTAssertTrue(postprocessorArguments.contains("audio_action=aac"))
        XCTAssertTrue(postprocessorArguments.contains("audio_bitrate=320"))
        XCTAssertFalse(arguments.contains("--remux-video"))
    }

    func testRequiredConversionUsesForcedPluginInsteadOfSkippableRecode() {
        var configuration = makeVideoConfiguration(format: .mp4)
        configuration.selectedVideoProcessingPlan = VideoProcessingPlan(
            container: .mp4,
            videoAction: .hevc(targetBitrateKbps: 20_000),
            audioAction: .aac(bitRateKbps: 320)
        )
        configuration.videoPluginDirectory = "/Applications/Downlink.app/Contents/Resources/plugins"

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/combined.mp4",
            ffmpegPath: "/Applications/Downlink.app/Contents/Resources/bin/ffmpeg",
            configuration: configuration
        )

        XCTAssertTrue(arguments.contains("--plugin-dirs"))
        XCTAssertTrue(arguments.contains("/Applications/Downlink.app/Contents/Resources/plugins"))
        XCTAssertTrue(arguments.contains("--use-postprocessor"))
        XCTAssertFalse(arguments.contains("--recode-video"))
        XCTAssertFalse(arguments.contains("--postprocessor-args"))
    }

    func testIndependentCombinedVideoAndAudioSelectionKeepsOnlyChosenAudio() throws {
        var configuration = makeVideoConfiguration(format: .mp4)
        configuration.selectedVideoFormatSelector = "combined+best-audio"
        configuration.selectedVideoProcessingPlan = VideoProcessingPlan(
            container: .mp4,
            videoAction: .copy,
            audioAction: .copy,
            selectedAudioStreamIndex: 1
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/Applications/Downlink.app/Contents/Resources/bin/ffmpeg",
            configuration: configuration
        )
        let postprocessorIndex = try XCTUnwrap(arguments.firstIndex(of: "--use-postprocessor"))

        XCTAssertTrue(arguments.contains("--audio-multistreams"))
        XCTAssertTrue(arguments[postprocessorIndex + 1].contains("audio_stream_index=1"))
    }

    func testPluginDirectoryResolvesFromDevelopmentWorkspaceIndependentlyOfFFmpeg() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("DownlinkPluginResolver-\(UUID().uuidString)", isDirectory: true)
        let plugin = root.appendingPathComponent(
            "Vendor/plugins/downlink/yt_dlp_plugins/postprocessor/downlink_convert.py"
        )
        try FileManager.default.createDirectory(
            at: plugin.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try "# test plugin".write(to: plugin, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: root) }

        XCTAssertEqual(
            DownlinkPluginDirectory.resolve(
                bundleResourceURL: nil,
                currentDirectoryURL: root,
                ffmpegPath: "/opt/homebrew/bin/ffmpeg"
            ),
            root.appendingPathComponent("Vendor/plugins").path
        )
    }

    func testSelectionUnavailableMessageExplainsHowToRecover() {
        XCTAssertEqual(
            AppLanguage.english.selectionUnavailable(quality: "2160p", includeAudio: false),
            "2160p is unavailable without audio. Choose another quality or turn on Include audio."
        )
        XCTAssertTrue(
            AppLanguage.thai.selectionUnavailable(quality: "2160p", includeAudio: false)
                .contains("2160p")
        )
    }

    func testCancellingControllerTerminatesDescendantProcess() throws {
        let controller = CheckProcessController()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "sleep 30 & wait"]

        XCTAssertTrue(try controller.start(process))
        let deadline = Date().addingTimeInterval(2)
        var descendants: [pid_t] = []
        repeat {
            descendants = ProcessTree.descendantProcessIDs(of: process.processIdentifier)
            if !descendants.isEmpty { break }
            Thread.sleep(forTimeInterval: 0.02)
        } while Date() < deadline
        let childPID = try XCTUnwrap(descendants.first)

        controller.stop(.cancelled)
        process.waitUntilExit()
        let stoppedDeadline = Date().addingTimeInterval(2)
        while ProcessTree.isProcessAlive(childPID), Date() < stoppedDeadline {
            Thread.sleep(forTimeInterval: 0.02)
        }

        XCTAssertFalse(ProcessTree.isProcessAlive(childPID))
    }

    func testVP94KMOVUsesTheSameHEVCAndAACPolicyAsMP4() throws {
        var configuration = makeVideoConfiguration(format: .mov)
        configuration.selectedVideoFormatSelector = "vp9+opus"
        configuration.selectedVideoProcessingPlan = VideoProcessingPlan(
            container: .mov,
            videoAction: .hevc(targetBitrateKbps: 20_000),
            audioAction: .aac(bitRateKbps: 320)
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        let mergeIndex = try XCTUnwrap(arguments.firstIndex(of: "--merge-output-format"))
        let postprocessorIndex = try XCTUnwrap(arguments.firstIndex(of: "--use-postprocessor"))
        XCTAssertEqual(arguments[mergeIndex + 1], "mkv")
        XCTAssertTrue(arguments[postprocessorIndex + 1].contains("container=mov"))
        XCTAssertTrue(arguments[postprocessorIndex + 1].contains("video_action=hevc"))
        XCTAssertTrue(arguments[postprocessorIndex + 1].contains("audio_action=aac"))
    }

    func testCompatibleH264AndAACUseDirectRemuxWithoutReencoding() {
        var configuration = makeVideoConfiguration(format: .mp4)
        configuration.selectedVideoProcessingPlan = VideoProcessingPlan(
            container: .mp4,
            videoAction: .copy,
            audioAction: .copy
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        XCTAssertTrue(arguments.contains("--merge-output-format"))
        XCTAssertTrue(arguments.contains("--remux-video"))
        XCTAssertFalse(arguments.contains("--recode-video"))
        XCTAssertFalse(arguments.contains("--postprocessor-args"))
    }

    func testIncompatibleAudioIsConvertedWithoutReencodingCompatibleVideo() throws {
        var configuration = makeVideoConfiguration(format: .mp4)
        configuration.selectedVideoProcessingPlan = VideoProcessingPlan(
            container: .mp4,
            videoAction: .copy,
            audioAction: .aac(bitRateKbps: 320)
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        let postprocessorIndex = try XCTUnwrap(arguments.firstIndex(of: "--use-postprocessor"))
        let postprocessorArguments = arguments[postprocessorIndex + 1]
        XCTAssertTrue(postprocessorArguments.contains("video_action=copy"))
        XCTAssertTrue(postprocessorArguments.contains("audio_action=aac"))
        XCTAssertTrue(postprocessorArguments.contains("audio_bitrate=320"))
    }

    func testMKVPreservesSourceVideoAndConvertsAudioToFLAC() throws {
        var configuration = makeVideoConfiguration(format: .mkv)
        configuration.selectedVideoProcessingPlan = VideoProcessingPlan(
            container: .mkv,
            videoAction: .copy,
            audioAction: .flac
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        let mergeIndex = try XCTUnwrap(arguments.firstIndex(of: "--merge-output-format"))
        let postprocessorIndex = try XCTUnwrap(arguments.firstIndex(of: "--use-postprocessor"))
        XCTAssertEqual(arguments[mergeIndex + 1], "mkv")
        XCTAssertTrue(arguments[postprocessorIndex + 1].contains("container=mkv"))
        XCTAssertTrue(arguments[postprocessorIndex + 1].contains("video_action=copy"))
        XCTAssertTrue(arguments[postprocessorIndex + 1].contains("audio_action=flac"))
    }

    func testVideoOnlyConversionDropsAudioExplicitly() throws {
        var configuration = makeVideoConfiguration(format: .mp4, includeAudio: false)
        configuration.selectedVideoProcessingPlan = VideoProcessingPlan(
            container: .mp4,
            videoAction: .hevc(targetBitrateKbps: 8_000),
            audioAction: .none
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        let postprocessorIndex = try XCTUnwrap(arguments.firstIndex(of: "--use-postprocessor"))
        let postprocessorArguments = arguments[postprocessorIndex + 1]
        XCTAssertTrue(postprocessorArguments.contains("audio_action=none"))
    }

    private func makeVideoConfiguration(
        format: VideoFormat,
        includeAudio: Bool = true
    ) -> DownloadConfiguration {
        DownloadConfiguration(
            kind: .video,
            videoFormat: format,
            audioFormat: .mp3,
            quality: .p2160,
            includeVideoAudio: includeAudio,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [2160p].%(ext)s"
        )
    }

    func testAudioDownloadAlwaysRequestsBestAudio() throws {
        let configuration = DownloadConfiguration(
            kind: .audio,
            videoFormat: .mp4,
            audioFormat: .wav,
            quality: .p480,
            includeVideoAudio: false,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s.%(ext)s"
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/audio",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        let formatIndex = try XCTUnwrap(arguments.firstIndex(of: "--format"))
        XCTAssertEqual(arguments[formatIndex + 1], "bestaudio/best")
        XCTAssertTrue(arguments.contains("--audio-quality"))
        XCTAssertTrue(arguments.contains("0"))
    }

    func testAudioDownloadUsesCheckedExactFormatID() throws {
        var configuration = DownloadConfiguration(
            kind: .audio,
            videoFormat: .mp4,
            audioFormat: .wav,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s.%(ext)s"
        )
        configuration.selectedAudioFormatSelector = "audio-best"

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/audio",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        let formatIndex = try XCTUnwrap(arguments.firstIndex(of: "--format"))
        XCTAssertEqual(arguments[formatIndex + 1], "audio-best")
    }

    func testDynamicVideoQualityIsUsedInSummaryAndOutputTemplate() throws {
        let summary = try XCTUnwrap(MediaSummary.make(
            metadataGroups: [[["title": "Clip"]]],
            fallbackURLs: ["https://example.com/video"],
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            videoQualityLabel: "360p",
            totalBytes: nil,
            previewImageURL: nil
        ))

        XCTAssertEqual(summary.outputFilename, "Clip [360p].mp4")
        XCTAssertEqual(OutputNaming.template(kind: .video, videoQualityLabel: "360p"), "%(title)s [360p].%(ext)s")
        XCTAssertEqual(OutputNaming.template(kind: .audio, videoQualityLabel: nil), "%(title)s.%(ext)s")
    }

    func testBuildScriptUsesCalendarVersionAndBuildNumber() throws {
        let scriptURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("scripts/build_app.sh")
        let script = try String(contentsOf: scriptURL, encoding: .utf8)

        XCTAssertTrue(script.contains("APP_VERSION=\"26.1\""))
        XCTAssertTrue(script.contains("APP_BUILD=\"2601\""))
        XCTAssertTrue(script.contains("Vendor/plugins"))
        XCTAssertTrue(script.contains("$RESOURCES_DIR/plugins"))
        XCTAssertTrue(script.contains("cp -L"))
        XCTAssertTrue(script.contains("downlink_convert.py"))
        XCTAssertTrue(script.contains("__pycache__"))
        XCTAssertTrue(script.contains("*.pyc"))
        XCTAssertTrue(script.contains("Packaged tool is missing"))
    }

    func testVideoArtworkOptionEmbedsThumbnail() {
        let configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: true,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [1080p].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        XCTAssertTrue(arguments.contains("--embed-metadata"))
        XCTAssertTrue(arguments.contains("--embed-thumbnail"))
    }

    func testMOVDoesNotRequestUnsupportedArtworkEmbedding() {
        let configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mov,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: true,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [1080p].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        XCTAssertTrue(arguments.contains("--embed-metadata"))
        XCTAssertFalse(arguments.contains("--embed-thumbnail"))
    }

    func testVideoAlwaysEmbedsMetadataWhenArtworkIsOff() {
        let configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [1080p].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        XCTAssertTrue(arguments.contains("--embed-metadata"))
        XCTAssertFalse(arguments.contains("--embed-thumbnail"))
    }

    func testAudioAlwaysEmbedsMetadataWithoutArtwork() {
        let configuration = DownloadConfiguration(
            kind: .audio,
            videoFormat: .mp4,
            audioFormat: .wav,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: true,
            embedArtwork: true,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s.%(ext)s"
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/audio",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        XCTAssertTrue(arguments.contains("--embed-metadata"))
        XCTAssertFalse(arguments.contains("--embed-thumbnail"))
        XCTAssertFalse(arguments.contains("--write-subs"))
    }

    func testVideoDownloadArgumentsUseFasterSingleItemFragmentSettings() throws {
        let configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [1080p].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        let concurrentFragmentsIndex = try XCTUnwrap(arguments.firstIndex(of: "--concurrent-fragments"))
        XCTAssertEqual(arguments[concurrentFragmentsIndex + 1], "8")
        XCTAssertTrue(arguments.contains("--no-playlist"))
    }

    func testVideoWithoutAudioUsesVideoOnlyFormatSelector() throws {
        let configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p720,
            includeVideoAudio: false,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [720p].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://example.com/video",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        let formatIndex = try XCTUnwrap(arguments.firstIndex(of: "--format"))
        XCTAssertEqual(arguments[formatIndex + 1], "bv*[height<=720]/bv*/bestvideo")
        XCTAssertFalse(arguments.contains("ba"))
    }

    func testScanArgumentsForImageRequestThumbnailMetadata() {
        let configuration = DownloadConfiguration(
            kind: .image,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [Image].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.scanArguments(
            for: "https://www.instagram.com/p/example/",
            configuration: configuration
        )

        XCTAssertTrue(arguments.contains("--dump-json"))
        XCTAssertTrue(arguments.contains("--skip-download"))
        XCTAssertTrue(arguments.contains("--ignore-no-formats-error"))
        XCTAssertFalse(arguments.contains("--no-playlist"))
    }

    func testCookiesFileIsAddedWhenSelected() {
        let configuration = DownloadConfiguration(
            kind: .image,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .file,
            cookieFilePath: "/tmp/instagram-cookies.txt",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [Image].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.scanArguments(
            for: "https://www.instagram.com/p/example/",
            configuration: configuration
        )

        let cookiesIndex = arguments.firstIndex(of: "--cookies")
        XCTAssertEqual(cookiesIndex.map { arguments[$0 + 1] }, "/tmp/instagram-cookies.txt")
        XCTAssertFalse(arguments.contains("--cookies-from-browser"))
    }

    func testCookiesFileIsNotAddedWhenPathIsEmpty() {
        let configuration = DownloadConfiguration(
            kind: .image,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .file,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [Image].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.scanArguments(
            for: "https://www.instagram.com/p/example/",
            configuration: configuration
        )

        XCTAssertFalse(arguments.contains("--cookies"))
        XCTAssertFalse(arguments.contains("--cookies-from-browser"))
    }

    func testCookiesAreNotAddedForNonInstagramLinks() {
        let configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .file,
            cookieFilePath: "/tmp/instagram-cookies.txt",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s.%(ext)s"
        )

        let arguments = DownloadCommandBuilder.arguments(
            for: "https://www.youtube.com/watch?v=example",
            ffmpegPath: "/opt/homebrew/bin/ffmpeg",
            configuration: configuration
        )

        XCTAssertFalse(arguments.contains("--cookies"))
        XCTAssertFalse(arguments.contains("--cookies-from-browser"))
    }

    func testInstagramProfilePostURLIsNormalizedToCanonicalPostURL() {
        let configuration = DownloadConfiguration(
            kind: .image,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedArtwork: false,
            cookieSource: .none,
            cookieFilePath: "",
            outputDirectory: "/tmp/downlink",
            outputTemplate: "%(title)s [Image].%(ext)s"
        )

        let arguments = DownloadCommandBuilder.scanArguments(
            for: "https://www.instagram.com/pamigax/p/DY61ZYP1HSs/",
            configuration: configuration
        )

        XCTAssertEqual(arguments.last, "https://www.instagram.com/p/DY61ZYP1HSs/")
    }

    func testInstagramCanonicalPostURLStripsTrackingQuery() {
        XCTAssertEqual(
            DownloadCommandBuilder.normalizedURLString("https://www.instagram.com/p/DY61ZYP1HSs/?utm_source=ig_web_copy_link&igsh=abc"),
            "https://www.instagram.com/p/DY61ZYP1HSs/"
        )
    }

    func testImageMetadataExtractorSelectsLargestThumbnail() throws {
        let metadata: [String: Any] = [
            "id": "DY61ZYP1HSs",
            "title": "Post by pamigax",
            "http_headers": [
                "Referer": "https://www.instagram.com/"
            ],
            "thumbnails": [
                ["url": "https://cdn.example.com/small.jpg", "width": 320, "height": 320],
                ["url": "https://cdn.example.com/large.jpg", "width": 1440, "height": 1800]
            ]
        ]

        let item = try XCTUnwrap(ImageMetadataExtractor.items(from: metadata).first)

        XCTAssertEqual(item.url.absoluteString, "https://cdn.example.com/large.jpg")
        XCTAssertEqual(item.httpHeaders["Referer"], "https://www.instagram.com/")
        XCTAssertEqual(item.suggestedFilename(index: 1, total: 1), "Post by pamigax [Image].jpg")
    }

    func testImageMetadataExtractorPrefersOriginalDirectImageAndKeepsSize() throws {
        let metadata: [String: Any] = [
            "id": "image",
            "title": "Original",
            "url": "https://cdn.example.com/original.png",
            "ext": "png",
            "filesize": 2_000_000,
            "thumbnails": [
                ["url": "https://cdn.example.com/thumbnail.jpg", "width": 4000, "height": 4000]
            ]
        ]

        let item = try XCTUnwrap(ImageMetadataExtractor.items(from: metadata).first)

        XCTAssertEqual(item.url.absoluteString, "https://cdn.example.com/original.png")
        XCTAssertEqual(item.fileExtension, "png")
        XCTAssertEqual(item.bytes, 2_000_000)
    }

    func testImageMetadataExtractorRecognizesOriginalImageFromURLPathWithoutExtField() throws {
        let item = try XCTUnwrap(ImageMetadataExtractor.items(from: [
            "id": "image",
            "url": "https://cdn.example.com/original.webp",
            "thumbnails": [["url": "https://cdn.example.com/thumb.jpg", "width": 4000, "height": 4000]]
        ]).first)

        XCTAssertEqual(item.url.absoluteString, "https://cdn.example.com/original.webp")
        XCTAssertEqual(item.fileExtension, "webp")
    }

    func testImageSummaryUsesOnlyKnownImageItemSizes() throws {
        let summary = try XCTUnwrap(MediaSummary.make(
            metadataGroups: [[["title": "Image"]]],
            fallbackURLs: ["https://example.com/image"],
            kind: .image,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            totalBytes: 99_000_000,
            imageTotalBytes: 2_000_000,
            previewImageURL: nil
        ))

        XCTAssertNotEqual(summary.estimatedSize, "--")
        XCTAssertTrue(summary.estimatedSize.contains("2"))
    }

    func testImageItemSizeRequiresEveryImageSize() {
        let known = ImageDownloadItem(
            url: URL(string: "https://example.com/known.jpg")!,
            title: "Known",
            id: "known",
            fileExtension: "jpg",
            httpHeaders: [:],
            bytes: 100
        )
        let unknown = ImageDownloadItem(
            url: URL(string: "https://example.com/unknown.jpg")!,
            title: "Unknown",
            id: "unknown",
            fileExtension: "jpg",
            httpHeaders: [:]
        )

        XCTAssertEqual(ImageItemSize.totalBytes(itemsByURL: ["one": [known]]), 100)
        XCTAssertNil(ImageItemSize.totalBytes(itemsByURL: ["two": [known, unknown]]))
    }

    func testImageItemCacheUsesNormalizedURLKeysFromCheckedMetadata() {
        let metadata: [[String: Any]] = [[
            "id": "DY61ZYP1HSs",
            "title": "Post by pamigax",
            "thumbnails": [
                ["url": "https://cdn.example.com/large.jpg", "width": 1440, "height": 1800]
            ]
        ]]

        let cache = ImageItemCache.make(
            urls: ["https://www.instagram.com/pamigax/p/DY61ZYP1HSs/"],
            metadataGroups: [metadata]
        )

        XCTAssertEqual(cache["https://www.instagram.com/p/DY61ZYP1HSs/"]?.first?.url.absoluteString, "https://cdn.example.com/large.jpg")
    }

    func testImageMetadataExtractorReadsNestedEntries() {
        let metadata: [String: Any] = [
            "id": "DY61ZYP1HSs",
            "title": "Carousel post",
            "entries": [
                [
                    "id": "entry-1",
                    "title": "First image",
                    "thumbnails": [
                        ["url": "https://cdn.example.com/first.jpg", "width": 1080, "height": 1350]
                    ]
                ],
                [
                    "id": "entry-2",
                    "title": "Second image",
                    "thumbnails": [
                        ["url": "https://cdn.example.com/second.jpg", "width": 1080, "height": 1350]
                    ]
                ]
            ]
        ]

        let items = ImageMetadataExtractor.items(from: metadata)

        XCTAssertEqual(items.map(\.url.absoluteString), [
            "https://cdn.example.com/first.jpg",
            "https://cdn.example.com/second.jpg"
        ])
    }

    func testImageCheckWithoutCachedImagesIsUnavailable() {
        let state = ImageCheckValidator.validatedState(
            kind: .image,
            scanState: .ready(totalBytes: nil, count: 1, previewImageURL: nil),
            imageItemsByURL: [:]
        )

        XCTAssertEqual(state, .unavailable)
    }

    func testImageCheckWithCachedImagesStaysReady() {
        let item = ImageDownloadItem(
            url: URL(string: "https://cdn.example.com/first.jpg")!,
            title: "First image",
            id: "entry-1",
            fileExtension: "jpg",
            httpHeaders: [:]
        )

        let state = ImageCheckValidator.validatedState(
            kind: .image,
            scanState: .ready(totalBytes: nil, count: 1, previewImageURL: item.url),
            imageItemsByURL: ["https://www.instagram.com/p/DY61ZYP1HSs/": [item]]
        )

        XCTAssertEqual(state, .ready(totalBytes: nil, count: 1, previewImageURL: item.url))
    }

    func testImagePreviewItemsFollowCheckedURLOrder() {
        let firstItem = ImageDownloadItem(
            url: URL(string: "https://cdn.example.com/first.jpg")!,
            title: "First image",
            id: "entry-1",
            fileExtension: "jpg",
            httpHeaders: [:]
        )
        let secondItem = ImageDownloadItem(
            url: URL(string: "https://cdn.example.com/second.jpg")!,
            title: "Second image",
            id: "entry-2",
            fileExtension: "jpg",
            httpHeaders: [:]
        )

        let items = ImagePreviewList.items(
            for: [
                "https://www.instagram.com/p/SECOND/",
                "https://www.instagram.com/p/FIRST/"
            ],
            itemsByURL: [
                "https://www.instagram.com/p/FIRST/": [firstItem],
                "https://www.instagram.com/p/SECOND/": [secondItem]
            ]
        )

        XCTAssertEqual(items.map(\.url.absoluteString), [
            "https://cdn.example.com/second.jpg",
            "https://cdn.example.com/first.jpg"
        ])
    }

    func testImageDestinationUsesCollisionSafeFilename() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("downlink-image-collision-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let existing = directory.appendingPathComponent("Post [Image].jpg")
        try Data("existing".utf8).write(to: existing)

        let destination = ImageDestinationResolver.availableURL(
            directory: directory,
            filename: "Post [Image].jpg"
        )

        XCTAssertEqual(destination.lastPathComponent, "Post [Image] (2).jpg")
        XCTAssertEqual(try String(contentsOf: existing, encoding: .utf8), "existing")
    }

    func testCancelledImageWriteDoesNotCreateFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("downlink-image-cancel-\(UUID().uuidString)", isDirectory: true)
        let destination = directory.appendingPathComponent("cancelled.jpg")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        XCTAssertThrowsError(try ImageFileWriter.write(
            Data("image".utf8),
            directory: directory,
            filename: destination.lastPathComponent,
            cancellationCheck: { throw CancellationError() }
        ))
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testImageWriteCancelledAfterReservationRemovesEmptyFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("downlink-image-post-reserve-cancel-\(UUID().uuidString)", isDirectory: true)
        let destination = directory.appendingPathComponent("cancelled.jpg")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var cancellationChecks = 0

        XCTAssertThrowsError(try ImageFileWriter.write(
            Data("image".utf8),
            directory: directory,
            filename: destination.lastPathComponent,
            cancellationCheck: {
                cancellationChecks += 1
                if cancellationChecks == 2 { throw CancellationError() }
            }
        ))
        XCTAssertEqual(cancellationChecks, 2)
        XCTAssertFalse(FileManager.default.fileExists(atPath: destination.path))
    }

    func testImageFileWriterPreservesExistingFileAndReturnsActualSavedName() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("downlink-image-write-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let existing = directory.appendingPathComponent("Post.jpg")
        try Data("existing".utf8).write(to: existing)

        let savedURL = try ImageFileWriter.write(
            Data("new".utf8),
            directory: directory,
            filename: "Post.jpg"
        )

        XCTAssertEqual(savedURL.lastPathComponent, "Post (2).jpg")
        XCTAssertEqual(try String(contentsOf: existing, encoding: .utf8), "existing")
        XCTAssertEqual(try String(contentsOf: savedURL, encoding: .utf8), "new")
    }

    func testImagePreviewSummaryUsesNumberedCarouselFilename() {
        let first = ImageDownloadItem(
            url: URL(string: "https://cdn.example.com/first.jpg")!,
            title: "Post",
            id: "first",
            fileExtension: "jpg",
            httpHeaders: [:]
        )
        let second = ImageDownloadItem(
            url: URL(string: "https://cdn.example.com/second.jpg")!,
            title: "Post",
            id: "second",
            fileExtension: "jpg",
            httpHeaders: [:]
        )

        XCTAssertEqual(
            ImagePreviewSummary.outputFilename(items: [first, second]),
            "Post [Image] 1.jpg"
        )
    }
}
