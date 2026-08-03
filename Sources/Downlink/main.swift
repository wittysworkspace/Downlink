import SwiftUI
import AppKit
import Darwin
import Foundation

private let appDisplayName = "Downlink"
private let appVersion = AppMetadata.version

enum AppMetadata {
    static let version = "26.0"
}

enum AppMotionTransitionStyle: Equatable {
    case identity
    case fade
    case topReveal
    case scaleFade
}

enum AppMotion {
    private static let fast = 0.16
    private static let state = 0.22

    static func fastDuration(reduceMotion: Bool) -> Double {
        reduceMotion ? 0 : fast
    }

    static func stateDuration(reduceMotion: Bool) -> Double {
        reduceMotion ? 0 : state
    }

    static func fastAnimation(reduceMotion: Bool) -> Animation? {
        guard !reduceMotion else { return nil }
        return .timingCurve(0.25, 1, 0.5, 1, duration: fast)
    }

    static func stateAnimation(reduceMotion: Bool) -> Animation? {
        guard !reduceMotion else { return nil }
        return .timingCurve(0.22, 1, 0.36, 1, duration: state)
    }

    static func activityTransitionStyle(isChecking: Bool, reduceMotion: Bool) -> AppMotionTransitionStyle {
        guard !reduceMotion else { return .identity }
        return isChecking ? .fade : .topReveal
    }

    static func summaryPlaceholderTransitionStyle(isChecking: Bool, reduceMotion: Bool) -> AppMotionTransitionStyle {
        guard !reduceMotion else { return .identity }
        return isChecking ? .fade : .topReveal
    }
}

enum AppTypography {
    static let primaryFontFamily = "DB Helvethaica X"
    static let monospacedFontFamily = "DB HelvethaicaMon X"
    static let captionSize: CGFloat = 14
    static let secondarySize: CGFloat = 15
    static let bodySize: CGFloat = 16
    static let controlSize: CGFloat = 16
    static let editorSize: CGFloat = 17
    static let sectionTitleSize: CGFloat = 18
    static let brandTitleSize: CGFloat = 26
    static let previewIconSize: CGFloat = 30

    private static let regularFontName = "DBHelvethaicaX-Reg"
    private static let mediumFontName = "DBHelvethaicaX-Med"

    static func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(fontName(for: weight), size: size)
    }

    static func nsFont(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        NSFont(name: nsFontName(for: weight), size: size) ?? .systemFont(ofSize: size, weight: weight)
    }

    private static func fontName(for weight: Font.Weight) -> String {
        switch weight {
        case .medium, .semibold, .bold, .heavy, .black:
            return mediumFontName
        default:
            return regularFontName
        }
    }

    private static func nsFontName(for weight: NSFont.Weight) -> String {
        weight.rawValue >= NSFont.Weight.medium.rawValue ? mediumFontName : regularFontName
    }
}

enum AppControlMetrics {
    static let compactMenuWidth: CGFloat = 150
    static let settingsFieldLabelWidth: CGFloat = 86
    static let settingsLabelToControlSpacing: CGFloat = 16
    static let settingsOutputGroupSpacing: CGFloat = 24
    static let settingsInlineControlSpacing: CGFloat = 16
    static let settingsCheckboxSpacing: CGFloat = 30
}

enum SettingsRow: Equatable {
    case modeAndFormat
    case outputDirectory
    case cookies
    case includeAudio
    case metadata
}

enum SettingsLayout {
    static let checkboxControlColumnX = AppControlMetrics.settingsFieldLabelWidth
        + AppControlMetrics.settingsLabelToControlSpacing

    static func rows(for kind: DownloadKind, showsCookies: Bool) -> [SettingsRow] {
        var rows: [SettingsRow] = [.modeAndFormat, .outputDirectory]

        if showsCookies {
            rows.append(.cookies)
        }

        if kind == .video {
            rows.append(.includeAudio)
        }

        if kind != .image {
            rows.append(.metadata)
        }
        return rows
    }
}

enum ImagePreviewLayout {
    static let summaryPreviewWidth: CGFloat = 300
    static let summaryPreviewHeight: CGFloat = 172
    static let headerHeight: CGFloat = 24
    static let verticalSpacing: CGFloat = 8
    static let tileHeight: CGFloat = 132
    static let singleImageTileWidth: CGFloat = 256
    static let multiImageTileWidth: CGFloat = 92
    static let tileSpacing: CGFloat = 10
    static let pagerButtonSize: CGFloat = 32
    static let pagerButtonHitSize: CGFloat = 32
    static let visibleTileCount = 3
}

enum ImagePreviewPager {
    static func visibleItems(from items: [ImageDownloadItem], startIndex: Int) -> [ImageDownloadItem] {
        guard !items.isEmpty else { return [] }

        let startIndex = clampedStartIndex(startIndex, itemCount: items.count)
        let endIndex = min(startIndex + ImagePreviewLayout.visibleTileCount, items.count)
        return Array(items[startIndex..<endIndex])
    }

    static func nextIndex(from currentIndex: Int, itemCount: Int) -> Int {
        clampedStartIndex(currentIndex + 1, itemCount: itemCount)
    }

    static func previousIndex(from currentIndex: Int) -> Int {
        max(currentIndex - 1, 0)
    }

    static func clampedStartIndex(_ startIndex: Int, itemCount: Int) -> Int {
        guard itemCount > 0 else { return 0 }

        let maxStartIndex = max(itemCount - ImagePreviewLayout.visibleTileCount, 0)
        return min(max(startIndex, 0), maxStartIndex)
    }
}

enum LinkCheckSignature {
    static func make(
        urls: [String],
        kind: DownloadKind,
        videoFormat _: VideoFormat,
        audioFormat _: AudioFormat,
        quality _: Quality,
        includeVideoAudio _: Bool,
        includeSubtitles _: Bool,
        embedArtwork _: Bool,
        cookieSource: CookieSource,
        cookieFilePath: String
    ) -> String {
        [
            urls.joined(separator: "\n"),
            kind.rawValue,
            cookieSource.rawValue,
            cookieFilePath
        ].joined(separator: "\u{1F}")
    }
}

enum TitlebarDoubleClickPolicy {
    static let titlebarHeight: CGFloat = 32

    static func isInTitlebarRow(locationY: CGFloat, windowHeight: CGFloat) -> Bool {
        guard windowHeight > 0 else { return false }

        return locationY >= windowHeight - titlebarHeight && locationY <= windowHeight
    }
}

struct TitlebarDoubleClickInstaller: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.install()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.install()
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.remove()
    }

    @MainActor
    final class Coordinator {
        private var monitor: Any?

        @MainActor
        func install() {
            guard monitor == nil else { return }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
                guard event.clickCount == 2,
                      let window = event.window,
                      window === NSApp.keyWindow,
                      TitlebarDoubleClickPolicy.isInTitlebarRow(
                        locationY: event.locationInWindow.y,
                        windowHeight: window.frame.height
                      ),
                      !Self.isOverStandardWindowButton(event, in: window) else {
                    return event
                }

                window.zoom(nil)
                return nil
            }
        }

        func remove() {
            guard let monitor else { return }

            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }

        private static func isOverStandardWindowButton(_ event: NSEvent, in window: NSWindow) -> Bool {
            let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
            return buttons.contains { button in
                guard let buttonView = window.standardWindowButton(button),
                      let superview = buttonView.superview else {
                    return false
                }

                let frameInWindow = superview.convert(buttonView.frame, to: nil)
                return frameInWindow.contains(event.locationInWindow)
            }
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case thai = "th"

    var id: String { rawValue }

    var menuTitle: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .thai: return "ไทย"
        }
    }

    var title: String {
        switch self {
        case .english: return appDisplayName
        case .simplifiedChinese, .traditionalChinese, .thai: return appDisplayName
        }
    }

    var subtitle: String {
        switch self {
        case .english: return "Save videos and audio you have permission to keep."
        case .simplifiedChinese: return "下载你有权保存的视频和音频。"
        case .traditionalChinese: return "下載你有權保存的影片和音訊。"
        case .thai: return "บันทึกวิดีโอและเสียงที่คุณมีสิทธิ์เก็บไว้"
        }
    }

    var ready: String {
        switch self {
        case .english: return "Ready"
        case .simplifiedChinese: return "就绪"
        case .traditionalChinese: return "就緒"
        case .thai: return "พร้อม"
        }
    }

    var downloading: String {
        switch self {
        case .english: return "Downloading"
        case .simplifiedChinese: return "下载中"
        case .traditionalChinese: return "下載中"
        case .thai: return "กำลังดาวน์โหลด"
        }
    }

    var finished: String {
        switch self {
        case .english: return "Finished"
        case .simplifiedChinese: return "已完成"
        case .traditionalChinese: return "已完成"
        case .thai: return "เสร็จแล้ว"
        }
    }

    var cancelled: String {
        switch self {
        case .english: return "Cancelled"
        case .simplifiedChinese: return "已取消"
        case .traditionalChinese: return "已取消"
        case .thai: return "ยกเลิกแล้ว"
        }
    }

    var missingTools: String {
        switch self {
        case .english: return "Missing tools"
        case .simplifiedChinese: return "缺少依赖"
        case .traditionalChinese: return "缺少依賴"
        case .thai: return "ขาดเครื่องมือ"
        }
    }

    var error: String {
        switch self {
        case .english: return "Error"
        case .simplifiedChinese: return "错误"
        case .traditionalChinese: return "錯誤"
        case .thai: return "ข้อผิดพลาด"
        }
    }

    var downloadFailed: String {
        switch self {
        case .english: return "Download failed. Check the link and try again."
        case .simplifiedChinese: return "下载失败，请检查链接后重试。"
        case .traditionalChinese: return "下載失敗，請檢查連結後再試一次。"
        case .thai: return "ดาวน์โหลดไม่สำเร็จ โปรดตรวจสอบลิงก์แล้วลองอีกครั้ง"
        }
    }

    var initialLog: String {
        ""
    }

    var links: String {
        switch self {
        case .english: return "Links"
        case .simplifiedChinese: return "链接"
        case .traditionalChinese: return "連結"
        case .thai: return "ลิงก์"
        }
    }

    var linksPlaceholder: String {
        switch self {
        case .english: return "Paste URL here"
        case .simplifiedChinese: return "在这里粘贴链接"
        case .traditionalChinese: return "在這裡貼上連結"
        case .thai: return "วาง URL ที่นี่"
        }
    }

    var saveTo: String {
        switch self {
        case .english: return "Save To"
        case .simplifiedChinese: return "保存到"
        case .traditionalChinese: return "儲存到"
        case .thai: return "บันทึกไปที่"
        }
    }

    var choose: String {
        switch self {
        case .english: return "Choose"
        case .simplifiedChinese: return "选择"
        case .traditionalChinese: return "選擇"
        case .thai: return "เลือก"
        }
    }

    var mode: String {
        switch self {
        case .english: return "Mode"
        case .simplifiedChinese: return "模式"
        case .traditionalChinese: return "模式"
        case .thai: return "โหมด"
        }
    }

    var videoFormat: String {
        switch self {
        case .english: return "Video Format"
        case .simplifiedChinese: return "视频格式"
        case .traditionalChinese: return "影片格式"
        case .thai: return "รูปแบบวิดีโอ"
        }
    }

    var audioFormat: String {
        switch self {
        case .english: return "Audio Format"
        case .simplifiedChinese: return "音频格式"
        case .traditionalChinese: return "音訊格式"
        case .thai: return "รูปแบบเสียง"
        }
    }

    var quality: String {
        switch self {
        case .english: return "Quality"
        case .simplifiedChinese: return "清晰度"
        case .traditionalChinese: return "畫質"
        case .thai: return "คุณภาพ"
        }
    }

    var options: String {
        switch self {
        case .english: return "Options"
        case .simplifiedChinese: return "选项"
        case .traditionalChinese: return "選項"
        case .thai: return "ตัวเลือก"
        }
    }

    var metadata: String {
        switch self {
        case .english: return "Embed metadata"
        case .simplifiedChinese: return "嵌入元数据"
        case .traditionalChinese: return "嵌入中繼資料"
        case .thai: return "ฝังข้อมูลเมตา"
        }
    }

    var artwork: String {
        switch self {
        case .english: return "Embed artwork"
        case .simplifiedChinese: return "嵌入封面"
        case .traditionalChinese: return "嵌入封面"
        case .thai: return "ฝังภาพปก"
        }
    }

    var subtitles: String {
        switch self {
        case .english: return "Download subtitles when available"
        case .simplifiedChinese: return "下载可用字幕"
        case .traditionalChinese: return "下載可用字幕"
        case .thai: return "ดาวน์โหลดคำบรรยายเมื่อมี"
        }
    }

    var download: String {
        switch self {
        case .english: return "Download"
        case .simplifiedChinese: return "下载"
        case .traditionalChinese: return "下載"
        case .thai: return "ดาวน์โหลด"
        }
    }

    var cancel: String {
        switch self {
        case .english: return "Cancel"
        case .simplifiedChinese: return "取消"
        case .traditionalChinese: return "取消"
        case .thai: return "ยกเลิก"
        }
    }

    var dependencyReady: String {
        switch self {
        case .english: return "Downloader, FFmpeg, and FFprobe are ready."
        case .simplifiedChinese: return "下载器、FFmpeg 和 FFprobe 已就绪。"
        case .traditionalChinese: return "下載器、FFmpeg 和 FFprobe 已就緒。"
        case .thai: return "ตัวดาวน์โหลด, FFmpeg และ FFprobe พร้อมใช้งาน"
        }
    }

    var dependencyMissing: String {
        switch self {
        case .english: return "Install yt-dlp, ffmpeg, and ffprobe, or bundle them inside the app."
        case .simplifiedChinese: return "请安装 yt-dlp、ffmpeg 和 ffprobe，或把它们内置到应用包中。"
        case .traditionalChinese: return "請安裝 yt-dlp、ffmpeg 和 ffprobe，或把它們內建到應用程式中。"
        case .thai: return "ติดตั้ง yt-dlp, ffmpeg และ ffprobe หรือรวมไว้ในแอป"
        }
    }

    var checkingLinks: String {
        switch self {
        case .english: return "Checking"
        case .simplifiedChinese: return "检测中"
        case .traditionalChinese: return "檢測中"
        case .thai: return "กำลังตรวจสอบ"
        }
    }

    var check: String {
        switch self {
        case .english: return "Check"
        case .simplifiedChinese: return "检测"
        case .traditionalChinese: return "檢測"
        case .thai: return "ตรวจสอบ"
        }
    }

    var includeAudio: String {
        switch self {
        case .english: return "Include audio"
        case .simplifiedChinese: return "包含音频"
        case .traditionalChinese: return "包含音訊"
        case .thai: return "รวมเสียง"
        }
    }

    var cookies: String {
        switch self {
        case .english: return "Cookies"
        case .simplifiedChinese: return "Cookie"
        case .traditionalChinese: return "Cookie"
        case .thai: return "คุกกี้"
        }
    }

    var cookiesFilePlaceholder: String {
        switch self {
        case .english: return "Choose cookies.txt"
        case .simplifiedChinese: return "选择 cookies.txt"
        case .traditionalChinese: return "選擇 cookies.txt"
        case .thai: return "เลือกไฟล์ cookies.txt"
        }
    }

    var chooseCookiesFileFirst: String {
        switch self {
        case .english: return "Choose a cookies.txt file first."
        case .simplifiedChinese: return "请先选择 cookies.txt 文件。"
        case .traditionalChinese: return "請先選擇 cookies.txt 檔案。"
        case .thai: return "เลือกไฟล์ cookies.txt ก่อน"
        }
    }

    func cookieSourceLabel(_ source: CookieSource) -> String {
        switch source {
        case .none:
            switch self {
            case .english: return "None"
            case .simplifiedChinese: return "无"
            case .traditionalChinese: return "無"
            case .thai: return "ไม่ใช้"
            }
        case .file:
            switch self {
            case .english: return "Cookies File"
            case .simplifiedChinese: return "Cookie 文件"
            case .traditionalChinese: return "Cookie 檔案"
            case .thai: return "ไฟล์คุกกี้"
            }
        }
    }

    var pasteLinkStatus: String {
        switch self {
        case .english: return "Paste link"
        case .simplifiedChinese: return "粘贴链接"
        case .traditionalChinese: return "貼上連結"
        case .thai: return "วางลิงก์"
        }
    }

    var unavailable: String {
        switch self {
        case .english: return "Unavailable"
        case .simplifiedChinese: return "不可用"
        case .traditionalChinese: return "不可用"
        case .thai: return "ใช้ไม่ได้"
        }
    }

    var language: String {
        switch self {
        case .english: return "Language"
        case .simplifiedChinese: return "语言"
        case .traditionalChinese: return "語言"
        case .thai: return "ภาษา"
        }
    }

    func kindLabel(_ kind: DownloadKind) -> String {
        switch kind {
        case .video:
            switch self {
            case .english: return "Video"
            case .simplifiedChinese: return "视频"
            case .traditionalChinese: return "影片"
            case .thai: return "วิดีโอ"
            }
        case .audio:
            switch self {
            case .english: return "Audio"
            case .simplifiedChinese: return "音频"
            case .traditionalChinese: return "音訊"
            case .thai: return "เสียง"
            }
        case .image:
            switch self {
            case .english: return "Image"
            case .simplifiedChinese: return "图片"
            case .traditionalChinese: return "圖片"
            case .thai: return "รูปภาพ"
            }
        }
    }

    func videoFormatLabel(_ format: VideoFormat) -> String {
        switch format {
        case .mp4: return "MP4"
        case .mkv: return "MKV"
        case .mov: return "MOV"
        }
    }

    func qualityLabel(_ quality: Quality) -> String {
        switch quality {
        case .p2160: return "4K"
        case .p1440: return "1440p"
        case .p1080: return "1080p"
        case .p720: return "720p"
        case .p480: return "480p"
        }
    }

    func missingToolLog(ytDlpFound: Bool, ffmpegFound: Bool, ffprobeFound: Bool) -> String {
        switch self {
        case .english:
            return "Missing dependency: yt-dlp \(ytDlpFound ? "found" : "missing"), ffmpeg \(ffmpegFound ? "found" : "missing"), ffprobe \(ffprobeFound ? "found" : "missing"). Install with: brew install yt-dlp ffmpeg\n"
        case .simplifiedChinese:
            return "缺少依赖：yt-dlp \(ytDlpFound ? "已找到" : "未找到")，ffmpeg \(ffmpegFound ? "已找到" : "未找到")，ffprobe \(ffprobeFound ? "已找到" : "未找到")。安装命令：brew install yt-dlp ffmpeg\n"
        case .traditionalChinese:
            return "缺少依賴：yt-dlp \(ytDlpFound ? "已找到" : "未找到")，ffmpeg \(ffmpegFound ? "已找到" : "未找到")，ffprobe \(ffprobeFound ? "已找到" : "未找到")。安裝命令：brew install yt-dlp ffmpeg\n"
        case .thai:
            return "ขาดเครื่องมือ: yt-dlp \(ytDlpFound ? "พบแล้ว" : "ไม่พบ"), ffmpeg \(ffmpegFound ? "พบแล้ว" : "ไม่พบ"), ffprobe \(ffprobeFound ? "พบแล้ว" : "ไม่พบ") ติดตั้งด้วย: brew install yt-dlp ffmpeg\n"
        }
    }
}

enum CookieSource: String, CaseIterable, Identifiable, Sendable {
    case none
    case file

    var id: String { rawValue }
}

enum InstagramURLDetector {
    static func isInstagramURL(_ rawURL: String) -> Bool {
        guard let components = URLComponents(string: rawURL),
              let host = components.host?.lowercased() else {
            return false
        }

        return host == "instagram.com" || host == "www.instagram.com"
    }

    static func postID(from rawURL: String) -> String? {
        guard isInstagramURL(rawURL),
              let components = URLComponents(string: rawURL) else {
            return nil
        }

        let pathParts = components.path
            .split(separator: "/")
            .map(String.init)

        if pathParts.count >= 2, ["p", "reel", "tv"].contains(pathParts[0]) {
            return pathParts[1]
        }

        if pathParts.count >= 3, ["p", "reel", "tv"].contains(pathParts[1]) {
            return pathParts[2]
        }

        return nil
    }
}

enum CookiePickerVisibility {
    static func shouldShow(for text: String) -> Bool {
        text
            .split(whereSeparator: \.isWhitespace)
            .contains { InstagramURLDetector.isInstagramURL(String($0)) }
    }
}

enum SingleURLInput {
    static func parse(_ text: String) -> String? {
        let tokens = text
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
        guard tokens.count == 1,
              let components = URLComponents(string: tokens[0]),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              components.host != nil else {
            return nil
        }
        return tokens[0]
    }
}

enum URLInputCommand {
    private static let submitCommandNames = [
        "insertNewline:",
        "insertNewlineIgnoringFieldEditor:"
    ]

    static func isSubmit(_ commandSelector: Selector) -> Bool {
        submitCommandNames.contains(NSStringFromSelector(commandSelector))
    }
}

enum DownloadKind: String, CaseIterable, Identifiable {
    case video
    case audio
    case image

    var id: String { rawValue }

    var usesFormatAndQualityControls: Bool {
        self != .image
    }
}

enum OutputNaming {
    static func template(kind: DownloadKind, videoQualityLabel: String?) -> String {
        switch kind {
        case .video:
            return "%(title)s [\(videoQualityLabel ?? "Best")].%(ext)s"
        case .audio:
            return "%(title)s.%(ext)s"
        case .image:
            return "%(title)s [Image].%(ext)s"
        }
    }
}

enum VideoFormat: String, CaseIterable, Identifiable {
    case mp4
    case mkv
    case mov

    var id: String { rawValue }
    var argumentValue: String? {
        rawValue
    }
}

enum AudioFormat: String, CaseIterable, Identifiable {
    case mp3
    case m4a
    case wav
    case flac
    case opus

    var id: String { rawValue }
}

enum Quality: String, CaseIterable, Identifiable {
    case p2160
    case p1440
    case p1080
    case p720
    case p480

    var id: String { rawValue }

    var maxHeight: Int {
        switch self {
        case .p2160: return 2160
        case .p1440: return 1440
        case .p1080: return 1080
        case .p720: return 720
        case .p480: return 480
        }
    }

    var formatSelector: String {
        return "bv*[height<=\(maxHeight)]+ba/b[height<=\(maxHeight)][acodec!=none]/bv*+ba/b[acodec!=none]/b"
    }

    var videoOnlyFormatSelector: String {
        "bv*[height<=\(maxHeight)]/bv*/bestvideo"
    }

    var filenameLabel: String {
        switch self {
        case .p2160: return "4k"
        case .p1440: return "1440p"
        case .p1080: return "1080p"
        case .p720: return "720p"
        case .p480: return "480p"
        }
    }
}

struct VideoQualityOption: Equatable, Identifiable, Sendable {
    let height: Int?

    static let best = VideoQualityOption(height: nil)

    var id: String {
        height.map(String.init) ?? "best"
    }

    var label: String {
        height.map { "\($0)p" } ?? "Best"
    }
}

struct VideoStreamSelection: Equatable, Sendable {
    let height: Int?
    let videoFormatID: String
    let audioFormatID: String?
    let selector: String
    let estimatedBytes: Int64?
}

struct AudioStreamSelection: Equatable, Sendable {
    let formatID: String
    let estimatedBytes: Int64?
}

struct MediaFormatCatalog: Equatable, Sendable {
    private struct MediaFormat: Equatable, Sendable {
        let id: String
        let height: Int?
        let hasVideo: Bool
        let hasAudio: Bool
        let videoCodec: String
        let audioCodec: String
        let videoBitrate: Double
        let audioBitrate: Double
        let bytes: Int64?
        let preference: Double
    }

    private let formats: [MediaFormat]
    let videoQualities: [VideoQualityOption]
    let checkedAudioSelection: AudioStreamSelection?

    static func make(metadata: [String: Any]) -> MediaFormatCatalog {
        let sourceFormats: [[String: Any]] = {
            if let formats = metadata["formats"] as? [[String: Any]], !formats.isEmpty {
                return formats
            }
            if let formats = metadata["requested_formats"] as? [[String: Any]], !formats.isEmpty {
                return formats
            }
            return [metadata]
        }()
        let formats = sourceFormats.compactMap { format -> MediaFormat? in
            guard let id = stringValue(format["format_id"]), !id.isEmpty else { return nil }

            let videoCodec = stringValue(format["vcodec"])
            let audioCodec = stringValue(format["acodec"])
            let hasVideo = videoCodec.map { $0 != "none" } ?? false
            let hasAudio = audioCodec.map { $0 != "none" } ?? false
            guard hasVideo || hasAudio else { return nil }

            return MediaFormat(
                id: id,
                height: intValue(format["height"]),
                hasVideo: hasVideo,
                hasAudio: hasAudio,
                videoCodec: videoCodec?.lowercased() ?? "none",
                audioCodec: audioCodec?.lowercased() ?? "none",
                videoBitrate: doubleValue(format["tbr"]) ?? doubleValue(format["vbr"]) ?? 0,
                audioBitrate: doubleValue(format["abr"]) ?? (hasAudio && !hasVideo ? doubleValue(format["tbr"]) : nil) ?? 0,
                bytes: int64Value(format["filesize"]) ?? int64Value(format["filesize_approx"]),
                preference: doubleValue(format["preference"]) ?? 0
            )
        }

        let heights = Set(formats.filter(\.hasVideo).compactMap(\.height)).sorted(by: >)
        let qualities = heights.isEmpty ? [.best] : heights.map { VideoQualityOption(height: $0) }
        return MediaFormatCatalog(
            formats: formats,
            videoQualities: qualities,
            checkedAudioSelection: checkedAudioSelection(from: metadata)
        )
    }

    func compatibleVideoQualities(
        outputFormat: VideoFormat,
        includeAudio: Bool
    ) -> [VideoQualityOption] {
        videoQualities.filter {
            videoSelection(
                height: $0.height,
                includeAudio: includeAudio,
                outputFormat: outputFormat
            ) != nil
        }
    }

    func videoSelection(
        height: Int?,
        includeAudio: Bool,
        outputFormat: VideoFormat = .mkv
    ) -> VideoStreamSelection? {
        let allVideoCandidates = formats.filter { format in
            format.hasVideo
                && (height == nil || format.height == height)
                && supportsVideo(format, in: outputFormat)
        }
        let videoOnlyCandidates = allVideoCandidates.filter { !$0.hasAudio }
        let combinedCandidates = allVideoCandidates.filter {
            $0.hasAudio && supportsAudio($0, in: outputFormat)
        }
        let audio = bestAudioOnlyFormat(in: outputFormat)
        let videoCandidates: [MediaFormat]
        if includeAudio {
            if audio != nil, !videoOnlyCandidates.isEmpty {
                videoCandidates = videoOnlyCandidates
            } else if !combinedCandidates.isEmpty {
                videoCandidates = combinedCandidates
            } else {
                return nil
            }
        } else {
            guard !videoOnlyCandidates.isEmpty else { return nil }
            videoCandidates = videoOnlyCandidates
        }
        guard let video = videoCandidates.max(by: { left, right in
            if left.videoBitrate == right.videoBitrate {
                if (left.bytes ?? 0) == (right.bytes ?? 0) {
                    if left.preference == right.preference {
                        return left.id > right.id
                    }
                    return left.preference < right.preference
                }
                return (left.bytes ?? 0) < (right.bytes ?? 0)
            }
            return left.videoBitrate < right.videoBitrate
        }) else {
            return nil
        }

        guard includeAudio, !video.hasAudio else {
            return VideoStreamSelection(
                height: video.height ?? height,
                videoFormatID: video.id,
                audioFormatID: nil,
                selector: video.id,
                estimatedBytes: video.bytes
            )
        }

        let selectedAudio = includeAudio && !video.hasAudio ? audio : nil
        let estimatedBytes: Int64?
        if let videoBytes = video.bytes, let audioBytes = selectedAudio?.bytes {
            estimatedBytes = videoBytes + audioBytes
        } else if selectedAudio == nil {
            estimatedBytes = video.bytes
        } else {
            estimatedBytes = nil
        }

        return VideoStreamSelection(
            height: video.height ?? height,
            videoFormatID: video.id,
            audioFormatID: selectedAudio?.id,
            selector: selectedAudio.map { "\(video.id)+\($0.id)" } ?? video.id,
            estimatedBytes: estimatedBytes
        )
    }

    var bestAudioSelection: AudioStreamSelection? {
        bestAudioFormat.map {
            AudioStreamSelection(formatID: $0.id, estimatedBytes: $0.bytes)
        }
    }

    private var bestAudioFormat: MediaFormat? {
        bestAudioOnlyFormat ?? bestFormat(in: formats.filter(\.hasAudio), bitrate: \.audioBitrate)
    }

    private var bestAudioOnlyFormat: MediaFormat? {
        bestFormat(in: formats.filter { $0.hasAudio && !$0.hasVideo }, bitrate: \.audioBitrate)
    }

    private func bestAudioOnlyFormat(in outputFormat: VideoFormat) -> MediaFormat? {
        bestFormat(
            in: formats.filter {
                $0.hasAudio && !$0.hasVideo && supportsAudio($0, in: outputFormat)
            },
            bitrate: \.audioBitrate
        )
    }

    private func supportsVideo(_ format: MediaFormat, in outputFormat: VideoFormat) -> Bool {
        switch outputFormat {
        case .mkv:
            return true
        case .mp4:
            return codec(format.videoCodec, hasAnyPrefix: [
                "avc1", "h264", "hev1", "hvc1", "hevc", "av01", "av1", "vp9", "vp09", "mpeg4"
            ])
        case .mov:
            return codec(format.videoCodec, hasAnyPrefix: [
                "avc1", "h264", "hev1", "hvc1", "hevc", "mpeg4"
            ])
        }
    }

    private func supportsAudio(_ format: MediaFormat, in outputFormat: VideoFormat) -> Bool {
        switch outputFormat {
        case .mkv:
            return true
        case .mp4:
            return codec(format.audioCodec, hasAnyPrefix: ["mp4a", "aac", "mp3", "opus"])
        case .mov:
            return codec(format.audioCodec, hasAnyPrefix: ["mp4a", "aac", "mp3"])
        }
    }

    private func codec(_ codec: String, hasAnyPrefix prefixes: [String]) -> Bool {
        prefixes.contains { codec.hasPrefix($0) }
    }

    private func bestFormat(
        in candidates: [MediaFormat],
        bitrate: KeyPath<MediaFormat, Double>
    ) -> MediaFormat? {
        return candidates.max(by: { left, right in
                if left[keyPath: bitrate] == right[keyPath: bitrate] {
                    if (left.bytes ?? 0) == (right.bytes ?? 0) {
                        if left.preference == right.preference {
                            return left.id > right.id
                        }
                        return left.preference < right.preference
                    }
                    return (left.bytes ?? 0) < (right.bytes ?? 0)
                }
                return left[keyPath: bitrate] < right[keyPath: bitrate]
            })
    }

    private static func stringValue(_ value: Any?) -> String? {
        value as? String
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? String { return Double(value) }
        return nil
    }

    private static func intValue(_ value: Any?) -> Int? {
        doubleValue(value).map { Int($0.rounded()) }
    }

    private static func int64Value(_ value: Any?) -> Int64? {
        doubleValue(value).map { Int64($0.rounded()) }
    }

    private static func checkedAudioSelection(from metadata: [String: Any]) -> AudioStreamSelection? {
        let requestedFormats = metadata["requested_formats"] as? [[String: Any]] ?? []
        let candidates = requestedFormats + [metadata]
        let audioOnly = candidates.first { format in
            let hasAudio = stringValue(format["acodec"]).map { $0 != "none" } ?? false
            let hasVideo = stringValue(format["vcodec"]).map { $0 != "none" } ?? false
            return hasAudio && !hasVideo && stringValue(format["format_id"]) != nil
        }
        let selected = audioOnly ?? candidates.first { format in
            (stringValue(format["acodec"]).map { $0 != "none" } ?? false)
                && stringValue(format["format_id"]) != nil
        }
        guard let selected, let id = stringValue(selected["format_id"]) else { return nil }
        return AudioStreamSelection(
            formatID: id,
            estimatedBytes: int64Value(selected["filesize"]) ?? int64Value(selected["filesize_approx"])
        )
    }
}

enum CheckedSelectionReadiness {
    static func hasVideoOptions(
        _ catalog: MediaFormatCatalog,
        outputFormat: VideoFormat = .mkv
    ) -> Bool {
        catalog.videoQualities.contains { quality in
            catalog.videoSelection(
                height: quality.height,
                includeAudio: true,
                outputFormat: outputFormat
            ) != nil
                || catalog.videoSelection(
                    height: quality.height,
                    includeAudio: false,
                    outputFormat: outputFormat
                ) != nil
        }
    }

    static func isFulfillable(
        kind: DownloadKind,
        catalog: MediaFormatCatalog?,
        selectedVideoHeight: Int?,
        includeVideoAudio: Bool,
        videoFormat: VideoFormat = .mkv
    ) -> Bool {
        switch kind {
        case .video:
            return catalog?.videoSelection(
                height: selectedVideoHeight,
                includeAudio: includeVideoAudio,
                outputFormat: videoFormat
            ) != nil
        case .audio:
            return catalog?.checkedAudioSelection != nil
        case .image:
            return true
        }
    }
}

struct DependencyStatus: Sendable {
    let ytDlpPath: String?
    let ffmpegPath: String?
    let ffprobePath: String?
    let galleryDLPath: String?

    var isReady: Bool {
        ytDlpPath != nil && ffmpegPath != nil && ffprobePath != nil
    }
}

enum LinkScanState: Equatable, Sendable {
    case empty
    case needsCheck(count: Int)
    case checking
    case ready(totalBytes: Int64?, count: Int, previewImageURL: URL?)
    case unavailable
    case missingTools
}

enum URLSubmitAction: Equatable {
    case check
    case none
}

enum URLSubmitPolicy {
    static func action(
        hasValidURL: Bool,
        isRunning: Bool,
        scanState: LinkScanState,
        hasCheckedOptions: Bool
    ) -> URLSubmitAction {
        guard hasValidURL,
              !isRunning,
              scanState != .checking,
              !hasCheckedOptions else {
            return .none
        }

        return .check
    }
}

enum LinkCheckCachePolicy {
    static func shouldReuse(hasValidCheck: Bool, forceRefresh: Bool) -> Bool {
        hasValidCheck && !forceRefresh
    }
}

enum LinkCheckFailure: Equatable, Sendable {
    case videoUnavailable
    case galleryRuntimeUnavailable
    case timedOut

    static func detect(in diagnosticLog: String) -> LinkCheckFailure? {
        if diagnosticLog.localizedCaseInsensitiveContains("video unavailable") {
            return .videoUnavailable
        }
        if diagnosticLog.localizedCaseInsensitiveContains("python3 not found")
            || diagnosticLog.localizedCaseInsensitiveContains("no module named gallery_dl") {
            return .galleryRuntimeUnavailable
        }
        if diagnosticLog.localizedCaseInsensitiveContains("link check timed out") {
            return .timedOut
        }
        return nil
    }

    func message(for language: AppLanguage) -> String {
        switch self {
        case .videoUnavailable:
            switch language {
            case .english:
                return "This video is unavailable. It may have been removed, made private, or restricted."
            case .simplifiedChinese:
                return "此视频不可用，可能已被删除、设为私密或受到访问限制。"
            case .traditionalChinese:
                return "此影片無法使用，可能已被刪除、設為私人或受到存取限制。"
            case .thai:
                return "วิดีโอนี้ไม่พร้อมใช้งาน อาจถูกลบ ตั้งเป็นส่วนตัว หรือจำกัดการเข้าถึง"
            }
        case .galleryRuntimeUnavailable:
            switch language {
            case .english:
                return "Instagram Image mode requires a working Python 3 runtime for gallery-dl."
            case .simplifiedChinese:
                return "Instagram 图片模式需要可供 gallery-dl 使用的 Python 3 运行环境。"
            case .traditionalChinese:
                return "Instagram 圖片模式需要可供 gallery-dl 使用的 Python 3 執行環境。"
            case .thai:
                return "โหมดรูปภาพ Instagram ต้องใช้ Python 3 ที่พร้อมทำงานสำหรับ gallery-dl"
            }
        case .timedOut:
            switch language {
            case .english:
                return "The link check took too long. Please try again."
            case .simplifiedChinese:
                return "链接检查耗时过长，请重试。"
            case .traditionalChinese:
                return "連結檢查耗時過長，請再試一次。"
            case .thai:
                return "การตรวจสอบลิงก์ใช้เวลานานเกินไป โปรดลองอีกครั้ง"
            }
        }
    }
}

struct LinkScanResult: @unchecked Sendable {
    let state: LinkScanState
    let metadataGroups: [[[String: Any]]]
    let diagnosticLog: String
}

struct MediaSummary {
    let title: String
    let source: String
    let creator: String
    let duration: String
    let estimatedSize: String
    let outputFilename: String
    let previewImageURL: URL?

    static func make(
        metadataGroups: [[[String: Any]]],
        fallbackURLs: [String],
        kind: DownloadKind,
        videoFormat: VideoFormat,
        audioFormat: AudioFormat,
        quality: Quality,
        videoQualityLabel: String? = nil,
        totalBytes: Int64?,
        imageTotalBytes: Int64? = nil,
        previewImageURL: URL?
    ) -> MediaSummary? {
        let metadata = metadataGroups.first?.first
        let fallbackURL = fallbackURLs.first ?? ""
        let title = stringValue(metadata?["title"])
            ?? stringValue(metadata?["fulltitle"])
            ?? URL(string: fallbackURL)?.host
            ?? "Ready to download"
        let source = stringValue(metadata?["extractor"])
            ?? stringValue(metadata?["extractor_key"])
            ?? URL(string: fallbackURL)?.host?
                .replacingOccurrences(of: "www.", with: "")
            ?? "Source"
        let creator = stringValue(metadata?["uploader"])
            ?? stringValue(metadata?["channel"])
            ?? stringValue(metadata?["creator"])
            ?? ""
        let duration = durationLabel(from: metadata?["duration"]) ?? "--"
        let estimatedSize = (kind == .image ? imageTotalBytes : totalBytes).map(byteLabelForUI) ?? "--"
        let fileExtension = fileExtension(kind: kind, videoFormat: videoFormat, audioFormat: audioFormat)
        let outputFilename: String

        if kind == .audio {
            outputFilename = "\(title).\(fileExtension)"
        } else {
            let descriptor = kind == .video
                ? (videoQualityLabel ?? quality.filenameLabel)
                : outputDescriptor(kind: kind, videoFormat: videoFormat, audioFormat: audioFormat, quality: quality)
            outputFilename = "\(title) [\(descriptor)].\(fileExtension)"
        }

        return MediaSummary(
            title: title,
            source: source,
            creator: creator,
            duration: duration,
            estimatedSize: estimatedSize,
            outputFilename: outputFilename,
            previewImageURL: previewImageURL
        )
    }

    private static func outputDescriptor(kind: DownloadKind, videoFormat: VideoFormat, audioFormat: AudioFormat, quality: Quality) -> String {
        switch kind {
        case .video:
            quality.filenameLabel
        case .audio:
            audioFormat.rawValue.uppercased()
        case .image:
            "Image"
        }
    }

    private static func fileExtension(kind: DownloadKind, videoFormat: VideoFormat, audioFormat: AudioFormat) -> String {
        switch kind {
        case .video:
            videoFormat.rawValue
        case .audio:
            audioFormat.rawValue
        case .image:
            "jpg"
        }
    }

    private static func stringValue(_ value: Any?) -> String? {
        guard let text = value as? String else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func durationLabel(from value: Any?) -> String? {
        let seconds: Double?
        if let double = value as? Double {
            seconds = double
        } else if let int = value as? Int {
            seconds = Double(int)
        } else if let number = value as? NSNumber {
            seconds = number.doubleValue
        } else {
            seconds = nil
        }

        guard let seconds else { return nil }
        let totalSeconds = max(Int(seconds.rounded()), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }

        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    static func byteLabelForUI(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }

    func replacingOutputFilename(_ outputFilename: String) -> MediaSummary {
        MediaSummary(
            title: title,
            source: source,
            creator: creator,
            duration: duration,
            estimatedSize: estimatedSize,
            outputFilename: outputFilename,
            previewImageURL: previewImageURL
        )
    }
}

struct DownloadHistoryItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let source: String
    let outputFilename: String
    let estimatedSize: String
    let previewImageURL: URL?
    let sourceURLs: [String]
    let kind: DownloadKind
    let videoFormat: VideoFormat
    let audioFormat: AudioFormat
    let quality: Quality
    let includeVideoAudio: Bool
    let includeSubtitles: Bool
    let embedArtwork: Bool
    let outputDirectory: String
    let imageItemsByURL: [String: [ImageDownloadItem]]
    let checkedMediaFormatCatalog: MediaFormatCatalog?
    let selectedVideoQuality: VideoQualityOption
    let checkedSignature: String?
    let completedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        source: String,
        outputFilename: String,
        estimatedSize: String,
        previewImageURL: URL?,
        sourceURLs: [String],
        kind: DownloadKind,
        videoFormat: VideoFormat,
        audioFormat: AudioFormat,
        quality: Quality,
        includeVideoAudio: Bool,
        includeSubtitles: Bool,
        embedArtwork: Bool,
        outputDirectory: String,
        imageItemsByURL: [String: [ImageDownloadItem]] = [:],
        checkedMediaFormatCatalog: MediaFormatCatalog? = nil,
        selectedVideoQuality: VideoQualityOption = .best,
        checkedSignature: String? = nil,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.source = source
        self.outputFilename = outputFilename
        self.estimatedSize = estimatedSize
        self.previewImageURL = previewImageURL
        self.sourceURLs = sourceURLs
        self.kind = kind
        self.videoFormat = videoFormat
        self.audioFormat = audioFormat
        self.quality = quality
        self.includeVideoAudio = includeVideoAudio
        self.includeSubtitles = includeSubtitles
        self.embedArtwork = embedArtwork
        self.outputDirectory = outputDirectory
        self.imageItemsByURL = imageItemsByURL
        self.checkedMediaFormatCatalog = checkedMediaFormatCatalog
        self.selectedVideoQuality = selectedVideoQuality
        self.checkedSignature = checkedSignature
        self.completedAt = completedAt
    }

    var mediaSummary: MediaSummary {
        MediaSummary(
            title: title,
            source: source,
            creator: "",
            duration: "--",
            estimatedSize: estimatedSize,
            outputFilename: outputFilename,
            previewImageURL: previewImageURL
        )
    }
}

enum DownloadHistoryList {
    static let maxItems = 100

    static func prepending(_ item: DownloadHistoryItem, to items: [DownloadHistoryItem]) -> [DownloadHistoryItem] {
        Array(([item] + items).prefix(maxItems))
    }

    static func removing(id: DownloadHistoryItem.ID, from items: [DownloadHistoryItem]) -> [DownloadHistoryItem] {
        items.filter { $0.id != id }
    }
}

struct ImageURLScanResult: Sendable {
    let items: [ImageDownloadItem]
    let diagnosticLog: String
}

struct DownloadConfiguration: Sendable, Equatable {
    let kind: DownloadKind
    let videoFormat: VideoFormat
    let audioFormat: AudioFormat
    let quality: Quality
    let includeVideoAudio: Bool
    let includeSubtitles: Bool
    let embedArtwork: Bool
    let cookieSource: CookieSource
    let cookieFilePath: String
    let outputDirectory: String
    let outputTemplate: String
    var selectedVideoFormatSelector: String? = nil
    var selectedAudioFormatSelector: String? = nil
}

enum DownloadCommandBuilder {
    static func arguments(for url: String, ffmpegPath: String, configuration: DownloadConfiguration) -> [String] {
        var args: [String] = [
            "--newline",
            "--progress",
            "--no-update",
            "--no-mtime",
            "--ffmpeg-location", URL(fileURLWithPath: ffmpegPath).deletingLastPathComponent().path,
            "--paths", configuration.outputDirectory,
            "--trim-filenames", "180",
            "--output", configuration.outputTemplate
        ]

        appendCookieArguments(to: &args, configuration: configuration, url: url)

        switch configuration.kind {
        case .video:
            appendFasterSingleItemDownloadArguments(to: &args)
            args.append("--embed-metadata")
            if configuration.embedArtwork {
                args.append("--embed-thumbnail")
            }

            if configuration.includeSubtitles {
                args.append("--write-subs")
                args.append("--write-auto-subs")
                args.append("--sub-langs")
                args.append("all,-live_chat")
            }

            let selector = configuration.selectedVideoFormatSelector
                ?? (configuration.includeVideoAudio ? configuration.quality.formatSelector : configuration.quality.videoOnlyFormatSelector)
            args.append(contentsOf: ["--format", selector])
            if let outputFormat = configuration.videoFormat.argumentValue {
                args.append("--merge-output-format")
                args.append(outputFormat)
                args.append("--remux-video")
                args.append(outputFormat)
            }
        case .audio:
            appendFasterSingleItemDownloadArguments(to: &args)
            args.append("--embed-metadata")

            args.append(contentsOf: ["--format", configuration.selectedAudioFormatSelector ?? "bestaudio/best"])
            args.append("--extract-audio")
            args.append("--audio-format")
            args.append(configuration.audioFormat.rawValue)
            args.append("--audio-quality")
            args.append("0")
        case .image:
            args.append("--ignore-no-formats-error")
            args.append("--write-thumbnail")
            args.append("--skip-download")
        }

        args.append(normalizedURLString(url))
        return args
    }

    private static func appendFasterSingleItemDownloadArguments(to args: inout [String]) {
        args.append("--no-playlist")
        args.append("--concurrent-fragments")
        args.append("8")
    }

    static func scanArguments(for url: String, configuration: DownloadConfiguration) -> [String] {
        var args = [
            "--dump-json",
            "--skip-download",
            "--no-update",
            "--no-warnings"
        ]

        appendCookieArguments(to: &args, configuration: configuration, url: url)

        switch configuration.kind {
        case .video:
            args.append("--no-playlist")
        case .audio:
            args.append("--no-playlist")
            args.append(contentsOf: ["--format", "bestaudio/best"])
        case .image:
            args.append("--ignore-no-formats-error")
        }

        args.append(normalizedURLString(url))
        return args
    }

    private static func appendCookieArguments(to args: inout [String], configuration: DownloadConfiguration, url: String) {
        guard configuration.cookieSource == .file else { return }
        guard InstagramURLDetector.isInstagramURL(url) else { return }
        let cookieFilePath = configuration.cookieFilePath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cookieFilePath.isEmpty else { return }
        args.append("--cookies")
        args.append(cookieFilePath)
    }

    static func normalizedURLString(_ rawURL: String) -> String {
        guard let components = URLComponents(string: rawURL),
              InstagramURLDetector.isInstagramURL(rawURL) else {
            return rawURL
        }

        let pathParts = components.path
            .split(separator: "/")
            .map(String.init)

        let typeIndex: Int
        if pathParts.count >= 2, ["p", "reel", "tv"].contains(pathParts[0]) {
            typeIndex = 0
        } else if pathParts.count >= 3, ["p", "reel", "tv"].contains(pathParts[1]) {
            typeIndex = 1
        } else {
            return rawURL
        }

        var normalized = components
        normalized.path = "/\(pathParts[typeIndex])/\(pathParts[typeIndex + 1])/"
        normalized.query = nil
        normalized.fragment = nil
        return normalized.string ?? rawURL
    }
}

struct ImageDownloadItem: Sendable, Equatable {
    let url: URL
    let title: String
    let id: String
    let fileExtension: String
    let httpHeaders: [String: String]
    let bytes: Int64?

    init(
        url: URL,
        title: String,
        id: String,
        fileExtension: String,
        httpHeaders: [String: String],
        bytes: Int64? = nil
    ) {
        self.url = url
        self.title = title
        self.id = id
        self.fileExtension = fileExtension
        self.httpHeaders = httpHeaders
        self.bytes = bytes
    }

    func suggestedFilename(index: Int, total: Int) -> String {
        let base = sanitizeFilename(title.isEmpty ? id : title)
        let suffix = total > 1 ? " \(index)" : ""
        return "\(base) [Image]\(suffix).\(fileExtension)"
    }

    private func sanitizeFilename(_ value: String) -> String {
        let forbidden = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = value
            .components(separatedBy: forbidden)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Instagram image" : String(cleaned.prefix(160))
    }
}

enum ImagePreviewSummary {
    static func outputFilename(items: [ImageDownloadItem]) -> String? {
        items.first?.suggestedFilename(index: 1, total: items.count)
    }
}

enum ImageDestinationResolver {
    static func availableURL(directory: URL, filename: String) -> URL {
        let original = directory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: original.path) else {
            return original
        }

        let filenameValue = filename as NSString
        let pathExtension = filenameValue.pathExtension
        let stem = filenameValue.deletingPathExtension
        var copyNumber = 2
        while true {
            let candidateName = pathExtension.isEmpty
                ? "\(stem) (\(copyNumber))"
                : "\(stem) (\(copyNumber)).\(pathExtension)"
            let candidate = directory.appendingPathComponent(candidateName)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            copyNumber += 1
        }
    }
}

enum ImageFileWriter {
    static func write(
        _ data: Data,
        directory: URL,
        filename: String,
        cancellationCheck: () throws -> Void = { try Task.checkCancellation() }
    ) throws -> URL {
        while true {
            try cancellationCheck()
            let destination = ImageDestinationResolver.availableURL(
                directory: directory,
                filename: filename
            )
            let descriptor = open(
                destination.path,
                O_WRONLY | O_CREAT | O_EXCL,
                S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH
            )
            if descriptor == -1 {
                if errno == EEXIST { continue }
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }

            let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
            do {
                try cancellationCheck()
                try handle.write(contentsOf: data)
                try handle.synchronize()
                try handle.close()
                return destination
            } catch {
                try? handle.close()
                try? FileManager.default.removeItem(at: destination)
                throw error
            }
        }
    }
}

enum ImageItemSize {
    static func totalBytes(itemsByURL: [String: [ImageDownloadItem]]) -> Int64? {
        let items = itemsByURL.values.flatMap { $0 }
        guard !items.isEmpty else { return nil }
        let sizes = items.compactMap(\.bytes)
        guard sizes.count == items.count else { return nil }
        return sizes.reduce(0, +)
    }
}

enum ImageMetadataExtractor {
    static func items(from metadata: [String: Any]) -> [ImageDownloadItem] {
        if let entries = metadata["entries"] as? [[String: Any]] {
            let parentTitle = (metadata["title"] as? String) ?? (metadata["fulltitle"] as? String) ?? ""
            return entries.enumerated().flatMap { offset, entry -> [ImageDownloadItem] in
                var merged = entry
                if merged["title"] == nil, !parentTitle.isEmpty {
                    merged["title"] = "\(parentTitle) \(offset + 1)"
                }
                if merged["http_headers"] == nil {
                    merged["http_headers"] = metadata["http_headers"]
                }
                return items(from: merged)
            }
        }

        guard let image = bestImage(from: metadata) else { return [] }
        let title = (metadata["title"] as? String) ?? (metadata["fulltitle"] as? String) ?? ""
        let id = (metadata["id"] as? String) ?? "instagram-image"
        return [
            ImageDownloadItem(
                url: image.url,
                title: title,
                id: id,
                fileExtension: imageExtension(for: image.url, metadata: metadata),
                httpHeaders: httpHeaders(from: metadata),
                bytes: image.bytes
            )
        ]
    }

    private static func bestImage(from metadata: [String: Any]) -> (url: URL, bytes: Int64?)? {
        if let value = metadata["url"] as? String,
           let url = URL(string: value) {
            let ext = (metadata["ext"] as? String)?.lowercased() ?? url.pathExtension.lowercased()
            guard ["jpg", "jpeg", "png", "webp"].contains(ext) else {
                return bestThumbnail(from: metadata)
            }
            return (url, numericInt64(metadata["filesize"]) ?? numericInt64(metadata["filesize_approx"]))
        }

        return bestThumbnail(from: metadata)
    }

    private static func bestThumbnail(from metadata: [String: Any]) -> (url: URL, bytes: Int64?)? {
        if let thumbnails = metadata["thumbnails"] as? [[String: Any]] {
            let candidates = thumbnails.compactMap { thumbnail -> (url: URL, area: Int, bytes: Int64?)? in
                guard let value = thumbnail["url"] as? String,
                      let url = URL(string: value) else {
                    return nil
                }
                let width = numericInt(thumbnail["width"]) ?? 0
                let height = numericInt(thumbnail["height"]) ?? 0
                return (
                    url,
                    width * height,
                    numericInt64(thumbnail["filesize"]) ?? numericInt64(thumbnail["filesize_approx"])
                )
            }

            if let best = candidates.max(by: { $0.area < $1.area }) {
                return (best.url, best.bytes)
            }
        }

        if let thumbnail = metadata["thumbnail"] as? String,
           let url = URL(string: thumbnail) {
            return (url, nil)
        }

        return nil
    }

    private static func imageExtension(for url: URL, metadata: [String: Any]) -> String {
        if let ext = (metadata["ext"] as? String)?.lowercased(),
           ["jpg", "jpeg", "png", "webp"].contains(ext) {
            return ext == "jpeg" ? "jpg" : ext
        }

        let pathExtension = url.pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "webp"].contains(pathExtension) {
            return pathExtension == "jpeg" ? "jpg" : pathExtension
        }

        return "jpg"
    }

    private static func numericInt(_ value: Any?) -> Int? {
        switch value {
        case let int as Int:
            return int
        case let int64 as Int64:
            return Int(int64)
        case let double as Double:
            return Int(double)
        case let string as String:
            return Int(string)
        default:
            return nil
        }
    }

    private static func numericInt64(_ value: Any?) -> Int64? {
        switch value {
        case let value as Int64:
            return value
        case let value as Int:
            return Int64(value)
        case let value as Double:
            return Int64(value.rounded())
        case let value as NSNumber:
            return value.int64Value
        case let value as String:
            return Double(value).map { Int64($0.rounded()) }
        default:
            return nil
        }
    }

    private static func httpHeaders(from metadata: [String: Any]) -> [String: String] {
        var headers = (metadata["http_headers"] as? [String: Any])?.compactMapValues { value in
            value as? String
        } ?? [:]

        headers["Referer"] = headers["Referer"] ?? "https://www.instagram.com/"
        headers["User-Agent"] = headers["User-Agent"] ?? "Mozilla/5.0"
        return headers
    }
}

enum ImageItemCache {
    static func make(urls: [String], metadataGroups: [[[String: Any]]]) -> [String: [ImageDownloadItem]] {
        var cache: [String: [ImageDownloadItem]] = [:]

        for (url, metadataItems) in zip(urls, metadataGroups) {
            let imageItems = metadataItems.flatMap(ImageMetadataExtractor.items(from:))
            guard !imageItems.isEmpty else { continue }
            cache[DownloadCommandBuilder.normalizedURLString(url)] = imageItems
        }

        return cache
    }
}

enum ImagePreviewList {
    static func items(for urls: [String], itemsByURL: [String: [ImageDownloadItem]]) -> [ImageDownloadItem] {
        urls.flatMap { url in
            itemsByURL[DownloadCommandBuilder.normalizedURLString(url), default: []]
        }
    }
}

final class CheckProcessController: @unchecked Sendable {
    enum StopReason {
        case cancelled
        case timedOut
    }

    private let lock = NSLock()
    private var process: Process?
    private var stopReason: StopReason?
    private var isComplete = false

    func start(_ process: Process) throws -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard stopReason == nil, !isComplete else { return false }
        self.process = process
        try process.run()
        return true
    }

    func stop(_ reason: StopReason) {
        lock.lock()
        guard stopReason == nil, !isComplete else {
            lock.unlock()
            return
        }
        stopReason = reason
        let activeProcess = process
        lock.unlock()

        if activeProcess?.isRunning == true {
            activeProcess?.terminate()
        }
    }

    func complete() -> StopReason? {
        lock.lock()
        defer { lock.unlock() }
        isComplete = true
        process = nil
        return stopReason
    }
}

enum GalleryDLImageScanner {
    private struct OrderedImageScanOutput: Sendable {
        let index: Int
        let url: String
        let result: ImageURLScanResult
    }

    static func scan(
        galleryDLPath: String,
        urls: [String],
        cookieFilePath: String,
        timeout: Duration = .seconds(90)
    ) async -> (itemsByURL: [String: [ImageDownloadItem]], diagnosticLog: String) {
        var itemsByURL: [String: [ImageDownloadItem]] = [:]
        var diagnosticLog = ""

        let scanOutputs = await imageScanOutputs(
            galleryDLPath: galleryDLPath,
            urls: urls,
            cookieFilePath: cookieFilePath,
            timeout: timeout
        )

        for scanOutput in scanOutputs {
            let parsedOutput = scanOutput.result
            diagnosticLog += parsedOutput.diagnosticLog
            if !parsedOutput.items.isEmpty {
                itemsByURL[DownloadCommandBuilder.normalizedURLString(scanOutput.url)] = parsedOutput.items
            }
        }

        return (itemsByURL, diagnosticLog)
    }

    private static func imageScanOutputs(
        galleryDLPath: String,
        urls: [String],
        cookieFilePath: String,
        timeout: Duration
    ) async -> [OrderedImageScanOutput] {
        guard urls.count > 1 else {
            var outputs: [OrderedImageScanOutput] = []
            for (index, url) in urls.enumerated() {
                let output = await metadataScan(
                    galleryDLPath: galleryDLPath,
                    url: url,
                    cookieFilePath: cookieFilePath,
                    timeout: timeout
                )
                outputs.append(OrderedImageScanOutput(
                    index: index,
                    url: url,
                    result: parseOutput(
                        output,
                        sourceURL: url
                    )
                ))
            }
            return outputs
        }

        return await withTaskGroup(of: OrderedImageScanOutput.self) { group in
            for (index, url) in urls.enumerated() {
                group.addTask {
                    OrderedImageScanOutput(
                        index: index,
                        url: url,
                        result: parseOutput(
                            await metadataScan(
                                galleryDLPath: galleryDLPath,
                                url: url,
                                cookieFilePath: cookieFilePath,
                                timeout: timeout
                            ),
                            sourceURL: url
                        )
                    )
                }
            }

            var outputs: [OrderedImageScanOutput?] = Array(repeating: nil, count: urls.count)
            for await output in group {
                outputs[output.index] = output
            }

            return outputs.compactMap { $0 }
        }
    }

    static func parseOutput(_ output: String, sourceURL: String) -> ImageURLScanResult {
        let postID = InstagramURLDetector.postID(from: sourceURL) ?? "instagram"
        var items: [ImageDownloadItem] = []
        var diagnosticLines: [String] = []

        for line in output.components(separatedBy: .newlines) {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }

            guard let url = URL(string: trimmedLine),
                  let scheme = url.scheme?.lowercased(),
                  ["http", "https"].contains(scheme) else {
                diagnosticLines.append(trimmedLine)
                continue
            }

            items.append(ImageDownloadItem(
                url: url,
                title: "Instagram \(postID)",
                id: postID,
                fileExtension: imageExtension(for: url),
                httpHeaders: [
                    "Referer": "https://www.instagram.com/",
                    "User-Agent": "Mozilla/5.0"
                ]
            ))
        }

        let diagnosticLog = diagnosticLines.isEmpty ? "" : diagnosticLines.joined(separator: "\n") + "\n"
        return ImageURLScanResult(items: items, diagnosticLog: diagnosticLog)
    }

    private static func metadataScan(
        galleryDLPath: String,
        url: String,
        cookieFilePath: String,
        timeout: Duration
    ) async -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: galleryDLPath)
        process.arguments = [
            "-g",
            "--cookies",
            cookieFilePath,
            url
        ]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let controller = CheckProcessController()

        return await withTaskCancellationHandler {
            await Task.detached(priority: .userInitiated) {
                let timeoutTask = Task.detached {
                    do {
                        try await Task.sleep(for: timeout)
                    } catch {
                        return
                    }
                    controller.stop(.timedOut)
                }
                defer { timeoutTask.cancel() }

                do {
                    guard try controller.start(process) else { return "" }
                } catch {
                    _ = controller.complete()
                    return "Failed to start gallery-dl: \(error.localizedDescription)\n"
                }

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                let stopReason = controller.complete()
                if stopReason == .timedOut {
                    return "Link check timed out after 90 seconds.\n"
                }
                if stopReason == .cancelled {
                    return ""
                }

                let output = String(data: data, encoding: .utf8) ?? ""
                if process.terminationStatus != 0,
                   output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return "gallery-dl exited with code \(process.terminationStatus).\n"
                }
                return output
            }.value
        } onCancel: {
            controller.stop(.cancelled)
        }
    }

    private static func imageExtension(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "webp"].contains(pathExtension) {
            return pathExtension == "jpeg" ? "jpg" : pathExtension
        }

        return "jpg"
    }
}

enum ImageCheckValidator {
    static func validatedState(
        kind: DownloadKind,
        scanState: LinkScanState,
        imageItemsByURL: [String: [ImageDownloadItem]]
    ) -> LinkScanState {
        guard kind == .image else { return scanState }
        guard case .ready = scanState else { return scanState }
        return imageItemsByURL.values.contains { !$0.isEmpty } ? scanState : .unavailable
    }
}

struct MetadataScanOutput: @unchecked Sendable {
    let items: [[String: Any]]
    let diagnosticLog: String

    static func parse(_ output: String) -> MetadataScanOutput {
        var items: [[String: Any]] = []
        var diagnosticLines: [String] = []

        for line in output.components(separatedBy: .newlines) where !line.isEmpty {
            guard let data = line.data(using: .utf8),
                  let item = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                diagnosticLines.append(line)
                continue
            }

            items.append(item)
        }

        let diagnosticLog = diagnosticLines.isEmpty ? "" : diagnosticLines.joined(separator: "\n") + "\n"
        return MetadataScanOutput(items: items, diagnosticLog: diagnosticLog)
    }
}

enum MetadataDiagnostics {
    static func summary(for metadataGroups: [[[String: Any]]]) -> String {
        var lines: [String] = []

        for (groupIndex, group) in metadataGroups.enumerated() {
            lines.append("Metadata group \(groupIndex + 1): \(group.count) item(s)")

            for (itemIndex, metadata) in group.prefix(3).enumerated() {
                let keys = metadata.keys.sorted().prefix(18).joined(separator: ", ")
                let thumbnailCount = (metadata["thumbnails"] as? [[String: Any]])?.count ?? 0
                let hasThumbnail = metadata["thumbnail"] is String
                let hasURL = metadata["url"] is String
                let entries = metadata["entries"] as? [[String: Any]]

                lines.append("  item \(itemIndex + 1) keys: \(keys)")
                lines.append("  item \(itemIndex + 1) url:\(hasURL ? "yes" : "no") thumbnail:\(hasThumbnail ? "yes" : "no") thumbnails:\(thumbnailCount) entries:\(entries?.count ?? 0)")

                if let firstEntry = entries?.first {
                    let entryKeys = firstEntry.keys.sorted().prefix(18).joined(separator: ", ")
                    let entryThumbnailCount = (firstEntry["thumbnails"] as? [[String: Any]])?.count ?? 0
                    let entryHasThumbnail = firstEntry["thumbnail"] is String
                    let entryHasURL = firstEntry["url"] is String
                    lines.append("  first entry keys: \(entryKeys)")
                    lines.append("  first entry url:\(entryHasURL ? "yes" : "no") thumbnail:\(entryHasThumbnail ? "yes" : "no") thumbnails:\(entryThumbnailCount)")
                }
            }
        }

        return lines.joined(separator: "\n") + "\n"
    }
}

enum ImageDownloadError: LocalizedError {
    case badStatus(Int)

    var errorDescription: String? {
        switch self {
        case let .badStatus(statusCode):
            return "Image request returned HTTP \(statusCode)."
        }
    }
}

struct DownloadJob: Sendable {
    let url: String
    let kind: DownloadKind
    let arguments: [String]
    let imageItems: [ImageDownloadItem]
    let index: Int
    let total: Int
}

@MainActor
final class DownloadModel: ObservableObject, @unchecked Sendable {
    private enum DefaultsKey {
        static let cookieFilePath = "downlink.cookieFilePath"
    }

    @Published var urls = ""
    @Published var outputDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? NSHomeDirectory()
    @Published var language: AppLanguage = .english {
        didSet {
            status = Self.translatedStatus(status, from: oldValue, to: language)
            if userFacingErrorMessage == oldValue.downloadFailed {
                userFacingErrorMessage = language.downloadFailed
            }
            if logText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || logText == oldValue.initialLog {
                logText = language.initialLog
            }
        }
    }
    @Published var kind: DownloadKind = .video
    @Published var videoFormat: VideoFormat = .mp4
    @Published var audioFormat: AudioFormat = .mp3
    @Published var quality: Quality = .p1080
    @Published var includeVideoAudio = true
    @Published var includeSubtitles = false
    @Published var embedArtwork = true
    @Published var cookieSource: CookieSource = .file
    @Published var cookieFilePath: String = UserDefaults.standard.string(forKey: DefaultsKey.cookieFilePath) ?? "" {
        didSet {
            UserDefaults.standard.set(cookieFilePath, forKey: DefaultsKey.cookieFilePath)
        }
    }
    @Published var isRunning = false
    @Published var status = AppLanguage.english.ready
    @Published var logText = AppLanguage.english.initialLog
    @Published private(set) var userFacingErrorMessage: String?
    @Published var activeJobIndex: Int?
    @Published var completedJobCount = 0
    @Published var progressFraction = 0.0
    @Published var speedLabel = "0 KB/s"
    @Published var etaLabel = "--"
    @Published var downloadedLabel = "--"
    @Published var linkScanState: LinkScanState = .empty
    @Published var mediaSummary: MediaSummary?
    @Published private(set) var linkCheckFailure: LinkCheckFailure?
    @Published var downloadHistory: [DownloadHistoryItem] = []
    @Published private(set) var availableVideoQualities: [VideoQualityOption] = []
    @Published private(set) var selectedVideoQuality: VideoQualityOption = .best

    private var currentProcess: Process?
    private var currentProcessController: CheckProcessController?
    private var linkScanTask: Task<Void, Never>?
    private var downloadTask: Task<Void, Never>?
    private var isCancellationRequested = false
    private var currentJobStartDate: Date?
    private var currentDownloadedBytes: Int64?
    private var currentTotalBytes: Int64?
    private var smoothedBytesPerSecond: Double?
    private var smoothedRemainingSeconds: Double?
    private var checkedSignature: String?
    private var checkedImageItemsByURL: [String: [ImageDownloadItem]] = [:]
    private var checkedMetadataGroups: [[[String: Any]]] = []
    private var checkedTotalBytes: Int64?
    private var checkedPreviewImageURL: URL?
    private var checkedMediaFormatCatalog: MediaFormatCatalog?
    private var failedJobCount = 0
    private var cachedDependencyStatus: (status: DependencyStatus, resolvedAt: Date)?
    private lazy var directoryPanel = makeDirectoryPanel()
    private lazy var cookiesFilePanel = makeCookiesFilePanel()

    private static func translatedStatus(_ status: String, from oldLanguage: AppLanguage, to newLanguage: AppLanguage) -> String {
        let exactStatuses: [(old: String, new: String)] = [
            (oldLanguage.ready, newLanguage.ready),
            (oldLanguage.downloading, newLanguage.downloading),
            (oldLanguage.finished, newLanguage.finished),
            (oldLanguage.cancelled, newLanguage.cancelled),
            (oldLanguage.missingTools, newLanguage.missingTools),
            (oldLanguage.error, newLanguage.error)
        ]
        if let match = exactStatuses.first(where: { $0.old == status }) {
            return match.new
        }

        let downloadingPrefix = oldLanguage.downloading + " "
        if status.hasPrefix(downloadingPrefix) {
            return newLanguage.downloading + " " + status.dropFirst(downloadingPrefix.count)
        }

        return status
    }

    var parsedURLs: [String] {
        SingleURLInput.parse(urls).map { [$0] } ?? []
    }

    var canDownload: Bool {
        !isRunning && hasValidCheck && currentSelectionIsFulfillable
    }

    var imagePreviewItems: [ImageDownloadItem] {
        ImagePreviewList.items(for: parsedURLs, itemsByURL: checkedImageItemsByURL)
    }

    var canUsePrimaryButton: Bool {
        !isRunning
            && parsedURLs.count == 1
            && linkScanState != .checking
            && (!hasValidCheck || currentSelectionIsFulfillable)
    }

    var qualityControlTitle: String {
        switch kind {
        case .video:
            return hasValidCheck ? selectedVideoQuality.label : "--"
        case .audio:
            return "Best"
        case .image:
            return "--"
        }
    }

    var isQualityControlEnabled: Bool {
        kind == .video && hasValidCheck && !availableVideoQualities.isEmpty
    }

    var hasCheckedOptions: Bool {
        hasValidCheck
    }

    var currentSelectionIsFulfillable: Bool {
        CheckedSelectionReadiness.isFulfillable(
            kind: kind,
            catalog: checkedMediaFormatCatalog,
            selectedVideoHeight: selectedVideoQuality.height,
            includeVideoAudio: includeVideoAudio,
            videoFormat: videoFormat
        )
    }

    var displayedProgress: Double {
        if linkScanState == .checking {
            return 0.12
        }

        if isRunning {
            return max(progressFraction, 0.03)
        }

        if completedJobCount > 0 {
            return 1
        }

        return 0
    }

    var primaryButtonTitle: String {
        if linkScanState == .checking {
            return language.checkingLinks
        }

        return hasValidCheck ? language.download : language.check
    }

    private var hasValidCheck: Bool {
        if case .ready = linkScanState {
            return checkedSignature == currentSignature
        }

        return false
    }

    var dependencyStatus: DependencyStatus {
        if let cachedDependencyStatus,
           Date().timeIntervalSince(cachedDependencyStatus.resolvedAt) < 30 {
            return cachedDependencyStatus.status
        }

        let status = DependencyStatus(
            ytDlpPath: findExecutable(named: "yt-dlp", fallbackPaths: [
                "/opt/homebrew/bin/yt-dlp",
                "/usr/local/bin/yt-dlp",
                "/usr/bin/yt-dlp"
            ]),
            ffmpegPath: findExecutable(named: "ffmpeg", fallbackPaths: [
                "/opt/homebrew/bin/ffmpeg",
                "/usr/local/bin/ffmpeg",
                "/usr/bin/ffmpeg"
            ]),
            ffprobePath: findExecutable(named: "ffprobe", fallbackPaths: [
                "/opt/homebrew/bin/ffprobe",
                "/usr/local/bin/ffprobe",
                "/usr/bin/ffprobe"
            ]),
            galleryDLPath: findExecutable(named: "gallery-dl", fallbackPaths: [
                "/opt/homebrew/bin/gallery-dl",
                "/usr/local/bin/gallery-dl",
                "/tmp/downlink-gallerydl-venv/bin/gallery-dl"
            ])
        )
        cachedDependencyStatus = (status, Date())
        return status
    }

    func chooseCookiesFile() {
        let panel = cookiesFilePanel
        panel.prompt = language.choose
        panel.title = language.cookiesFilePlaceholder
        panel.directoryURL = existingDirectoryURL(for: cookieFilePath) ?? existingDirectoryURL(for: outputDirectory)

        presentOpenPanel(panel) { [weak self] url in
            guard let self else { return }
            cookieFilePath = url.path
            cookieSource = .file
            resetLinkScan()
        }
    }

    func chooseDirectory() {
        let panel = directoryPanel
        panel.prompt = language.choose
        panel.directoryURL = existingDirectoryURL(for: outputDirectory)

        presentOpenPanel(panel) { [weak self] url in
            guard let self else { return }
            outputDirectory = url.path
        }
    }

    func resetLinkScan() {
        guard !isRunning else { return }

        linkScanTask?.cancel()
        linkCheckFailure = nil
        userFacingErrorMessage = nil
        checkedSignature = nil
        checkedImageItemsByURL = [:]
        checkedMetadataGroups = []
        checkedTotalBytes = nil
        checkedPreviewImageURL = nil
        checkedMediaFormatCatalog = nil
        availableVideoQualities = []
        selectedVideoQuality = .best
        mediaSummary = nil
        completedJobCount = 0
        progressFraction = 0
        speedLabel = "0 KB/s"
        etaLabel = "--"
        downloadedLabel = "--"
        resetTransferEstimates()

        let urls = parsedURLs
        guard urls.count == 1 else {
            linkScanState = self.urls.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .empty : .unavailable
            return
        }

        linkScanState = .needsCheck(count: urls.count)
    }

    func selectVideoQuality(_ option: VideoQualityOption) {
        guard kind == .video, availableVideoQualities.contains(option) else { return }
        selectedVideoQuality = option
        refreshCheckedSelection()
    }

    func refreshCheckedSelection() {
        guard hasValidCheck, !checkedMetadataGroups.isEmpty else { return }

        if kind == .video, let catalog = checkedMediaFormatCatalog {
            availableVideoQualities = catalog.compatibleVideoQualities(
                outputFormat: videoFormat,
                includeAudio: includeVideoAudio
            )
            if !availableVideoQualities.contains(selectedVideoQuality) {
                selectedVideoQuality = availableVideoQualities.first ?? .best
            }
        }

        let selection = selectedVideoStreamSelection
        let estimatedBytes: Int64?
        switch kind {
        case .video:
            estimatedBytes = selection?.estimatedBytes
        case .audio:
            estimatedBytes = checkedMediaFormatCatalog?.checkedAudioSelection?.estimatedBytes
        case .image:
            estimatedBytes = nil
        }
        let refreshedSummary = MediaSummary.make(
            metadataGroups: checkedMetadataGroups,
            fallbackURLs: parsedURLs,
            kind: kind,
            videoFormat: videoFormat,
            audioFormat: audioFormat,
            quality: quality,
            videoQualityLabel: kind == .video ? selectedVideoQuality.label : nil,
            totalBytes: estimatedBytes,
            imageTotalBytes: kind == .image ? ImageItemSize.totalBytes(itemsByURL: checkedImageItemsByURL) : nil,
            previewImageURL: checkedPreviewImageURL
        )
        if kind == .image,
           let refreshedSummary,
           let outputFilename = ImagePreviewSummary.outputFilename(items: imagePreviewItems) {
            mediaSummary = refreshedSummary.replacingOutputFilename(outputFilename)
        } else {
            mediaSummary = refreshedSummary
        }
    }

    func performPrimaryAction() {
        if hasValidCheck {
            startDownload()
        } else {
            checkLinks()
        }
    }

    func submitURLFromEditor() {
        let action = URLSubmitPolicy.action(
            hasValidURL: parsedURLs.count == 1,
            isRunning: isRunning,
            scanState: linkScanState,
            hasCheckedOptions: hasCheckedOptions
        )
        guard action == .check else { return }
        checkLinks()
    }

    func checkLinks() {
        checkLinks(forceRefresh: false)
    }

    func recheckLinks() {
        checkLinks(forceRefresh: true)
    }

    private func checkLinks(forceRefresh: Bool) {
        linkScanTask?.cancel()
        linkCheckFailure = nil

        let urls = parsedURLs
        guard urls.count == 1 else {
            linkScanState = self.urls.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .empty : .unavailable
            checkedSignature = nil
            return
        }

        if LinkCheckCachePolicy.shouldReuse(hasValidCheck: hasValidCheck, forceRefresh: forceRefresh) {
            return
        }

        if forceRefresh {
            checkedSignature = nil
            checkedImageItemsByURL = [:]
            checkedMetadataGroups = []
            checkedTotalBytes = nil
            checkedPreviewImageURL = nil
            checkedMediaFormatCatalog = nil
            availableVideoQualities = []
            selectedVideoQuality = .best
            mediaSummary = nil
        }

        guard !needsCookiesFile(for: urls) else {
            linkScanState = .unavailable
            checkedSignature = nil
            checkedImageItemsByURL = [:]
            appendLog("\(language.chooseCookiesFileFirst)\n")
            return
        }

        let dependencies = dependencyStatus

        if shouldUseGalleryDLForImageScan(urls: urls) {
            guard let galleryDLPath = dependencies.galleryDLPath else {
                linkScanState = .missingTools
                checkedSignature = nil
                appendLog("Missing dependency: gallery-dl.\n")
                return
            }

            linkScanState = .checking

            let signature = currentSignature
            let cookieFilePath = cookieFilePath
            linkScanTask = Task { [weak self, galleryDLPath, urls, cookieFilePath, signature] in
                let result = await GalleryDLImageScanner.scan(
                    galleryDLPath: galleryDLPath,
                    urls: urls,
                    cookieFilePath: cookieFilePath
                )
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    guard let self, !Task.isCancelled else { return }
                    let imageCount = result.itemsByURL.values.reduce(0) { $0 + $1.count }
                    let previewImageURL = result.itemsByURL.values.flatMap { $0 }.first?.url
                    let detectedFailure = LinkCheckFailure.detect(in: result.diagnosticLog)
                    let state: LinkScanState
                    if imageCount > 0 {
                        state = .ready(totalBytes: nil, count: urls.count, previewImageURL: previewImageURL)
                    } else if detectedFailure == .galleryRuntimeUnavailable {
                        state = .missingTools
                    } else {
                        state = .unavailable
                    }

                    self.linkScanState = state
                    self.linkCheckFailure = detectedFailure
                    self.checkedSignature = {
                        if case .ready = state {
                            return signature
                        }

                        return nil
                    }()
                    self.checkedImageItemsByURL = self.checkedSignature == nil ? [:] : result.itemsByURL
                    self.checkedPreviewImageURL = self.checkedSignature == nil ? nil : previewImageURL
                    if case let .ready(totalBytes, _, previewImageURL) = state {
                        let firstItem = result.itemsByURL.values.flatMap { $0 }.first
                        self.mediaSummary = MediaSummary(
                            title: firstItem?.title ?? "Image download",
                            source: urls.first.flatMap { URL(string: $0)?.host?.replacingOccurrences(of: "www.", with: "") } ?? "Source",
                            creator: "",
                            duration: "--",
                            estimatedSize: totalBytes.map(MediaSummary.byteLabelForUI) ?? "--",
                            outputFilename: ImagePreviewSummary.outputFilename(
                                items: result.itemsByURL.values.flatMap { $0 }
                            ) ?? "Image [Image].jpg",
                            previewImageURL: previewImageURL
                        )
                    } else {
                        self.mediaSummary = nil
                    }

                    if !result.diagnosticLog.isEmpty {
                        self.appendLog(result.diagnosticLog)
                    }
                    self.appendLog("Check found \(imageCount) image item(s) with gallery-dl.\n")
                    if imageCount == 0 {
                        self.appendLog("No downloadable image URLs were found by gallery-dl.\n")
                    }
                }
            }
            return
        }

        guard let ytDlpPath = dependencies.ytDlpPath else {
            linkScanState = .missingTools
            checkedSignature = nil
            return
        }

        linkScanState = .checking

        let signature = currentSignature
        let configuration = downloadConfiguration
        let argumentGroups = urls.map { DownloadCommandBuilder.scanArguments(for: $0, configuration: configuration) }
        linkScanTask = Task { [weak self, ytDlpPath, argumentGroups, signature, urls] in
            let result = await LinkScanner.scanWithMetadata(ytDlpPath: ytDlpPath, argumentGroups: argumentGroups)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self, !Task.isCancelled else { return }
                let imageItemsByURL = ImageItemCache.make(urls: urls, metadataGroups: result.metadataGroups)
                let catalog = MediaFormatCatalog.make(metadata: result.metadataGroups.first?.first ?? [:])
                var validatedState = ImageCheckValidator.validatedState(
                    kind: self.kind,
                    scanState: result.state,
                    imageItemsByURL: imageItemsByURL
                )
                if case .ready = validatedState {
                    if self.kind == .video,
                       !CheckedSelectionReadiness.hasVideoOptions(
                        catalog,
                        outputFormat: self.videoFormat
                       ) {
                        validatedState = .unavailable
                    } else if self.kind == .audio, catalog.checkedAudioSelection == nil {
                        validatedState = .unavailable
                    }
                }

                self.linkScanState = validatedState
                if case .unavailable = validatedState {
                    self.linkCheckFailure = LinkCheckFailure.detect(in: result.diagnosticLog)
                } else {
                    self.linkCheckFailure = nil
                }
                self.checkedSignature = {
                    if case .ready = validatedState {
                        return signature
                    }

                    return nil
                }()
                self.checkedImageItemsByURL = self.checkedSignature == nil ? [:] : imageItemsByURL
                if case let .ready(totalBytes, _, previewImageURL) = validatedState {
                    self.checkedMetadataGroups = result.metadataGroups
                    self.checkedTotalBytes = totalBytes
                    self.checkedPreviewImageURL = previewImageURL
                    if self.kind == .video {
                        self.checkedMediaFormatCatalog = catalog
                        self.availableVideoQualities = catalog.compatibleVideoQualities(
                            outputFormat: self.videoFormat,
                            includeAudio: self.includeVideoAudio
                        )
                        self.selectedVideoQuality = self.availableVideoQualities.first ?? .best
                    } else if self.kind == .audio {
                        self.checkedMediaFormatCatalog = catalog
                        self.availableVideoQualities = []
                        self.selectedVideoQuality = .best
                    } else {
                        self.checkedMediaFormatCatalog = nil
                        self.availableVideoQualities = []
                        self.selectedVideoQuality = .best
                    }
                    self.refreshCheckedSelection()
                } else {
                    self.checkedMetadataGroups = []
                    self.checkedTotalBytes = nil
                    self.checkedPreviewImageURL = nil
                    self.checkedMediaFormatCatalog = nil
                    self.availableVideoQualities = []
                    self.selectedVideoQuality = .best
                    self.mediaSummary = nil
                }

                if !result.diagnosticLog.isEmpty {
                    self.appendLog(result.diagnosticLog)
                }

                if self.kind == .image {
                    let imageCount = imageItemsByURL.values.reduce(0) { $0 + $1.count }
                    self.appendLog("Check found \(imageCount) image item(s) from \(result.metadataGroups.count) metadata group(s).\n")
                    self.appendLog(MetadataDiagnostics.summary(for: result.metadataGroups))
                    if imageCount == 0 {
                        self.appendLog("No downloadable image URLs were found in yt-dlp metadata.\n")
                    }
                }
            }
        }
    }

    func startDownload() {
        guard canDownload else { return }

        userFacingErrorMessage = nil

        if kind == .video, selectedVideoStreamSelection == nil {
            checkedSignature = nil
            linkScanState = .needsCheck(count: 1)
            appendLog("The checked video format is unavailable. Check the URL again.\n")
            return
        }
        if kind == .audio, checkedMediaFormatCatalog?.checkedAudioSelection == nil {
            checkedSignature = nil
            linkScanState = .needsCheck(count: 1)
            appendLog("The checked audio format is unavailable. Check the URL again.\n")
            return
        }

        let dependencies = dependencyStatus
        guard let ytDlpPath = dependencies.ytDlpPath else {
            appendLog(language.missingToolLog(
                ytDlpFound: false,
                ffmpegFound: dependencies.ffmpegPath != nil,
                ffprobeFound: dependencies.ffprobePath != nil
            ))
            status = language.missingTools
            return
        }
        let ffmpegPath = dependencies.ffmpegPath ?? ytDlpPath

        if kind != .image, dependencies.ffmpegPath == nil {
            appendLog(language.missingToolLog(
                ytDlpFound: true,
                ffmpegFound: false,
                ffprobeFound: dependencies.ffprobePath != nil
            ))
            status = language.missingTools
            return
        }

        if kind != .image, dependencies.ffprobePath == nil {
            appendLog(language.missingToolLog(
                ytDlpFound: true,
                ffmpegFound: true,
                ffprobeFound: false
            ))
            status = language.missingTools
            return
        }

        isRunning = true
        isCancellationRequested = false
        status = language.downloading
        activeJobIndex = nil
        completedJobCount = 0
        failedJobCount = 0
        progressFraction = 0
        speedLabel = "0 KB/s"
        etaLabel = "--"
        downloadedLabel = "--"
        resetTransferEstimates()
        appendLog("\n\(language.downloading) \(parsedURLs.count) item(s)...\n")

        let jobs = parsedURLs.enumerated().map { offset, url in
            DownloadJob(
                url: url,
                kind: kind,
                arguments: kind == .image
                    ? DownloadCommandBuilder.scanArguments(for: url, configuration: downloadConfiguration)
                    : DownloadCommandBuilder.arguments(for: url, ffmpegPath: ffmpegPath, configuration: downloadConfiguration),
                imageItems: kind == .image ? checkedImageItemsByURL[DownloadCommandBuilder.normalizedURLString(url), default: []] : [],
                index: offset + 1,
                total: parsedURLs.count
            )
        }

        downloadTask = Task.detached(priority: .userInitiated) { [weak self] in
            for job in jobs {
                guard await self?.isStillRunning() == true else { break }
                if job.kind == .image {
                    await self?.runSingleImageDownload(ytDlpPath: ytDlpPath, job: job)
                } else {
                    await self?.runSingleDownload(ytDlpPath: ytDlpPath, job: job)
                }
                guard await self?.isStillRunning() == true else { break }
            }

            await self?.finishQueue()
        }
    }

    func repeatDownload(_ item: DownloadHistoryItem) {
        guard !isRunning else { return }
        restoreHistoryItem(item)
        if canDownload {
            startDownload()
        }
    }

    func removeDownloadHistoryItem(_ item: DownloadHistoryItem) {
        downloadHistory = DownloadHistoryList.removing(id: item.id, from: downloadHistory)
    }

    func clearDownloadHistory() {
        downloadHistory = []
    }

    func cancelDownload() {
        downloadTask?.cancel()
        currentProcessController?.stop(.cancelled)
        isCancellationRequested = true
        activeJobIndex = nil
        status = language.cancelled
        speedLabel = "0 KB/s"
        etaLabel = "--"
        resetTransferEstimates()
        appendLog("\n\(language.cancelled).\n")
    }

    private func findExecutable(named name: String, fallbackPaths: [String]) -> String? {
        let bundledPath = Bundle.main.resourceURL?
            .appendingPathComponent("bin")
            .appendingPathComponent(name)
            .path

        let candidates = ([bundledPath].compactMap { $0 } + fallbackPaths)
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func makeDirectoryPanel() -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.resolvesAliases = true
        return panel
    }

    private func makeCookiesFilePanel() -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.resolvesAliases = true
        return panel
    }

    private func existingDirectoryURL(for path: String) -> URL? {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { return nil }

        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: trimmedPath, isDirectory: &isDirectory) else {
            return nil
        }

        let directoryPath = isDirectory.boolValue
            ? trimmedPath
            : (trimmedPath as NSString).deletingLastPathComponent
        return URL(fileURLWithPath: directoryPath)
    }

    private func presentOpenPanel(_ panel: NSOpenPanel, onSelection: @escaping @MainActor (URL) -> Void) {
        guard let window = NSApp.keyWindow else {
            if panel.runModal() == .OK, let url = panel.url {
                onSelection(url)
            }
            return
        }

        panel.beginSheetModal(for: window) { [weak panel] response in
            guard response == .OK, let url = panel?.url else { return }
            Task { @MainActor in
                onSelection(url)
            }
        }
    }

    private func isStillRunning() -> Bool {
        isRunning && !isCancellationRequested
    }

    func finishQueue() {
        let wasCancelled = isCancellationRequested || status == language.cancelled
        currentProcess = nil
        currentProcessController = nil
        downloadTask = nil
        isRunning = false
        isCancellationRequested = false
        activeJobIndex = nil
        speedLabel = "0 KB/s"
        etaLabel = "--"
        resetTransferEstimates()
        if !wasCancelled {
            if failedJobCount > 0 {
                status = language.error
                appendLog("\n\(language.error).\n")
            } else {
                recordCompletedDownloadHistory()
                status = language.finished
                appendLog("\n\(language.finished).\n")
            }
        }
    }

    private func beginJob(_ job: DownloadJob) -> Bool {
        guard isRunning, !isCancellationRequested else { return false }
        activeJobIndex = job.index
        progressFraction = 0
        speedLabel = "0 KB/s"
        etaLabel = "--"
        downloadedLabel = "--"
        resetTransferEstimates()
        status = "\(language.downloading) \(job.index)/\(job.total)"
        appendLog("\n[\(job.index)/\(job.total)] \(job.url)\n")
        return true
    }

    private func setCurrentProcess(_ process: Process?, controller: CheckProcessController?) {
        currentProcess = process
        currentProcessController = controller
    }

    private func finishJob(_ job: DownloadJob, exitCode: Int32) {
        if exitCode == 0 {
            completedJobCount = max(completedJobCount, job.index)
            progressFraction = 1
            speedLabel = "0 KB/s"
            etaLabel = "--"
            appendLog("[\(job.index)/\(job.total)] \(language.finished).\n")
        } else if status != language.cancelled {
            etaLabel = "--"
            failedJobCount += 1
            status = language.error
            userFacingErrorMessage = language.downloadFailed
            appendLog("[\(job.index)/\(job.total)] Exit code: \(exitCode).\n")
            if kind == .video || kind == .audio {
                checkedSignature = nil
                linkScanState = .needsCheck(count: parsedURLs.count)
                appendLog("The checked media format may no longer be available. Check the URL again before downloading.\n")
            }
        }
    }

    private func recordCompletedDownloadHistory() {
        guard completedJobCount > 0, let mediaSummary else { return }

        let item = DownloadHistoryItem(
            title: mediaSummary.title,
            source: mediaSummary.source,
            outputFilename: mediaSummary.outputFilename,
            estimatedSize: mediaSummary.estimatedSize,
            previewImageURL: mediaSummary.previewImageURL,
            sourceURLs: parsedURLs,
            kind: kind,
            videoFormat: videoFormat,
            audioFormat: audioFormat,
            quality: quality,
            includeVideoAudio: includeVideoAudio,
            includeSubtitles: includeSubtitles,
            embedArtwork: embedArtwork,
            outputDirectory: outputDirectory,
            imageItemsByURL: checkedImageItemsByURL,
            checkedMediaFormatCatalog: checkedMediaFormatCatalog,
            selectedVideoQuality: selectedVideoQuality,
            checkedSignature: checkedSignature
        )
        downloadHistory = DownloadHistoryList.prepending(item, to: downloadHistory)
    }

    private func restoreHistoryItem(_ item: DownloadHistoryItem) {
        urls = item.sourceURLs.joined(separator: "\n")
        kind = item.kind
        videoFormat = item.videoFormat
        audioFormat = item.audioFormat
        quality = item.quality
        includeVideoAudio = item.includeVideoAudio
        includeSubtitles = item.includeSubtitles
        embedArtwork = item.embedArtwork
        outputDirectory = item.outputDirectory
        mediaSummary = item.mediaSummary
        checkedImageItemsByURL = item.imageItemsByURL
        checkedMetadataGroups = [[[
            "title": item.title,
            "extractor": item.source
        ]]]
        checkedTotalBytes = nil
        checkedPreviewImageURL = item.previewImageURL
        checkedMediaFormatCatalog = item.checkedMediaFormatCatalog
        selectedVideoQuality = item.selectedVideoQuality
        availableVideoQualities = item.kind == .video
            ? (item.checkedMediaFormatCatalog?.compatibleVideoQualities(
                outputFormat: item.videoFormat,
                includeAudio: item.includeVideoAudio
            ) ?? [item.selectedVideoQuality])
            : []
        if item.checkedSignature == currentSignature {
            linkScanState = .ready(totalBytes: nil, count: item.sourceURLs.count, previewImageURL: item.previewImageURL)
            checkedSignature = item.checkedSignature
        } else {
            linkScanState = .needsCheck(count: item.sourceURLs.count)
            checkedSignature = nil
        }
        completedJobCount = 0
        progressFraction = 0
        status = language.ready
        resetTransferEstimates()
    }

    private var outputTemplate: String {
        OutputNaming.template(
            kind: kind,
            videoQualityLabel: kind == .video ? selectedVideoQuality.label : nil
        )
    }

    private var selectedVideoStreamSelection: VideoStreamSelection? {
        checkedMediaFormatCatalog?.videoSelection(
            height: selectedVideoQuality.height,
            includeAudio: includeVideoAudio,
            outputFormat: videoFormat
        )
    }

    private var downloadConfiguration: DownloadConfiguration {
        var configuration = DownloadConfiguration(
            kind: kind,
            videoFormat: videoFormat,
            audioFormat: audioFormat,
            quality: quality,
            includeVideoAudio: includeVideoAudio,
            includeSubtitles: includeSubtitles,
            embedArtwork: embedArtwork,
            cookieSource: cookieSource,
            cookieFilePath: cookieFilePath,
            outputDirectory: outputDirectory,
            outputTemplate: outputTemplate
        )
        if kind == .video {
            configuration.selectedVideoFormatSelector = selectedVideoStreamSelection?.selector
        } else if kind == .audio {
            configuration.selectedAudioFormatSelector = checkedMediaFormatCatalog?.checkedAudioSelection?.formatID
        }
        return configuration
    }

    private var currentSignature: String {
        LinkCheckSignature.make(
            urls: parsedURLs,
            kind: kind,
            videoFormat: videoFormat,
            audioFormat: audioFormat,
            quality: quality,
            includeVideoAudio: includeVideoAudio,
            includeSubtitles: includeSubtitles,
            embedArtwork: embedArtwork,
            cookieSource: cookieSource,
            cookieFilePath: cookieFilePath
        )
    }

    private func needsCookiesFile(for urls: [String]) -> Bool {
        cookieSource == .file &&
            urls.contains(where: InstagramURLDetector.isInstagramURL) &&
            cookieFilePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func shouldUseGalleryDLForImageScan(urls: [String]) -> Bool {
        kind == .image && urls.allSatisfy(InstagramURLDetector.isInstagramURL)
    }

    private nonisolated func runSingleDownload(ytDlpPath: String, job: DownloadJob) async {
        guard await beginJob(job) else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytDlpPath)
        process.arguments = job.arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let controller = CheckProcessController()
        await setCurrentProcess(process, controller: controller)

        do {
            try Task.checkCancellation()
            guard try controller.start(process) else { return }
            let handle = pipe.fileHandleForReading
            while process.isRunning {
                let data = handle.availableData
                if data.isEmpty { break }
                guard let text = String(data: data, encoding: .utf8), !text.isEmpty else { continue }
                await appendLog(text)
            }
            process.waitUntilExit()

            let remainingData = handle.readDataToEndOfFile()
            if let remainingText = String(data: remainingData, encoding: .utf8), !remainingText.isEmpty {
                await appendLog(remainingText)
            }

            let stopReason = controller.complete()
            guard stopReason != .cancelled, !Task.isCancelled else { return }
            await finishJob(job, exitCode: process.terminationStatus)
        } catch is CancellationError {
            controller.stop(.cancelled)
            _ = controller.complete()
        } catch {
            _ = controller.complete()
            if !Task.isCancelled {
                await failToStart(error)
            }
        }
    }

    private nonisolated func runSingleImageDownload(ytDlpPath: String, job: DownloadJob) async {
        guard await beginJob(job) else { return }

        let imageItems: [ImageDownloadItem]
        if job.imageItems.isEmpty {
            guard let metadataItems = await LinkScanner.metadataItems(ytDlpPath: ytDlpPath, arguments: job.arguments) else {
                await finishJob(job, exitCode: 1)
                return
            }
            imageItems = metadataItems.flatMap(ImageMetadataExtractor.items(from:))
        } else {
            imageItems = job.imageItems
        }
        guard !imageItems.isEmpty else {
            await appendLog("No downloadable images found in metadata.\n")
            await finishJob(job, exitCode: 1)
            return
        }

        var completedItems = 0
        for (offset, item) in imageItems.enumerated() {
            guard await isStillRunning() else { break }
            do {
                let filename = item.suggestedFilename(index: offset + 1, total: imageItems.count)
                let savedFilename = try await downloadImage(item, filename: filename)
                completedItems += 1
                if offset == 0 {
                    await updateImageOutputFilename(savedFilename)
                }
                await appendLog("[image] Saved \(savedFilename)\n")
                await updateImageProgress(completed: completedItems, total: imageItems.count)
            } catch {
                await appendLog("[image] Failed: \(error.localizedDescription)\n")
            }
        }

        await finishJob(job, exitCode: completedItems == imageItems.count ? 0 : 1)
    }

    private nonisolated func downloadImage(_ item: ImageDownloadItem, filename: String) async throws -> String {
        let directory = await outputDirectoryPath()
        var request = URLRequest(url: item.url)
        for (field, value) in item.httpHeaders {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            throw ImageDownloadError.badStatus(httpResponse.statusCode)
        }

        let destination = try ImageFileWriter.write(
            data,
            directory: URL(fileURLWithPath: directory),
            filename: filename
        )
        return destination.lastPathComponent
    }

    private func updateImageOutputFilename(_ filename: String) {
        if let mediaSummary {
            self.mediaSummary = mediaSummary.replacingOutputFilename(filename)
        }
    }

    private func outputDirectoryPath() -> String {
        outputDirectory
    }

    private func updateImageProgress(completed: Int, total: Int) {
        progressFraction = total > 0 ? Double(completed) / Double(total) : 0
        downloadedLabel = "\(completed) / \(total)"
        speedLabel = "0 KB/s"
        etaLabel = completed == total ? "--" : etaLabel
    }

    func failToStart(_ error: Error) {
        failedJobCount += 1
        appendLog("Failed to start yt-dlp: \(error.localizedDescription)\n")
        status = language.error
        userFacingErrorMessage = error.localizedDescription
        speedLabel = "0 KB/s"
        etaLabel = "--"
        resetTransferEstimates()
    }

    private func appendLog(_ text: String) {
        logText += text
        updateProgress(from: text)
    }

    private func updateProgress(from text: String) {
        for line in text.components(separatedBy: .newlines) where line.contains("[download]") {
            let percentValue = firstMatch(in: line, pattern: #"(\d+(?:\.\d+)?)%"#).flatMap(Double.init)

            if let percentValue {
                progressFraction = min(max(percentValue / 100, 0), 1)
            }

            if let totalText = firstMatch(in: line, pattern: #"of\s+~?\s*([0-9.]+\s*[A-Za-z]+)"#),
               let totalBytes = parseByteCount(totalText) {
                currentTotalBytes = totalBytes

                if let percentValue {
                    let downloadedBytes = Int64((Double(totalBytes) * percentValue / 100).rounded())
                    currentDownloadedBytes = max(downloadedBytes, currentDownloadedBytes ?? 0)
                    downloadedLabel = "\(formatByteCount(currentDownloadedBytes ?? downloadedBytes)) / \(formatByteCount(totalBytes))"
                }
            } else if let downloadedText = firstMatch(in: line, pattern: #"([0-9.]+\s*[A-Za-z]+)\s+at"#),
                      let downloadedBytes = parseByteCount(downloadedText) {
                currentDownloadedBytes = max(downloadedBytes, currentDownloadedBytes ?? 0)
                downloadedLabel = formatByteCount(currentDownloadedBytes ?? downloadedBytes)
            }

            let instantSpeed = firstMatch(in: line, pattern: #"at\s+([0-9.]+\s*[A-Za-z]+/s)"#)
                .flatMap(parseSpeed)

            updateTransferEstimate(instantSpeed: instantSpeed)

            if smoothedRemainingSeconds == nil,
               let etaText = firstMatch(in: line, pattern: #"ETA\s+([0-9:]+)"#),
               let etaSeconds = parseDuration(etaText) {
                smoothedRemainingSeconds = Double(etaSeconds)
                etaLabel = formatDuration(etaSeconds)
            }
        }
    }

    private func resetTransferEstimates() {
        currentJobStartDate = Date()
        currentDownloadedBytes = nil
        currentTotalBytes = nil
        smoothedBytesPerSecond = nil
        smoothedRemainingSeconds = nil
    }

    private func updateTransferEstimate(instantSpeed: Double?) {
        guard let startDate = currentJobStartDate else { return }

        if let instantSpeed, instantSpeed > 0 {
            smoothedBytesPerSecond = smooth(previous: smoothedBytesPerSecond, next: instantSpeed, weight: 0.20)
        }

        if let downloadedBytes = currentDownloadedBytes, downloadedBytes > 0 {
            let elapsed = max(Date().timeIntervalSince(startDate), 0.8)
            let averageSpeed = Double(downloadedBytes) / elapsed
            let blendedSpeed: Double

            if let smoothedBytesPerSecond {
                blendedSpeed = averageSpeed * 0.72 + smoothedBytesPerSecond * 0.28
            } else {
                blendedSpeed = averageSpeed
            }

            if blendedSpeed > 1 {
                smoothedBytesPerSecond = smooth(previous: smoothedBytesPerSecond, next: blendedSpeed, weight: 0.14)
                speedLabel = "\(formatByteCount(Int64(blendedSpeed)))/s"
            }

            if let totalBytes = currentTotalBytes, totalBytes > downloadedBytes, blendedSpeed > 1 {
                let remainingSeconds = Double(totalBytes - downloadedBytes) / blendedSpeed
                smoothedRemainingSeconds = smooth(previous: smoothedRemainingSeconds, next: remainingSeconds, weight: 0.16)

                if let smoothedRemainingSeconds {
                    etaLabel = formatDuration(Int(smoothedRemainingSeconds.rounded()))
                }
            }
        } else if let smoothedBytesPerSecond, smoothedBytesPerSecond > 1 {
            speedLabel = "\(formatByteCount(Int64(smoothedBytesPerSecond)))/s"
        }
    }

    private func smooth(previous: Double?, next: Double, weight: Double) -> Double {
        guard let previous else { return next }
        return previous * (1 - weight) + next * weight
    }

    private func parseByteCount(_ text: String) -> Int64? {
        let compact = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let valueText = firstMatch(in: compact, pattern: #"([0-9.]+)"#),
              let value = Double(valueText),
              let unit = firstMatch(in: compact, pattern: #"[0-9.]+\s*([A-Za-z]+)"#)?.lowercased() else {
            return nil
        }

        let multiplier: Double
        switch unit {
        case "b":
            multiplier = 1
        case "kb", "kib":
            multiplier = unit == "kb" ? 1_000 : 1_024
        case "mb", "mib":
            multiplier = unit == "mb" ? 1_000_000 : 1_048_576
        case "gb", "gib":
            multiplier = unit == "gb" ? 1_000_000_000 : 1_073_741_824
        case "tb", "tib":
            multiplier = unit == "tb" ? 1_000_000_000_000 : 1_099_511_627_776
        default:
            return nil
        }

        return Int64((value * multiplier).rounded())
    }

    private func parseSpeed(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: "/s", with: "", options: .caseInsensitive)
        return parseByteCount(cleaned).map(Double.init)
    }

    private func parseDuration(_ text: String) -> Int? {
        let parts = text.split(separator: ":").compactMap { Int($0) }
        guard !parts.isEmpty else { return nil }

        return parts.reduce(0) { partial, part in
            partial * 60 + part
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let seconds = max(seconds, 0)
        if seconds >= 3600 {
            return String(format: "%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
        }

        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func formatByteCount(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }

    private func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1 else {
            return nil
        }
        let captureRange = match.range(at: 1)
        guard let stringRange = Range(captureRange, in: text) else { return nil }
        return String(text[stringRange])
    }
}

enum LinkScanner {
    private struct OrderedMetadataScanOutput: Sendable {
        let index: Int
        let output: MetadataScanOutput
    }

    static func scan(ytDlpPath: String, argumentGroups: [[String]]) async -> LinkScanState {
        await scanWithMetadata(ytDlpPath: ytDlpPath, argumentGroups: argumentGroups).state
    }

    static func scanWithMetadata(
        ytDlpPath: String,
        argumentGroups: [[String]],
        timeout: Duration = .seconds(90)
    ) async -> LinkScanResult {
        var totalBytes: Int64 = 0
        var hasKnownSize = false
        var previewImageURL: URL?
        var metadataGroups: [[[String: Any]]] = []
        var diagnosticLog = ""

        for scanOutput in await metadataScanOutputs(
            ytDlpPath: ytDlpPath,
            argumentGroups: argumentGroups,
            timeout: timeout
        ) {
            diagnosticLog += scanOutput.diagnosticLog

            guard !scanOutput.items.isEmpty else {
                return LinkScanResult(state: .unavailable, metadataGroups: [], diagnosticLog: diagnosticLog)
            }

            let metadataItems = scanOutput.items
            metadataGroups.append(metadataItems)

            for metadata in metadataItems {
                if let bytes = estimatedBytes(from: metadata), bytes > 0 {
                    totalBytes += bytes
                    hasKnownSize = true
                }

                if previewImageURL == nil {
                    previewImageURL = ImageMetadataExtractor.items(from: metadata).first?.url ?? previewURL(from: metadata)
                }
            }
        }

        return LinkScanResult(
            state: .ready(totalBytes: hasKnownSize ? totalBytes : nil, count: argumentGroups.count, previewImageURL: previewImageURL),
            metadataGroups: metadataGroups,
            diagnosticLog: diagnosticLog
        )
    }

    private static func metadataScanOutputs(
        ytDlpPath: String,
        argumentGroups: [[String]],
        timeout: Duration
    ) async -> [MetadataScanOutput] {
        guard argumentGroups.count > 1 else {
            var outputs: [MetadataScanOutput] = []
            for arguments in argumentGroups {
                outputs.append(await metadataScan(
                    ytDlpPath: ytDlpPath,
                    arguments: arguments,
                    timeout: timeout
                ))
            }
            return outputs
        }

        return await withTaskGroup(of: OrderedMetadataScanOutput.self) { group in
            for (index, arguments) in argumentGroups.enumerated() {
                group.addTask {
                    OrderedMetadataScanOutput(
                        index: index,
                        output: await metadataScan(
                            ytDlpPath: ytDlpPath,
                            arguments: arguments,
                            timeout: timeout
                        )
                    )
                }
            }

            var outputs: [MetadataScanOutput?] = Array(repeating: nil, count: argumentGroups.count)
            for await orderedOutput in group {
                outputs[orderedOutput.index] = orderedOutput.output
            }

            return outputs.compactMap { $0 }
        }
    }

    static func metadataItems(ytDlpPath: String, arguments: [String]) async -> [[String: Any]]? {
        let output = await metadataScan(
            ytDlpPath: ytDlpPath,
            arguments: arguments,
            timeout: .seconds(90)
        )
        return output.items.isEmpty ? nil : output.items
    }

    private static func metadataScan(
        ytDlpPath: String,
        arguments: [String],
        timeout: Duration
    ) async -> MetadataScanOutput {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytDlpPath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        let controller = CheckProcessController()

        return await withTaskCancellationHandler {
            await Task.detached(priority: .userInitiated) {
                let timeoutTask = Task.detached {
                    do {
                        try await Task.sleep(for: timeout)
                    } catch {
                        return
                    }
                    controller.stop(.timedOut)
                }
                defer { timeoutTask.cancel() }

                do {
                    guard try controller.start(process) else {
                        return MetadataScanOutput(items: [], diagnosticLog: "")
                    }
                } catch {
                    _ = controller.complete()
                    return MetadataScanOutput(items: [], diagnosticLog: "Failed to start yt-dlp: \(error.localizedDescription)\n")
                }

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                let stopReason = controller.complete()

                if stopReason == .timedOut {
                    return MetadataScanOutput(items: [], diagnosticLog: "Link check timed out after 90 seconds.\n")
                }
                if stopReason == .cancelled {
                    return MetadataScanOutput(items: [], diagnosticLog: "")
                }

                guard let output = String(data: data, encoding: .utf8) else {
                    let exitLog = process.terminationStatus == 0 ? "" : "yt-dlp exited with code \(process.terminationStatus).\n"
                    return MetadataScanOutput(items: [], diagnosticLog: exitLog)
                }

                let parsedOutput = MetadataScanOutput.parse(output)
                if process.terminationStatus == 0 || !parsedOutput.diagnosticLog.isEmpty {
                    return parsedOutput
                }

                return MetadataScanOutput(items: parsedOutput.items, diagnosticLog: "yt-dlp exited with code \(process.terminationStatus).\n")
            }.value
        } onCancel: {
            controller.stop(.cancelled)
        }
    }

    private static func estimatedBytes(from metadata: [String: Any]) -> Int64? {
        if let requestedFormats = metadata["requested_formats"] as? [[String: Any]] {
            let sizes = requestedFormats.compactMap(formatBytes)
            guard !sizes.isEmpty else { return nil }
            return sizes.reduce(0, +)
        }

        return formatBytes(metadata)
    }

    private static func previewURL(from metadata: [String: Any]) -> URL? {
        if let thumbnail = metadata["thumbnail"] as? String,
           let url = URL(string: thumbnail) {
            return url
        }

        if let thumbnails = metadata["thumbnails"] as? [[String: Any]] {
            return thumbnails
                .compactMap { thumbnail -> URL? in
                    guard let value = thumbnail["url"] as? String else { return nil }
                    return URL(string: value)
                }
                .last
        }

        if let url = metadata["url"] as? String,
           let ext = (metadata["ext"] as? String)?.lowercased(),
           ["jpg", "jpeg", "png", "webp"].contains(ext) {
            return URL(string: url)
        }

        return nil
    }

    private static func formatBytes(_ format: [String: Any]) -> Int64? {
        numericBytes(format["filesize"]) ?? numericBytes(format["filesize_approx"])
    }

    private static func numericBytes(_ value: Any?) -> Int64? {
        switch value {
        case let int as Int:
            return Int64(int)
        case let int64 as Int64:
            return int64
        case let double as Double:
            return Int64(double)
        case let string as String:
            return Int64(string)
        default:
            return nil
        }
    }
}

struct PlaceholderTextEditor: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    func makeNSView(context: Context) -> PlaceholderTextEditorHost {
        let view = PlaceholderTextEditorHost()
        view.textView.delegate = context.coordinator
        context.coordinator.host = view
        view.update(text: text, placeholder: placeholder)
        return view
    }

    func updateNSView(_ nsView: PlaceholderTextEditorHost, context: Context) {
        context.coordinator.text = $text
        context.coordinator.onSubmit = onSubmit
        nsView.update(text: text, placeholder: placeholder)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        var onSubmit: () -> Void
        weak var host: PlaceholderTextEditorHost?

        init(text: Binding<String>, onSubmit: @escaping () -> Void) {
            self.text = text
            self.onSubmit = onSubmit
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
            host?.setPlaceholderVisible(textView.string.isEmpty)
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard URLInputCommand.isSubmit(commandSelector) else { return false }
            onSubmit()
            return true
        }
    }
}

final class PlaceholderTextEditorHost: NSView {
    let textView = NSTextView()

    private let scrollView = NSScrollView()
    private let placeholderLabel = NSTextField(labelWithString: "")
    private let editorInset = NSSize(width: 18, height: 15)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    func update(text: String, placeholder: String) {
        if textView.string != text {
            textView.string = text
        }

        placeholderLabel.stringValue = placeholder
        setPlaceholderVisible(text.isEmpty)
    }

    func setPlaceholderVisible(_ isVisible: Bool) {
        placeholderLabel.isHidden = !isVisible
    }

    private func configure() {
        translatesAutoresizingMaskIntoConstraints = false

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.importsGraphics = false
        textView.font = AppTypography.nsFont(size: AppTypography.editorSize, weight: .regular)
        textView.textColor = .labelColor
        textView.insertionPointColor = .controlAccentColor
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textContainerInset = editorInset
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.font = AppTypography.nsFont(size: AppTypography.editorSize, weight: .regular)
        placeholderLabel.textColor = .tertiaryLabelColor
        placeholderLabel.backgroundColor = .clear
        placeholderLabel.lineBreakMode = .byTruncatingTail

        scrollView.documentView = textView
        addSubview(scrollView)
        addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: editorInset.width),
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: editorInset.height),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -editorInset.width)
        ])
    }
}

struct ContentView: View {
    private enum HoverTarget: Hashable {
        case outputDirectory
        case download
        case cancel
        case videoFormat(VideoFormat)
        case audioFormat(AudioFormat)
        case quality(Quality)
        case mode(DownloadKind)
        case cookieSource(CookieSource)
        case cookiesFile
    }

    @StateObject private var model = DownloadModel()
    @State private var hoveredTarget: HoverTarget?

    private let primary = Color.white.opacity(0.94)
    private let secondary = Color.white.opacity(0.64)
    private let muted = Color.white.opacity(0.36)
    private let good = Color.white.opacity(0.82)
    private let warning = Color.white.opacity(0.68)
    private let separator = Color.white.opacity(0.10)

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 620
            let workspaceHeight = max(0, geometry.size.height - 73)

            mainPanel(compact: compact, workspaceHeight: workspaceHeight)
        }
        .background(background)
        .frame(minWidth: 680, minHeight: 640)
        .preferredColorScheme(.dark)
        .onAppear {
            model.resetLinkScan()
        }
        .onChange(of: model.urls) {
            model.resetLinkScan()
        }
        .onChange(of: model.kind) {
            model.resetLinkScan()
        }
        .onChange(of: model.quality) {
            model.refreshCheckedSelection()
        }
        .onChange(of: model.videoFormat) {
            model.refreshCheckedSelection()
        }
        .onChange(of: model.audioFormat) {
            model.refreshCheckedSelection()
        }
        .onChange(of: model.includeVideoAudio) {
            model.refreshCheckedSelection()
        }
        .onChange(of: model.cookieSource) {
            model.resetLinkScan()
        }
        .onChange(of: model.cookieFilePath) {
            model.resetLinkScan()
        }
    }

    private var background: some View {
        Color(nsColor: .windowBackgroundColor)
        .ignoresSafeArea()
    }

    private func mainPanel(compact: Bool, workspaceHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            headerBar

            Divider()

            workspace(compact: compact, height: workspaceHeight)
        }
    }

    private func workspace(compact: Bool, height: CGFloat) -> some View {
        let inputHeight = min(
            max(height * (compact ? 0.24 : 0.30), compact ? CGFloat(110) : CGFloat(140)),
            compact ? CGFloat(160) : CGFloat(200)
        )

        return VStack(alignment: .leading, spacing: compact ? 14 : 16) {
            linkInput(height: inputHeight)

            Divider()

            optionsAndStatus(compact: compact)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, compact ? 16 : 22)
        .padding(.vertical, compact ? 14 : 17)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func optionsAndStatus(compact: Bool) -> some View {
        if compact {
            VStack(spacing: 16) {
                optionsPane
                Divider()
                progressPane
            }
        } else {
            HStack(alignment: .top, spacing: 16) {
                optionsPane
                    .frame(maxWidth: .infinity)

                Divider()
                    .frame(minHeight: 218)

                progressPane
                    .frame(minWidth: 240, idealWidth: 260, maxWidth: 280)
            }
        }
    }

    private var headerBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                brandHeader

                Spacer(minLength: 16)

                linkStatusBadge

                languagePicker
            }

            VStack(alignment: .leading, spacing: 12) {
                brandHeader

                HStack(spacing: 10) {
                    linkStatusBadge
                    languagePicker
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var brandHeader: some View {
        HStack(spacing: 12) {
            appMark(size: 38)

            Text(appDisplayName)
                .font(AppTypography.font(size: AppTypography.brandTitleSize, weight: .semibold))
                .foregroundStyle(primary)
        }
    }

    private var languagePicker: some View {
        Picker(model.language.language, selection: $model.language) {
            ForEach(AppLanguage.allCases) { language in
                Text(language.menuTitle).tag(language)
            }
        }
        .labelsHidden()
        .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
        .frame(width: 132)
    }

    private func linkInput(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(model.language.links, systemImage: "link")
                    .font(AppTypography.font(size: AppTypography.bodySize, weight: .semibold))
                    .foregroundStyle(primary)

                Spacer()

                Text(localized(
                    en: model.parsedURLs.count == 1 ? "1 link" : "\(model.parsedURLs.count) links",
                    zh: "\(model.parsedURLs.count) 个链接",
                    zhHant: "\(model.parsedURLs.count) 個連結",
                    th: "\(model.parsedURLs.count) ลิงก์"
                ))
                .font(AppTypography.font(size: AppTypography.secondarySize, weight: .medium))
                .foregroundStyle(muted)
            }

            PlaceholderTextEditor(
                text: $model.urls,
                placeholder: model.language.linksPlaceholder,
                onSubmit: model.submitURLFromEditor
            )
                .frame(height: height)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(alignment: .top) { Rectangle().fill(separator).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(separator).frame(height: 1) }
        }
    }

    private var optionsPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(model.language.options, icon: "slider.horizontal.3")

            HStack(spacing: ImagePreviewLayout.tileSpacing) {
                ForEach(DownloadKind.allCases) { kind in
                    modeButton(kind)
                }
                Spacer()
            }

            if model.kind == .video {
                VStack(alignment: .leading, spacing: 12) {
                    optionRow(title: localized(en: "Format", zh: "格式", zhHant: "格式", th: "รูปแบบ")) {
                        optionStrip {
                            ForEach(VideoFormat.allCases) { format in
                                segmentButton(
                                    title: model.language.videoFormatLabel(format),
                                    isSelected: model.videoFormat == format,
                                    hoverTarget: .videoFormat(format)
                                ) {
                                    model.videoFormat = format
                                }
                            }
                        }
                    }

                    optionRow(title: model.language.quality) {
                        optionStrip {
                            if model.availableVideoQualities.isEmpty {
                                segmentButton(
                                    title: "--",
                                    isSelected: false,
                                    hoverTarget: .quality(.p1080)
                                ) {}
                                .disabled(true)
                            } else {
                                ForEach(model.availableVideoQualities) { quality in
                                    segmentButton(
                                        title: quality.label,
                                        isSelected: model.selectedVideoQuality == quality,
                                        hoverTarget: .quality(.p1080)
                                    ) {
                                        model.selectVideoQuality(quality)
                                    }
                                }
                            }
                        }
                    }

                    Toggle(model.language.includeAudio, isOn: $model.includeVideoAudio)
                        .toggleStyle(.checkbox)
                        .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
                        .foregroundStyle(secondary)
                }
            } else if model.kind == .audio {
                optionRow(title: localized(en: "Format", zh: "格式", zhHant: "格式", th: "รูปแบบ")) {
                    optionStrip {
                        ForEach(AudioFormat.allCases) { format in
                            segmentButton(
                                title: format.rawValue.uppercased(),
                                isSelected: model.audioFormat == format,
                                hoverTarget: .audioFormat(format)
                            ) {
                                model.audioFormat = format
                            }
                        }
                    }
                }

                optionRow(title: model.language.quality) {
                    optionStrip {
                        segmentButton(
                            title: "Best",
                            isSelected: true,
                            hoverTarget: .quality(.p1080)
                        ) {}
                        .disabled(true)
                    }
                }
            }

            outputDirectoryRow

            if CookiePickerVisibility.shouldShow(for: model.urls) {
                optionRow(title: model.language.cookies) {
                    optionStrip {
                        ForEach(CookieSource.allCases) { source in
                            segmentButton(
                                title: model.language.cookieSourceLabel(source),
                                isSelected: model.cookieSource == source,
                                hoverTarget: .cookieSource(source)
                            ) {
                                model.cookieSource = source
                            }
                        }
                    }
                }

                if model.cookieSource == .file {
                    cookiesFileRow
                }
            }

            if model.kind != .image {
                VStack(alignment: .leading, spacing: 9) {
                    Toggle(model.language.metadata, isOn: .constant(true))
                        .disabled(true)
                    if model.kind == .video {
                        Toggle(model.language.artwork, isOn: $model.embedArtwork)
                        Toggle(model.language.subtitles, isOn: $model.includeSubtitles)
                    } else {
                        Toggle(model.language.artwork, isOn: .constant(false))
                            .disabled(true)
                        Toggle(model.language.subtitles, isOn: .constant(false))
                            .disabled(true)
                    }
                }
                .toggleStyle(.checkbox)
                .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
                .foregroundStyle(secondary)
            }
        }
    }

    private var progressPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(localized(en: "Status", zh: "状态", zhHant: "狀態", th: "สถานะ"), icon: "waveform.path.ecg")

            if model.linkScanState == .checking {
                ProgressView()
                    .tint(primary)
                    .progressViewStyle(.linear)
            } else {
                ProgressView(value: model.displayedProgress)
                    .tint(primary)
                    .progressViewStyle(.linear)
            }

            imagePreview

            VStack(alignment: .leading, spacing: 8) {
                statusLine(
                    localized(en: "Progress", zh: "进度", zhHant: "進度", th: "ความคืบหน้า"),
                    value: model.linkScanState == .checking
                        ? model.language.checkingLinks
                        : "\(Int(model.displayedProgress * 100))%"
                )
                statusLine(localized(en: "Speed", zh: "速度", zhHant: "速度", th: "ความเร็ว"), value: model.speedLabel)
                statusLine(localized(en: "Remaining", zh: "剩余", zhHant: "剩餘", th: "เหลือ"), value: model.etaLabel)
            }

            HStack(spacing: 10) {
                Button(action: model.performPrimaryAction) {
                    let isHovered = hoveredTarget == .download && model.canUsePrimaryButton
                    Label(model.primaryButtonTitle, systemImage: model.canDownload ? "arrow.down" : "checkmark")
                        .font(AppTypography.font(size: AppTypography.controlSize, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(downloadButtonBackground(isHovered: isHovered), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .foregroundStyle(model.canUsePrimaryButton ? Color.black.opacity(0.90) : Color.white.opacity(0.52))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.white.opacity(isHovered ? 0.22 : 0))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!model.canUsePrimaryButton)
                .contentShape(Rectangle())
                .onHover { setHover(.download, $0 && model.canUsePrimaryButton) }

                Button(action: model.cancelDownload) {
                    let isHovered = hoveredTarget == .cancel && model.isRunning
                    Image(systemName: "xmark")
                        .font(AppTypography.font(size: AppTypography.controlSize, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(model.isRunning ? (isHovered ? 0.16 : 0.10) : 0.04), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.white.opacity(isHovered ? 0.14 : 0))
                        )
                }
                .help(model.language.cancel)
                .buttonStyle(.plain)
                .foregroundStyle(model.isRunning ? primary : muted)
                .disabled(!model.isRunning)
                .contentShape(Rectangle())
                .onHover { setHover(.cancel, $0 && model.isRunning) }
            }

            diagnosticLog
        }
    }

    @ViewBuilder
    private var diagnosticLog: some View {
        let trimmedLog = model.logText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLog.isEmpty {
            ScrollView {
                Text(model.logText)
                    .font(AppTypography.font(size: AppTypography.captionSize, weight: .medium))
                    .foregroundStyle(secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(8)
            }
            .frame(height: 96)
            .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.white.opacity(0.08))
            )
        }
    }

    private var linkStatusBadge: some View {
        return HStack(spacing: 6) {
            Image(systemName: linkStatusIcon)
            Text(linkStatusText)
        }
        .font(AppTypography.font(size: AppTypography.secondarySize, weight: .semibold))
        .foregroundStyle(linkStatusColor)
        .padding(.horizontal, 10)
        .frame(height: 36)
        .background(Color.white.opacity(0.06), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.09)))
    }

    private var linkStatusIcon: String {
        switch model.linkScanState {
        case .empty:
            return "link"
        case .needsCheck:
            return "checkmark"
        case .checking:
            return "clock.arrow.circlepath"
        case .ready:
            return "checkmark.circle.fill"
        case .unavailable, .missingTools:
            return "exclamationmark.triangle.fill"
        }
    }

    private var linkStatusText: String {
        switch model.linkScanState {
        case .empty:
            return model.language.pasteLinkStatus
        case let .needsCheck(count):
            if count > 1 {
                return "\(model.language.check) · \(count)"
            }
            return model.language.check
        case .checking:
            return model.language.checkingLinks
        case let .ready(totalBytes, count, _):
            let sizeText = totalBytes.map(formatBytes) ?? localized(en: "size unknown", zh: "大小未知", zhHant: "大小未知", th: "ไม่ทราบขนาด")
            if count > 1 {
                return "\(model.language.ready) · \(count) · \(sizeText)"
            }
            return "\(model.language.ready) · \(sizeText)"
        case .unavailable:
            return model.language.unavailable
        case .missingTools:
            return model.language.missingTools
        }
    }

    private var linkStatusColor: Color {
        switch model.linkScanState {
        case .ready:
            return good
        case .checking:
            return secondary
        case .empty, .needsCheck:
            return muted
        case .unavailable, .missingTools:
            return warning
        }
    }

    private var outputDirectoryRow: some View {
        Button(action: model.chooseDirectory) {
            let isHovered = hoveredTarget == .outputDirectory
            HStack(spacing: 10) {
                Image(systemName: "folder")
                    .foregroundStyle(muted)
                Text(model.outputDirectory)
                    .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
                    .foregroundStyle(secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text(model.language.choose)
                    .font(AppTypography.font(size: AppTypography.bodySize, weight: .semibold))
                    .foregroundStyle(primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 11)
            .background(Color.white.opacity(isHovered ? 0.055 : 0), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(alignment: .top) { Rectangle().fill(separator).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(separator).frame(height: 1) }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { setHover(.outputDirectory, $0) }
    }

    private var cookiesFileRow: some View {
        Button(action: model.chooseCookiesFile) {
            let isHovered = hoveredTarget == .cookiesFile
            HStack(spacing: 10) {
                Image(systemName: "doc.text")
                    .foregroundStyle(muted)
                Text(model.cookieFilePath.isEmpty ? model.language.cookiesFilePlaceholder : model.cookieFilePath)
                    .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
                    .foregroundStyle(model.cookieFilePath.isEmpty ? muted : secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text(model.language.choose)
                    .font(AppTypography.font(size: AppTypography.bodySize, weight: .semibold))
                    .foregroundStyle(primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 11)
            .background(Color.white.opacity(isHovered ? 0.055 : 0), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(alignment: .top) { Rectangle().fill(separator).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(separator).frame(height: 1) }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { setHover(.cookiesFile, $0) }
    }

    private func downloadButtonBackground(isHovered: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(model.canUsePrimaryButton ? (isHovered ? 1.00 : 0.96) : 0.13),
                Color.white.opacity(model.canUsePrimaryButton ? (isHovered ? 0.82 : 0.72) : 0.08)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func modeButton(_ kind: DownloadKind) -> some View {
        Button {
            var transaction = Transaction()
            transaction.animation = nil
            withTransaction(transaction) {
                model.kind = kind
            }
        } label: {
            let selected = model.kind == kind
            let isHovered = hoveredTarget == .mode(kind)
            HStack(spacing: 7) {
                Image(systemName: modeIcon(for: kind))
                    .font(AppTypography.font(size: AppTypography.bodySize, weight: .semibold))
                Text(model.language.kindLabel(kind))
                    .font(AppTypography.font(size: AppTypography.bodySize, weight: .semibold))
            }
            .foregroundStyle(selected || isHovered ? primary : secondary)
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(Color.white.opacity(isHovered && !selected ? 0.045 : 0), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(selected ? primary : (isHovered ? secondary : .clear))
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { setHover(.mode(kind), $0) }
    }

    @ViewBuilder
    private var imagePreview: some View {
        if model.kind == .image,
           case let .ready(_, _, previewImageURL) = model.linkScanState,
           let previewImageURL {
            AsyncImage(url: previewImageURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Image(systemName: "photo")
                        .font(AppTypography.font(size: AppTypography.previewIconSize, weight: .semibold))
                        .foregroundStyle(muted)
                default:
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(height: 132)
            .frame(maxWidth: .infinity)
            .clipped()
            .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.white.opacity(0.09))
            )
        }
    }

    private func modeIcon(for kind: DownloadKind) -> String {
        switch kind {
        case .video:
            return "play.rectangle"
        case .audio:
            return "waveform"
        case .image:
            return "photo"
        }
    }

    private func setHover(_ target: HoverTarget, _ isHovered: Bool) {
        withAnimation(.easeOut(duration: 0.12)) {
            if isHovered {
                hoveredTarget = target
            } else if hoveredTarget == target {
                hoveredTarget = nil
            }
        }
    }

    private func statusLine(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(muted)
            Spacer()
            Text(value)
                .foregroundStyle(primary)
        }
        .font(AppTypography.font(size: AppTypography.secondarySize, weight: .medium))
    }

    private func pickerRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.font(size: AppTypography.bodySize, weight: .semibold))
                .foregroundStyle(secondary)
            Spacer()
            content()
        }
    }

    private func optionRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                pickerLabel(title)
                    .frame(width: 90, alignment: .leading)
                content()
            }

            VStack(alignment: .leading, spacing: 6) {
                pickerLabel(title)
                content()
            }
        }
    }

    private func optionStrip<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 1) {
            content()
        }
        .padding(2)
        .background(Color.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(Color.white.opacity(0.08))
        )
    }

    private func segmentButton(title: String, isSelected: Bool, hoverTarget: HoverTarget, action: @escaping () -> Void) -> some View {
        let isHovered = hoveredTarget == hoverTarget

        return Button(action: action) {
            Text(title)
                .font(AppTypography.font(size: AppTypography.controlSize, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white.opacity(0.96) : (isHovered ? primary : secondary))
                .lineLimit(1)
                .frame(minWidth: 72)
                .frame(height: 32)
                .padding(.horizontal, 7)
                .background(segmentBackground(isSelected: isSelected, isHovered: isHovered), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { setHover(hoverTarget, $0) }
    }

    private func segmentBackground(isSelected: Bool, isHovered: Bool) -> Color {
        if isSelected {
            return Color.accentColor.opacity(isHovered ? 0.94 : 0.86)
        }

        return Color.white.opacity(isHovered ? 0.09 : 0)
    }

    private func pickerLabel(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.font(size: AppTypography.bodySize, weight: .semibold))
            .foregroundStyle(secondary)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(AppTypography.font(size: AppTypography.controlSize, weight: .semibold))
            Text(title)
                .font(AppTypography.font(size: AppTypography.sectionTitleSize, weight: .bold))
            Spacer()
        }
        .foregroundStyle(primary)
    }

    private func appMark(size: CGFloat) -> some View {
        Image(nsImage: NSApplication.shared.applicationIconImage)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .scaledToFit()
        .frame(width: size, height: size)
    }

    private func localized(en: String, zh: String, zhHant: String, th: String) -> String {
        switch model.language {
        case .english:
            return en
        case .simplifiedChinese:
            return zh
        case .traditionalChinese:
            return zhHant
        case .thai:
            return th
        }
    }
}

struct RedesignedContentView: View {
    private enum HoverTarget: Hashable {
        case check
        case download
        case cancel
        case outputDirectory
        case cookiesFile
        case mode(DownloadKind)
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var model = DownloadModel()
    @State private var hoveredTarget: HoverTarget?
    @State private var imagePreviewStartIndex = 0
    @State private var imagePreviewPageDirection = 1

    private let canvas = Color(nsColor: .windowBackgroundColor)
    private let panelFill = Color(nsColor: .controlBackgroundColor).opacity(0.42)
    private let recessedFill = Color(nsColor: .textBackgroundColor).opacity(0.62)
    private let separator = Color(nsColor: .separatorColor).opacity(0.75)
    private let primary = Color(nsColor: .labelColor)
    private let secondary = Color(nsColor: .secondaryLabelColor)
    private let muted = Color(nsColor: .tertiaryLabelColor)
    private let accent = Color.accentColor
    private let ready = Color(nsColor: .systemGreen)
    private let warning = Color(nsColor: .systemRed)

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Rectangle()
                .fill(separator)
                .frame(height: 1)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    linkCaptureSection
                    mediaSummarySection
                    settingsSection
                    if shouldShowRecentDownloads {
                        recentDownloadsSection
                    }
                }
                .frame(maxWidth: 1120, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.top, 30)
                .padding(.bottom, 44)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .background(background)
        .background(TitlebarDoubleClickInstaller().frame(width: 0, height: 0))
        .frame(minWidth: 940, minHeight: 700)
        .preferredColorScheme(.dark)
        .tint(accent)
        .onAppear {
            model.resetLinkScan()
        }
        .onChange(of: model.urls) {
            model.resetLinkScan()
        }
        .onChange(of: model.kind) {
            model.resetLinkScan()
        }
        .onChange(of: model.quality) {
            model.refreshCheckedSelection()
        }
        .onChange(of: model.videoFormat) {
            model.refreshCheckedSelection()
        }
        .onChange(of: model.audioFormat) {
            model.refreshCheckedSelection()
        }
        .onChange(of: model.includeVideoAudio) {
            model.refreshCheckedSelection()
        }
        .onChange(of: model.cookieSource) {
            model.resetLinkScan()
        }
        .onChange(of: model.cookieFilePath) {
            model.resetLinkScan()
        }
        .onChange(of: model.imagePreviewItems.map(\.url)) {
            imagePreviewStartIndex = ImagePreviewPager.clampedStartIndex(
                imagePreviewStartIndex,
                itemCount: model.imagePreviewItems.count
            )
        }
        .animation(AppMotion.stateAnimation(reduceMotion: reduceMotion), value: model.mediaSummary != nil)
        .animation(AppMotion.stateAnimation(reduceMotion: reduceMotion), value: model.isRunning)
        .animation(AppMotion.stateAnimation(reduceMotion: reduceMotion), value: model.downloadHistory.map(\.id))
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .controlBackgroundColor).opacity(0.92),
                canvas,
                Color(nsColor: .underPageBackgroundColor).opacity(0.78)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            appMark(size: 28)

            Text(appDisplayName)
                .font(AppTypography.font(size: 21, weight: .semibold))
                .foregroundStyle(primary)

            Text("version \(appVersion)")
                .font(AppTypography.font(size: AppTypography.captionSize, weight: .medium))
                .foregroundStyle(muted)

            Spacer()

            languagePicker
        }
        .padding(.horizontal, 24)
        .frame(height: 58)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.72))
    }

    private var linkCaptureSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localized(en: "Paste a link", zh: "粘贴链接", zhHant: "貼上連結", th: "วางลิงก์"))
                .font(AppTypography.font(size: 20, weight: .medium))
                .foregroundStyle(secondary)

            HStack(spacing: 14) {
                Image(systemName: "link")
                    .font(AppTypography.font(size: 21, weight: .medium))
                    .foregroundStyle(muted)
                    .frame(width: 34)

                PlaceholderTextEditor(
                    text: $model.urls,
                    placeholder: model.language.linksPlaceholder,
                    onSubmit: model.submitURLFromEditor
                )
                    .frame(height: 52)
                    .disabled(model.isRunning)

                inputTrailingControl
            }
            .padding(.horizontal, 16)
            .frame(height: 66)
            .background(recessedFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(inputAccent, lineWidth: inputBorderWidth)
            )
            .animation(AppMotion.fastAnimation(reduceMotion: reduceMotion), value: model.linkScanState)

            linkStatusLine
        }
    }

    @ViewBuilder
    private var linkStatusLine: some View {
        if shouldShowLinkStatusLine {
            HStack(spacing: 6) {
                Image(systemName: statusIcon)
                    .font(AppTypography.font(size: AppTypography.captionSize, weight: .semibold))
                Text(statusText)
                    .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
            }
            .foregroundStyle(statusColor)
            .padding(.leading, 10)
            .transition(appTransition(.topReveal))
        }
    }

    private var mediaSummarySection: some View {
        GroupBox {
            if let summary = model.mediaSummary {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 22) {
                        summaryPreview(summary)
                            .frame(
                                width: model.kind == .image ? ImagePreviewLayout.summaryPreviewWidth : 256,
                                height: model.kind == .image ? ImagePreviewLayout.summaryPreviewHeight : 144
                            )

                        summaryDetails(summary)
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        summaryPreview(summary)
                            .frame(height: model.kind == .image ? ImagePreviewLayout.summaryPreviewHeight : 180)
                        summaryDetails(summary)
                    }
                }
                .id("summary-\(model.kind.rawValue)")
                .transition(appTransition(.topReveal))
            } else {
                HStack(spacing: 14) {
                    Image(systemName: "link.badge.plus")
                        .font(AppTypography.font(size: 26, weight: .medium))
                        .foregroundStyle(muted)
                        .frame(width: 42, height: 42)
                        .background(panelFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 10) {
                        Text(emptySummaryTitle)
                            .font(AppTypography.font(size: 19, weight: .semibold))
                            .foregroundStyle(primary)
                        Text(emptySummaryMessage)
                            .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
                            .foregroundStyle(secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .id("summary-placeholder-\(emptySummaryTitle)")
                .transition(appTransition(AppMotion.summaryPlaceholderTransitionStyle(
                    isChecking: model.linkScanState == .checking,
                    reduceMotion: reduceMotion
                )))
            }
        }
        .groupBoxStyle(PanelGroupBoxStyle())
    }

    private var settingsSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 18) {
                modeAndFormatRow

                settingsControlRow(label: model.language.saveTo) {
                    outputDirectoryRow
                }

                if CookiePickerVisibility.shouldShow(for: model.urls) {
                    cookiesSettingsRow
                }

                if shouldShowIncludeAudioRow {
                    includeAudioRow
                }

                if shouldShowMetadataRow {
                    metadataRow
                }
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 22)
            .disabled(model.isRunning)

            progressMotionSection

            actionMotionSection
        }
        .background(panelFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(separator)
        )
    }

    @ViewBuilder
    private var progressMotionSection: some View {
        if shouldShowProgressBar {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(separator)
                    .frame(height: 1)

                activityProgressRow
                    .padding(.horizontal, 26)
                    .padding(.vertical, 14)
            }
            .transition(appTransition(AppMotion.activityTransitionStyle(
                isChecking: model.linkScanState == .checking,
                reduceMotion: reduceMotion
            )))
        }
    }

    @ViewBuilder
    private var actionMotionSection: some View {
        if shouldShowActionRow {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(separator)
                    .frame(height: 1)

                HStack(spacing: 16) {
                    if model.hasCheckedOptions && !model.isRunning {
                        secondaryButton(
                            title: model.language.check,
                            icon: "arrow.clockwise",
                            target: .check,
                            enabled: true,
                            action: model.recheckLinks
                        )
                    }

                    Spacer()

                    if model.isRunning {
                        secondaryButton(
                            title: model.language.cancel,
                            icon: "xmark",
                            target: .cancel,
                            enabled: true,
                            action: model.cancelDownload
                        )
                    }

                    primaryActionButton
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 18)
            }
            .transition(appTransition(AppMotion.activityTransitionStyle(
                isChecking: model.linkScanState == .checking,
                reduceMotion: reduceMotion
            )))
        }
    }

    private var recentDownloadsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localized(en: "Recent Downloads", zh: "最近下载", zhHant: "最近下載", th: "ดาวน์โหลดล่าสุด"))
                    .font(AppTypography.font(size: 20, weight: .medium))
                    .foregroundStyle(secondary)
                Spacer()
                Button(action: model.clearDownloadHistory) {
                    Text(localized(en: "Clear", zh: "清除", zhHant: "清除", th: "ล้าง"))
                        .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundStyle(accent)
                .contentShape(Rectangle())
            }

            VStack(spacing: 10) {
                ForEach(model.downloadHistory) { item in
                    recentDownloadRow(item)
                        .padding(13)
                        .background(recessedFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(separator)
                        )
                        .transition(appTransition(.topReveal))
                }
            }
        }
        .transition(appTransition(.topReveal))
    }

    private var shouldShowRecentDownloads: Bool {
        !model.downloadHistory.isEmpty
    }

    private var shouldShowActionRow: Bool {
        !model.parsedURLs.isEmpty || model.isRunning || model.linkScanState == .checking
    }

    private var shouldShowProgressBar: Bool {
        model.linkScanState == .checking || model.isRunning || model.userFacingErrorMessage != nil
    }

    private var activityProgressRow: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 10) {
                Text(progressTitle)
                    .font(AppTypography.font(size: AppTypography.bodySize, weight: .semibold))
                    .foregroundStyle(primary)

                Spacer()

                Text(progressDetail)
                    .font(AppTypography.font(size: AppTypography.secondarySize, weight: .medium))
                    .foregroundStyle(secondary)
                    .lineLimit(1)
            }

            if model.linkScanState == .checking {
                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(accent)
            } else {
                ProgressView(value: model.displayedProgress)
                    .progressViewStyle(.linear)
                    .tint(accent)
            }
        }
    }

    private var progressTitle: String {
        if model.linkScanState == .checking {
            return model.language.checkingLinks
        }

        if model.userFacingErrorMessage != nil {
            return model.language.error
        }

        return model.status
    }

    private var progressDetail: String {
        if model.linkScanState == .checking {
            return localized(en: "Preparing link details", zh: "正在准备链接详情", zhHant: "正在準備連結詳細資料", th: "กำลังเตรียมรายละเอียดลิงก์")
        }

        if let message = model.userFacingErrorMessage {
            return message
        }

        let percent = "\(Int(model.displayedProgress * 100))%"
        return "\(percent) · \(model.speedLabel) · \(model.etaLabel)"
    }

    private func summaryDetails(_ summary: MediaSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(summary.title)
                    .font(AppTypography.font(size: 21, weight: .bold))
                    .foregroundStyle(primary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Image(systemName: sourceIcon)
                        .foregroundStyle(accent)
                    Text(sourceLine(summary))
                        .foregroundStyle(secondary)
                        .lineLimit(1)
                }
                .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 60) {
                    summaryMetrics(summary)
                }

                HStack(spacing: 34) {
                    summaryMetrics(summary)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "doc")
                    .foregroundStyle(muted)
                Text(summary.outputFilename)
                    .font(AppTypography.font(size: AppTypography.secondarySize, weight: .medium))
                    .foregroundStyle(muted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func summaryPreview(_ summary: MediaSummary) -> some View {
        let items = model.imagePreviewItems
        if model.kind == .image, !items.isEmpty {
            imagePreviewStrip(items)
        } else {
            thumbnailView(url: summary.previewImageURL)
        }
    }

    private func imagePreviewStrip(_ items: [ImageDownloadItem]) -> some View {
        let visibleItems = ImagePreviewPager.visibleItems(from: items, startIndex: imagePreviewStartIndex)
        let canPageBackward = imagePreviewStartIndex > 0
        let canPageForward = imagePreviewStartIndex < ImagePreviewPager.clampedStartIndex(items.count, itemCount: items.count)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundStyle(accent)
                Text(imageCountLabel(items.count))
                    .font(AppTypography.font(size: AppTypography.secondarySize, weight: .semibold))
                    .foregroundStyle(secondary)
                Spacer(minLength: 0)

                if items.count > ImagePreviewLayout.visibleTileCount {
                    previewPagerButton(systemName: "chevron.left", isEnabled: canPageBackward) {
                        imagePreviewPageDirection = -1
                        runMotion {
                            imagePreviewStartIndex = ImagePreviewPager.previousIndex(from: imagePreviewStartIndex)
                        }
                    }
                    previewPagerButton(systemName: "chevron.right", isEnabled: canPageForward) {
                        imagePreviewPageDirection = 1
                        runMotion {
                            imagePreviewStartIndex = ImagePreviewPager.nextIndex(
                                from: imagePreviewStartIndex,
                                itemCount: items.count
                            )
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                ForEach(Array(visibleItems.enumerated()), id: \.element.url) { offset, item in
                    imagePreviewTile(
                        item: item,
                        index: imagePreviewStartIndex + offset,
                        total: items.count
                    )
                }
            }
            .id(imagePreviewStartIndex)
            .transition(imagePreviewPagingTransition)
        }
    }

    private func previewPagerButton(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(AppTypography.font(size: AppTypography.captionSize, weight: .bold))
                .frame(width: ImagePreviewLayout.pagerButtonSize, height: ImagePreviewLayout.pagerButtonSize)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? primary : muted)
        .background(recessedFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(separator)
        )
        .disabled(!isEnabled)
        .contentShape(Rectangle())
    }

    private func imagePreviewTile(item: ImageDownloadItem, index: Int, total: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            previewImageView(url: item.url)
                .frame(width: imagePreviewTileWidth(total: total), height: ImagePreviewLayout.tileHeight)

            Text("\(index + 1)")
                .font(AppTypography.font(size: AppTypography.captionSize, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.black.opacity(0.62), in: Capsule())
                .padding(7)
        }
    }

    private func imagePreviewTileWidth(total: Int) -> CGFloat {
        total == 1 ? ImagePreviewLayout.singleImageTileWidth : ImagePreviewLayout.multiImageTileWidth
    }

    private func imageCountLabel(_ count: Int) -> String {
        switch model.language {
        case .english:
            return count == 1 ? "1 image" : "\(count) images"
        case .simplifiedChinese:
            return "\(count) 张图片"
        case .traditionalChinese:
            return "\(count) 張圖片"
        case .thai:
            return "\(count) ภาพ"
        }
    }

    @ViewBuilder
    private func summaryMetrics(_ summary: MediaSummary) -> some View {
        metric(label: localized(en: "Duration", zh: "时长", zhHant: "長度", th: "ความยาว"), value: summary.duration)
        metric(label: localized(en: "Estimated Size", zh: "预计大小", zhHant: "預估大小", th: "ขนาดโดยประมาณ"), value: summary.estimatedSize)
        metric(label: localized(en: "Status", zh: "状态", zhHant: "狀態", th: "สถานะ"), value: model.language.ready, color: ready, icon: "checkmark.circle.fill")
    }

    private var modeAndFormatRow: some View {
        ViewThatFits(in: .horizontal) {
            settingsControlRow(label: localized(en: "Mode", zh: "模式", zhHant: "模式", th: "โหมด")) {
                ZStack(alignment: .leading) {
                    HStack {
                        Spacer(minLength: AppControlMetrics.settingsOutputGroupSpacing)
                        formatQualityControls
                    }

                    modeControl
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 16) {
                settingsControlRow(label: localized(en: "Mode", zh: "模式", zhHant: "模式", th: "โหมด")) {
                    modeControl
                }

                settingsControlRow(label: localized(en: "Format", zh: "格式", zhHant: "格式", th: "รูปแบบ")) {
                    formatQualityControls
                }
            }
        }
    }

    private var cookiesSettingsRow: some View {
        settingsControlRow(label: model.language.cookies) {
            HStack(spacing: 12) {
                cookieSourcePicker
                    .frame(width: 190)

                if model.cookieSource == .file {
                    cookiesFileRow
                } else {
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var shouldShowIncludeAudioRow: Bool {
        SettingsLayout.rows(
            for: model.kind,
            showsCookies: CookiePickerVisibility.shouldShow(for: model.urls)
        ).contains(.includeAudio)
    }

    private var shouldShowMetadataRow: Bool {
        SettingsLayout.rows(
            for: model.kind,
            showsCookies: CookiePickerVisibility.shouldShow(for: model.urls)
        ).contains(.metadata)
    }

    private var includeAudioRow: some View {
        settingsControlRow(label: localized(en: "Audio", zh: "音频", zhHant: "音訊", th: "เสียง")) {
            Toggle(model.language.includeAudio, isOn: $model.includeVideoAudio)
                .toggleStyle(.checkbox)
                .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
                .foregroundStyle(secondary)

            Spacer(minLength: 0)
        }
    }

    private var metadataRow: some View {
        settingsControlRow(label: localized(en: "Metadata", zh: "元数据", zhHant: "中繼資料", th: "เมทาดาต้า")) {
            HStack(spacing: AppControlMetrics.settingsCheckboxSpacing) {
                metadataToggle
                artworkToggle
                subtitlesToggle
                Spacer(minLength: 0)
            }
        }
        .toggleStyle(.checkbox)
        .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
        .foregroundStyle(secondary)
    }

    private var metadataToggle: some View {
        Toggle(model.language.metadata, isOn: .constant(true))
            .disabled(true)
            .opacity(0.45)
    }

    @ViewBuilder
    private var artworkToggle: some View {
        if model.kind == .video {
            Toggle(model.language.artwork, isOn: $model.embedArtwork)
        } else {
            Toggle(model.language.artwork, isOn: .constant(false))
                .disabled(true)
                .opacity(0.45)
        }
    }

    @ViewBuilder
    private var subtitlesToggle: some View {
        if model.kind == .video {
            Toggle(model.language.subtitles, isOn: $model.includeSubtitles)
        } else {
            Toggle(model.language.subtitles, isOn: .constant(false))
                .disabled(true)
                .opacity(0.45)
        }
    }

    private func recentDownloadRow(_ item: DownloadHistoryItem) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                recentThumbnail(item)
                recentTextBlock(item)
                Spacer()
                recentStatus(item)
                recentActions(item)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    recentThumbnail(item)
                    recentTextBlock(item)
                }
                HStack {
                    recentStatus(item)
                    Spacer()
                    recentActions(item)
                }
            }
        }
    }

    private func recentThumbnail(_ item: DownloadHistoryItem) -> some View {
        thumbnailView(url: item.previewImageURL)
            .frame(width: 146, height: 82)
    }

    private func recentTextBlock(_ item: DownloadHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(AppTypography.font(size: AppTypography.bodySize, weight: .bold))
                .foregroundStyle(primary)
                .lineLimit(1)
            Text("\(item.outputFilename) · \(item.estimatedSize)")
                .font(AppTypography.font(size: AppTypography.secondarySize, weight: .medium))
                .foregroundStyle(muted)
                .lineLimit(1)
        }
    }

    private func recentStatus(_ item: DownloadHistoryItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(ready)
            Text(model.language.finished)
                .foregroundStyle(secondary)
        }
        .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
    }

    private func recentActions(_ item: DownloadHistoryItem) -> some View {
        HStack(spacing: 12) {
            historyIconButton(systemName: "arrow.clockwise", label: localized(en: "Download again", zh: "重新下载", zhHant: "重新下載", th: "โหลดซ้ำ")) {
                model.repeatDownload(item)
            }
            historyIconButton(systemName: "trash", label: localized(en: "Remove", zh: "移除", zhHant: "移除", th: "ลบ")) {
                model.removeDownloadHistoryItem(item)
            }
        }
        .disabled(model.isRunning)
    }

    private func historyIconButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(AppTypography.font(size: 17, weight: .semibold))
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .foregroundStyle(muted)
        .contentShape(Rectangle())
        .help(label)
    }

    private var modeControl: some View {
        HStack(spacing: 0) {
            ForEach(DownloadKind.allCases) { kind in
                modeSegmentButton(kind)
            }
        }
        .background(Color(nsColor: .controlColor).opacity(0.72), in: Capsule())
        .clipShape(Capsule())
        .fixedSize()
        .animation(AppMotion.fastAnimation(reduceMotion: reduceMotion), value: model.kind)
    }

    private func modeSegmentButton(_ kind: DownloadKind) -> some View {
        let isSelected = model.kind == kind

        return Text(model.language.kindLabel(kind))
            .font(AppTypography.font(size: AppTypography.controlSize, weight: .semibold))
            .foregroundStyle(isSelected ? primary : secondary)
            .frame(width: 62, height: 34)
            .background {
                if isSelected {
                    Capsule()
                        .fill(accent)
                }
            }
            .overlay(alignment: .trailing) {
                if kind != DownloadKind.allCases.last && !isSelected {
                    Rectangle()
                        .fill(separator)
                        .frame(width: 1, height: 20)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                runMotion {
                    model.kind = kind
                }
            }
            .accessibilityLabel(model.language.kindLabel(kind))
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var formatQualityControls: some View {
        if model.kind.usesFormatAndQualityControls {
            HStack(spacing: AppControlMetrics.settingsInlineControlSpacing) {
                inlineControlField(title: localized(en: "Format", zh: "格式", zhHant: "格式", th: "รูปแบบ")) {
                    formatPicker
                }

                inlineControlField(title: model.language.quality) {
                    qualityPicker
                }
            }
        } else {
            inlineStaticField(
                title: localized(en: "Format", zh: "格式", zhHant: "格式", th: "รูปแบบ"),
                value: localized(en: "Original", zh: "原始", zhHant: "原始", th: "ต้นฉบับ")
            )
        }
    }

    @ViewBuilder
    private var inputTrailingControl: some View {
        if model.linkScanState == .checking {
            ProgressView()
                .controlSize(.small)
                .frame(width: 32)
                .id("checking")
                .transition(inputTrailingTransition)
        } else if model.canUsePrimaryButton && !model.hasCheckedOptions {
            Button(action: model.checkLinks) {
                Image(systemName: "arrow.right.circle")
                    .font(AppTypography.font(size: 22, weight: .semibold))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .foregroundStyle(accent)
            .contentShape(Rectangle())
            .help(model.language.check)
            .id("check")
            .transition(inputTrailingTransition)
        } else if model.canDownload {
            Image(systemName: "checkmark.circle.fill")
                .font(AppTypography.font(size: 22, weight: .semibold))
                .foregroundStyle(ready)
                .frame(width: 32)
                .id("ready")
                .transition(inputTrailingTransition)
        } else if model.hasCheckedOptions && !model.currentSelectionIsFulfillable {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AppTypography.font(size: 20, weight: .semibold))
                .foregroundStyle(warning)
                .frame(width: 32)
                .id("selection-warning")
                .transition(inputTrailingTransition)
        } else if model.linkScanState == .unavailable || model.linkScanState == .missingTools {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(AppTypography.font(size: 20, weight: .semibold))
                .foregroundStyle(warning)
                .frame(width: 32)
                .id("warning")
                .transition(inputTrailingTransition)
        } else {
            Color.clear
                .frame(width: 32)
                .id("empty")
                .transition(inputTrailingTransition)
        }
    }

    private var primaryActionButton: some View {
        Group {
            if model.canUsePrimaryButton {
                Button(action: model.performPrimaryAction) {
                    primaryActionLabel
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: {}) {
                    primaryActionLabel
                }
                .buttonStyle(.bordered)
                .disabled(true)
            }
        }
        .controlSize(.large)
        .onHover { hoveredTarget = $0 ? .download : nil }
    }

    private var primaryActionLabel: some View {
        Label(model.primaryButtonTitle, systemImage: model.canDownload ? "arrow.down" : "checkmark")
            .font(AppTypography.font(size: AppTypography.controlSize, weight: .semibold))
            .frame(minWidth: 148)
            .id(model.primaryButtonTitle)
            .transition(reduceMotion ? .identity : .opacity)
    }

    @ViewBuilder
    private var formatPicker: some View {
        if model.kind == .audio {
            fixedMenuButton(title: model.audioFormat.rawValue.uppercased(), width: AppControlMetrics.compactMenuWidth) {
                ForEach(AudioFormat.allCases) { format in
                    selectableMenuButton(
                        title: format.rawValue.uppercased(),
                        isSelected: model.audioFormat == format
                    ) {
                        model.audioFormat = format
                    }
                }
            }
        } else if model.kind == .video {
            fixedMenuButton(title: model.language.videoFormatLabel(model.videoFormat), width: AppControlMetrics.compactMenuWidth) {
                ForEach(VideoFormat.allCases) { format in
                    selectableMenuButton(
                        title: model.language.videoFormatLabel(format),
                        isSelected: model.videoFormat == format
                    ) {
                        model.videoFormat = format
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var qualityPicker: some View {
        if model.kind == .video {
            fixedMenuButton(title: model.qualityControlTitle, width: AppControlMetrics.compactMenuWidth) {
                ForEach(model.availableVideoQualities) { quality in
                    selectableMenuButton(
                        title: quality.label,
                        isSelected: model.selectedVideoQuality == quality
                    ) {
                        model.selectVideoQuality(quality)
                    }
                }
            }
            .disabled(!model.isQualityControlEnabled)
        } else if model.kind == .audio {
            fixedMenuButton(title: "Best", width: AppControlMetrics.compactMenuWidth) {
                Text("Best")
            }
            .disabled(true)
        }
    }

    private func fixedMenuButton<Content: View>(
        title: String,
        width: CGFloat,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Menu {
            content()
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(AppTypography.font(size: AppTypography.controlSize, weight: .semibold))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up.chevron.down")
                    .font(AppTypography.font(size: 11, weight: .semibold))
                    .foregroundStyle(muted)
            }
            .foregroundStyle(primary)
            .padding(.horizontal, 12)
            .frame(width: width, height: 34)
            .background(Color(nsColor: .controlColor).opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(separator)
            )
            .contentShape(Rectangle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .frame(width: width)
    }

    private func selectableMenuButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if isSelected {
                Label(title, systemImage: "checkmark")
            } else {
                Text(title)
            }
        }
    }

    private var languagePicker: some View {
        Picker(model.language.language, selection: $model.language) {
            ForEach(AppLanguage.allCases) { language in
                Text(language.menuTitle).tag(language)
            }
        }
        .labelsHidden()
        .frame(width: 134)
    }

    private var cookieSourcePicker: some View {
        Picker("", selection: $model.cookieSource) {
            ForEach(CookieSource.allCases) { source in
                Text(model.language.cookieSourceLabel(source)).tag(source)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
    }

    private var outputDirectoryRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .foregroundStyle(accent)
            Text(model.outputDirectory)
                .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
                .foregroundStyle(secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Button(action: model.chooseDirectory) {
                Text(localized(en: "Browse...", zh: "浏览...", zhHant: "瀏覽...", th: "เลือก..."))
                    .font(AppTypography.font(size: AppTypography.controlSize, weight: .semibold))
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .frame(height: 50)
        .background(recessedFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(separator)
        )
    }

    private var cookiesFileRow: some View {
        Button(action: model.chooseCookiesFile) {
            HStack(spacing: 10) {
                Image(systemName: "doc.text")
                    .foregroundStyle(muted)
                Text(model.cookieFilePath.isEmpty ? model.language.cookiesFilePlaceholder : model.cookieFilePath)
                    .font(AppTypography.font(size: AppTypography.bodySize, weight: .medium))
                    .foregroundStyle(model.cookieFilePath.isEmpty ? muted : secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(recessedFill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(separator)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hoveredTarget = $0 ? .cookiesFile : nil }
    }

    private func settingsControlRow<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: AppControlMetrics.settingsLabelToControlSpacing) {
            fieldLabel(label)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func inlineControlField<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 10) {
            inlineFieldLabel(title)
            content()
                .frame(width: AppControlMetrics.compactMenuWidth)
                .controlSize(.large)
        }
    }

    private func inlineStaticField(title: String, value: String) -> some View {
        HStack(spacing: 10) {
            inlineFieldLabel(title)
            Text(value)
                .font(AppTypography.font(size: AppTypography.controlSize, weight: .semibold))
                .foregroundStyle(secondary)
                .frame(width: AppControlMetrics.compactMenuWidth, alignment: .leading)
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.font(size: AppTypography.bodySize, weight: .semibold))
            .foregroundStyle(primary)
            .frame(width: AppControlMetrics.settingsFieldLabelWidth, alignment: .leading)
    }

    private func inlineFieldLabel(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.font(size: AppTypography.bodySize, weight: .semibold))
            .foregroundStyle(secondary)
    }

    private func metric(label: String, value: String, color: Color? = nil, icon: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppTypography.font(size: AppTypography.secondarySize, weight: .medium))
                .foregroundStyle(muted)

            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(AppTypography.font(size: AppTypography.captionSize, weight: .bold))
                }
                Text(value)
                    .lineLimit(1)
            }
            .font(AppTypography.font(size: 18, weight: .semibold))
            .foregroundStyle(color ?? primary)
        }
    }

    private func secondaryButton(title: String, icon: String, target: HoverTarget, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(AppTypography.font(size: AppTypography.controlSize, weight: .semibold))
                .frame(minWidth: 112)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .disabled(!enabled)
        .onHover { hoveredTarget = $0 ? target : nil }
    }

    @ViewBuilder
    private func thumbnailView(url: URL?) -> some View {
        if let url {
            GeometryReader { proxy in
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                    case .failure:
                        thumbnailPlaceholder
                    default:
                        ZStack {
                            thumbnailPlaceholder
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }
            .background(recessedFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } else {
            thumbnailPlaceholder
        }
    }

    @ViewBuilder
    private func previewImageView(url: URL) -> some View {
        GeometryReader { proxy in
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                case .failure:
                    thumbnailPlaceholder
                default:
                    ZStack {
                        thumbnailPlaceholder
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .background(recessedFill, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(separator)
        )
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            recessedFill
            appMark(size: 42)
                .opacity(0.88)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(separator)
        )
    }

    private var statusBadge: some View {
        HStack(spacing: 7) {
            Image(systemName: statusIcon)
            Text(statusBadgeText)
                .lineLimit(1)
        }
        .font(AppTypography.font(size: AppTypography.secondarySize, weight: .semibold))
        .foregroundStyle(statusColor)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(panelFill, in: Capsule())
        .overlay(Capsule().stroke(separator))
    }

    private var primaryActionBackground: LinearGradient {
        let active = model.canUsePrimaryButton
        return LinearGradient(
            colors: [
                active ? accent.opacity(0.98) : panelFill,
                active ? accent.opacity(0.76) : recessedFill
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var imagePreviewPagingTransition: AnyTransition {
        guard !reduceMotion else { return .identity }

        let insertionEdge: Edge = imagePreviewPageDirection >= 0 ? .trailing : .leading
        let removalEdge: Edge = imagePreviewPageDirection >= 0 ? .leading : .trailing
        return .asymmetric(
            insertion: .opacity.combined(with: .move(edge: insertionEdge)),
            removal: .opacity.combined(with: .move(edge: removalEdge))
        )
    }

    private var inputTrailingTransition: AnyTransition {
        appTransition(.scaleFade)
    }

    private func appTransition(_ style: AppMotionTransitionStyle) -> AnyTransition {
        switch style {
        case .identity:
            return .identity
        case .fade:
            return .opacity
        case .topReveal:
            return reduceMotion ? .identity : .opacity.combined(with: .move(edge: .top))
        case .scaleFade:
            return reduceMotion ? .identity : .opacity.combined(with: .scale(scale: 0.94))
        }
    }

    private func runMotion(_ updates: () -> Void) {
        withAnimation(AppMotion.stateAnimation(reduceMotion: reduceMotion)) {
            updates()
        }
    }

    private var inputAccent: Color {
        switch model.linkScanState {
        case .ready:
            ready
        case .checking:
            accent
        case .unavailable, .missingTools:
            warning
        case .empty, .needsCheck:
            separator
        }
    }

    private var inputBorderWidth: CGFloat {
        switch model.linkScanState {
        case .ready, .checking, .unavailable, .missingTools:
            1.4
        case .empty, .needsCheck:
            1
        }
    }

    private var inputTrailingIcon: String {
        switch model.linkScanState {
        case .ready:
            "checkmark.circle.fill"
        case .checking:
            "clock.arrow.circlepath"
        case .unavailable, .missingTools:
            "exclamationmark.triangle.fill"
        case .empty, .needsCheck:
            "arrow.right.circle"
        }
    }

    private var statusIcon: String {
        switch model.linkScanState {
        case .empty:
            "link"
        case .needsCheck:
            "checkmark"
        case .checking:
            "clock.arrow.circlepath"
        case .ready:
            "checkmark"
        case .unavailable, .missingTools:
            "exclamationmark.triangle"
        }
    }

    private var statusText: String {
        switch model.linkScanState {
        case .empty:
            return model.language.pasteLinkStatus
        case let .needsCheck(count):
            return count > 1
                ? "\(model.language.check) \(count) \(model.language.links)"
                : model.language.check
        case .checking:
            return model.language.checkingLinks
        case .ready:
            return localized(en: "Link is valid and supported", zh: "链接有效且受支持", zhHant: "連結有效且支援", th: "ลิงก์ถูกต้องและรองรับ")
        case .unavailable:
            return model.language.unavailable
        case .missingTools:
            return model.language.missingTools
        }
    }

    private var statusBadgeText: String {
        switch model.linkScanState {
        case let .ready(totalBytes, count, _):
            let size = totalBytes.map(MediaSummary.byteLabelForUI) ?? localized(en: "size unknown", zh: "大小未知", zhHant: "大小未知", th: "ไม่ทราบขนาด")
            return count > 1 ? "\(model.language.ready) · \(count) · \(size)" : "\(model.language.ready) · \(size)"
        default:
            return statusText
        }
    }

    private var statusColor: Color {
        switch model.linkScanState {
        case .ready:
            ready
        case .unavailable, .missingTools:
            warning
        case .checking:
            accent
        case .empty, .needsCheck:
            muted
        }
    }

    private var shouldShowLinkStatusLine: Bool {
        switch model.linkScanState {
        case .unavailable, .missingTools:
            return true
        case .empty, .needsCheck, .checking, .ready:
            return false
        }
    }

    private var emptySummaryTitle: String {
        switch model.linkScanState {
        case .checking:
            return model.language.checkingLinks
        case .unavailable:
            return model.language.unavailable
        case .missingTools:
            return model.language.missingTools
        default:
            return localized(en: "Media details will appear here", zh: "媒体详情会显示在这里", zhHant: "媒體詳細資料會顯示在這裡", th: "รายละเอียดสื่อจะแสดงที่นี่")
        }
    }

    private var emptySummaryMessage: String {
        switch model.linkScanState {
        case .checking:
            return localized(en: "Downlink is checking the link and estimating the output.", zh: "Downlink 正在检查链接并估算输出。", zhHant: "Downlink 正在檢查連結並預估輸出。", th: "Downlink กำลังตรวจลิงก์และประเมินไฟล์ผลลัพธ์")
        case .unavailable:
            return model.linkCheckFailure?.message(for: model.language)
                ?? localized(en: "This link could not be prepared for download.", zh: "无法准备下载此链接。", zhHant: "無法準備下載此連結。", th: "ไม่สามารถเตรียมลิงก์นี้สำหรับดาวน์โหลดได้")
        case .missingTools:
            return model.linkCheckFailure?.message(for: model.language)
                ?? localized(en: "A required downloader component is unavailable.", zh: "所需的下载组件不可用。", zhHant: "所需的下載元件無法使用。", th: "ส่วนประกอบดาวน์โหลดที่จำเป็นไม่พร้อมใช้งาน")
        default:
            return localized(en: "Paste a supported link, then check it before downloading.", zh: "粘贴支持的链接，然后先检查再下载。", zhHant: "貼上支援的連結，下載前先檢查。", th: "วางลิงก์ที่รองรับ แล้วตรวจสอบก่อนดาวน์โหลด")
        }
    }

    private var sourceIcon: String {
        switch model.kind {
        case .video:
            return "play.rectangle.fill"
        case .audio:
            return "waveform"
        case .image:
            return "photo.fill"
        }
    }

    private func sourceLine(_ summary: MediaSummary) -> String {
        [summary.source, summary.creator]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " · ")
    }

    private var recentSubtitle: String {
        guard let summary = model.mediaSummary else {
            return localized(en: "Checked items will stay visible while this window is open", zh: "已检查的项目会显示在这里", zhHant: "已檢查的項目會顯示在這裡", th: "รายการที่ตรวจแล้วจะแสดงที่นี่")
        }

        return "\(summary.outputFilename) · \(summary.estimatedSize)"
    }

    private var recentStatusText: String {
        if model.isRunning {
            return model.status
        }

        if model.completedJobCount > 0 {
            return model.language.finished
        }

        if model.canDownload {
            return model.language.ready
        }

        return model.status
    }

    private var recentStatusIcon: String {
        if model.isRunning {
            return "arrow.down.circle"
        }

        if model.completedJobCount > 0 || model.canDownload {
            return "checkmark.circle.fill"
        }

        return "circle"
    }

    private var recentStatusColor: Color {
        model.completedJobCount > 0 || model.canDownload ? ready : muted
    }

    private func appMark(size: CGFloat) -> some View {
        Image(nsImage: NSApplication.shared.applicationIconImage)
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .scaledToFit()
            .frame(width: size, height: size)
    }

    private func localized(en: String, zh: String, zhHant: String, th: String) -> String {
        switch model.language {
        case .english:
            return en
        case .simplifiedChinese:
            return zh
        case .traditionalChinese:
            return zhHant
        case .thai:
            return th
        }
    }
}

struct PanelGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.content
            .padding(18)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.42), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.75))
            )
    }
}

@main
struct DownlinkApp: App {
    var body: some Scene {
        WindowGroup {
            RedesignedContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1120, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appSettings) {}
        }
    }
}
