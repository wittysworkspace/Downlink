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
            embedMetadata: true,
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
            embedMetadata: true,
            outputDirectory: "/tmp"
        )

        let history = DownloadHistoryList.removing(
            id: first.id,
            from: DownloadHistoryList.prepending(second, to: DownloadHistoryList.prepending(first, to: []))
        )

        XCTAssertEqual(history.map(\.title), ["Second"])
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
            embedMetadata: true,
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
            embedMetadata: true,
            cookieSource: .file,
            cookieFilePath: "/tmp/cookies.txt"
        )

        XCTAssertEqual(first, second)
    }

    @MainActor
    func testDownloadModelDefaultsCookieSourceToCookiesFile() {
        XCTAssertEqual(DownloadModel().cookieSource, .file)
    }

    @MainActor
    func testDownloadModelShowsActivityWhileChecking() {
        let model = DownloadModel()

        model.linkScanState = .checking

        XCTAssertGreaterThan(model.displayedProgress, 0)
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
            embedMetadata: true,
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
            embedMetadata: true,
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

    func testScanArgumentsDisableYtDlpUpdateWarnings() {
        let configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedMetadata: true,
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

    func testVideoMetadataDoesNotEmbedThumbnailArtwork() {
        let configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedMetadata: true,
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

    func testVideoDownloadArgumentsUseFasterSingleItemFragmentSettings() throws {
        let configuration = DownloadConfiguration(
            kind: .video,
            videoFormat: .mp4,
            audioFormat: .mp3,
            quality: .p1080,
            includeVideoAudio: true,
            includeSubtitles: false,
            embedMetadata: false,
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
            embedMetadata: false,
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
            embedMetadata: false,
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
            embedMetadata: false,
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
            embedMetadata: false,
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
            embedMetadata: false,
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
            embedMetadata: false,
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
}
