import SwiftUI
import AppKit
import Foundation

private let appDisplayName = "Downlink"

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
        case .english: return "Embed metadata and artwork"
        case .simplifiedChinese: return "嵌入元数据和封面"
        case .traditionalChinese: return "嵌入中繼資料和封面"
        case .thai: return "ฝังข้อมูลเมตาและภาพปก"
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
        case .english: return "Downloader and FFmpeg are ready."
        case .simplifiedChinese: return "下载器和 FFmpeg 已就绪。"
        case .traditionalChinese: return "下載器和 FFmpeg 已就緒。"
        case .thai: return "ตัวดาวน์โหลดและ FFmpeg พร้อมใช้งาน"
        }
    }

    var dependencyMissing: String {
        switch self {
        case .english: return "Install yt-dlp and ffmpeg, or bundle them inside the app."
        case .simplifiedChinese: return "请安装 yt-dlp 和 ffmpeg，或把它们内置到应用包中。"
        case .traditionalChinese: return "請安裝 yt-dlp 和 ffmpeg，或把它們內建到應用程式中。"
        case .thai: return "ติดตั้ง yt-dlp และ ffmpeg หรือรวมไว้ในแอป"
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
        }
    }

    func videoFormatLabel(_ format: VideoFormat) -> String {
        switch format {
        case .mp4: return "MP4"
        case .mkv: return "MKV"
        case .webm: return "WEBM"
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

    func missingToolLog(ytDlpFound: Bool, ffmpegFound: Bool) -> String {
        switch self {
        case .english:
            return "Missing dependency: yt-dlp \(ytDlpFound ? "found" : "missing"), ffmpeg \(ffmpegFound ? "found" : "missing"). Install with: brew install yt-dlp ffmpeg\n"
        case .simplifiedChinese:
            return "缺少依赖：yt-dlp \(ytDlpFound ? "已找到" : "未找到")，ffmpeg \(ffmpegFound ? "已找到" : "未找到")。安装命令：brew install yt-dlp ffmpeg\n"
        case .traditionalChinese:
            return "缺少依賴：yt-dlp \(ytDlpFound ? "已找到" : "未找到")，ffmpeg \(ffmpegFound ? "已找到" : "未找到")。安裝命令：brew install yt-dlp ffmpeg\n"
        case .thai:
            return "ขาดเครื่องมือ: yt-dlp \(ytDlpFound ? "พบแล้ว" : "ไม่พบ"), ffmpeg \(ffmpegFound ? "พบแล้ว" : "ไม่พบ") ติดตั้งด้วย: brew install yt-dlp ffmpeg\n"
        }
    }
}

enum DownloadKind: String, CaseIterable, Identifiable {
    case video
    case audio

    var id: String { rawValue }
}

enum VideoFormat: String, CaseIterable, Identifiable {
    case mp4
    case mkv
    case webm
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
    case aac

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

struct DependencyStatus {
    let ytDlpPath: String?
    let ffmpegPath: String?

    var isReady: Bool {
        ytDlpPath != nil && ffmpegPath != nil
    }
}

enum LinkScanState: Equatable, Sendable {
    case empty
    case checking
    case ready(totalBytes: Int64?, count: Int)
    case unavailable
    case missingTools
}

struct DownloadJob: Sendable {
    let url: String
    let arguments: [String]
    let index: Int
    let total: Int
}

@MainActor
final class DownloadModel: ObservableObject, @unchecked Sendable {
    @Published var urls = ""
    @Published var outputDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? NSHomeDirectory()
    @Published var language: AppLanguage = .english {
        didSet {
            status = language.ready
            if logText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || logText == oldValue.initialLog {
                logText = language.initialLog
            }
        }
    }
    @Published var kind: DownloadKind = .video
    @Published var videoFormat: VideoFormat = .mp4
    @Published var audioFormat: AudioFormat = .mp3
    @Published var quality: Quality = .p1080
    @Published var includeSubtitles = false
    @Published var embedMetadata = true
    @Published var isRunning = false
    @Published var status = AppLanguage.english.ready
    @Published var logText = AppLanguage.english.initialLog
    @Published var activeJobIndex: Int?
    @Published var completedJobCount = 0
    @Published var progressFraction = 0.0
    @Published var speedLabel = "0 KB/s"
    @Published var etaLabel = "--"
    @Published var downloadedLabel = "--"
    @Published var linkScanState: LinkScanState = .empty

    private var currentProcess: Process?
    private var linkScanTask: Task<Void, Never>?
    private var currentJobStartDate: Date?
    private var currentDownloadedBytes: Int64?
    private var currentTotalBytes: Int64?
    private var smoothedBytesPerSecond: Double?
    private var smoothedRemainingSeconds: Double?

    var parsedURLs: [String] {
        urls
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var canDownload: Bool {
        !isRunning && !parsedURLs.isEmpty
    }

    var dependencyStatus: DependencyStatus {
        DependencyStatus(
            ytDlpPath: findExecutable(named: "yt-dlp", fallbackPaths: [
                "/opt/homebrew/bin/yt-dlp",
                "/usr/local/bin/yt-dlp",
                "/usr/bin/yt-dlp"
            ]),
            ffmpegPath: findExecutable(named: "ffmpeg", fallbackPaths: [
                "/opt/homebrew/bin/ffmpeg",
                "/usr/local/bin/ffmpeg",
                "/usr/bin/ffmpeg"
            ])
        )
    }

    func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = language.choose

        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url.path
        }
    }

    func scheduleLinkScan() {
        linkScanTask?.cancel()

        let urls = parsedURLs
        guard !urls.isEmpty else {
            linkScanState = .empty
            return
        }

        let dependencies = dependencyStatus
        guard let ytDlpPath = dependencies.ytDlpPath else {
            linkScanState = .missingTools
            return
        }

        linkScanState = .checking

        let argumentGroups = urls.map { scanArguments(for: $0) }
        linkScanTask = Task { [weak self, ytDlpPath, argumentGroups] in
            do {
                try await Task.sleep(nanoseconds: 650_000_000)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            let result = await LinkScanner.scan(ytDlpPath: ytDlpPath, argumentGroups: argumentGroups)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard let self, !Task.isCancelled else { return }
                self.linkScanState = result
            }
        }
    }

    func startDownload() {
        guard canDownload else { return }

        let dependencies = dependencyStatus
        guard let ytDlpPath = dependencies.ytDlpPath, let ffmpegPath = dependencies.ffmpegPath else {
            appendLog(language.missingToolLog(
                ytDlpFound: dependencies.ytDlpPath != nil,
                ffmpegFound: dependencies.ffmpegPath != nil
            ))
            status = language.missingTools
            return
        }

        isRunning = true
        status = language.downloading
        activeJobIndex = nil
        completedJobCount = 0
        progressFraction = 0
        speedLabel = "0 KB/s"
        etaLabel = "--"
        downloadedLabel = "--"
        resetTransferEstimates()
        appendLog("\n\(language.downloading) \(parsedURLs.count) item(s)...\n")

        let jobs = parsedURLs.enumerated().map { offset, url in
            DownloadJob(
                url: url,
                arguments: arguments(for: url, ffmpegPath: ffmpegPath),
                index: offset + 1,
                total: parsedURLs.count
            )
        }

        Task.detached(priority: .userInitiated) { [weak self] in
            for job in jobs {
                guard await self?.isStillRunning() == true else { break }
                await self?.runSingleDownload(ytDlpPath: ytDlpPath, job: job)
                guard await self?.isStillRunning() == true else { break }
            }

            await self?.finishQueue()
        }
    }

    func cancelDownload() {
        currentProcess?.terminate()
        isRunning = false
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

    private func isStillRunning() -> Bool {
        isRunning
    }

    private func finishQueue() {
        currentProcess = nil
        isRunning = false
        activeJobIndex = nil
        speedLabel = "0 KB/s"
        etaLabel = "--"
        resetTransferEstimates()
        if status != language.cancelled {
            status = language.finished
            appendLog("\n\(language.finished).\n")
        }
    }

    private func beginJob(_ job: DownloadJob) {
        activeJobIndex = job.index
        progressFraction = 0
        speedLabel = "0 KB/s"
        etaLabel = "--"
        downloadedLabel = "--"
        resetTransferEstimates()
        status = "\(language.downloading) \(job.index)/\(job.total)"
        appendLog("\n[\(job.index)/\(job.total)] \(job.url)\n")
    }

    private func setCurrentProcess(_ process: Process?) {
        currentProcess = process
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
            appendLog("[\(job.index)/\(job.total)] Exit code: \(exitCode).\n")
        }
    }

    private func arguments(for url: String, ffmpegPath: String) -> [String] {
        var args: [String] = [
            "--newline",
            "--progress",
            "--no-mtime",
            "--ffmpeg-location", URL(fileURLWithPath: ffmpegPath).deletingLastPathComponent().path,
            "--paths", outputDirectory,
            "--trim-filenames", "180",
            "--output", outputTemplate
        ]

        if embedMetadata {
            args.append("--embed-metadata")
            args.append("--embed-thumbnail")
        }

        if includeSubtitles {
            args.append("--write-subs")
            args.append("--write-auto-subs")
            args.append("--sub-langs")
            args.append("all,-live_chat")
        }

        switch kind {
        case .video:
            args.append(contentsOf: ["--format", quality.formatSelector])
            if let outputFormat = videoFormat.argumentValue {
                args.append("--merge-output-format")
                args.append(outputFormat)
                args.append("--remux-video")
                args.append(outputFormat)
            }
        case .audio:
            args.append("--extract-audio")
            args.append("--audio-format")
            args.append(audioFormat.rawValue)
            args.append("--audio-quality")
            args.append("0")
        }

        args.append(url)
        return args
    }

    private func scanArguments(for url: String) -> [String] {
        var args = [
            "--dump-json",
            "--skip-download",
            "--no-warnings",
            "--no-playlist"
        ]

        switch kind {
        case .video:
            args.append(contentsOf: ["--format", quality.formatSelector])
        case .audio:
            args.append(contentsOf: ["--format", "bestaudio/best"])
        }

        args.append(url)
        return args
    }

    private var outputTemplate: String {
        let descriptor: String
        switch kind {
        case .video:
            descriptor = quality.filenameLabel
        case .audio:
            descriptor = audioFormat.rawValue.uppercased()
        }

        return "%(title)s [\(descriptor)].%(ext)s"
    }

    private nonisolated func runSingleDownload(ytDlpPath: String, job: DownloadJob) async {
        await beginJob(job)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytDlpPath)
        process.arguments = job.arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        await setCurrentProcess(process)

        do {
            try process.run()
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

            await finishJob(job, exitCode: process.terminationStatus)
        } catch {
            await failToStart(error)
        }
    }

    private func failToStart(_ error: Error) {
        appendLog("Failed to start yt-dlp: \(error.localizedDescription)\n")
        status = language.error
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
    static func scan(ytDlpPath: String, argumentGroups: [[String]]) async -> LinkScanState {
        var totalBytes: Int64 = 0
        var hasKnownSize = false

        for arguments in argumentGroups {
            guard let metadata = runMetadataProbe(ytDlpPath: ytDlpPath, arguments: arguments) else {
                return .unavailable
            }

            if let bytes = estimatedBytes(from: metadata), bytes > 0 {
                totalBytes += bytes
                hasKnownSize = true
            }
        }

        return .ready(totalBytes: hasKnownSize ? totalBytes : nil, count: argumentGroups.count)
    }

    private static func runMetadataProbe(ytDlpPath: String, arguments: [String]) -> [String: Any]? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytDlpPath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        guard let output = String(data: data, encoding: .utf8) else { return nil }

        return output
            .split(separator: "\n")
            .compactMap { line -> [String: Any]? in
                guard let data = line.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return nil
                }
                return json
            }
            .first
    }

    private static func estimatedBytes(from metadata: [String: Any]) -> Int64? {
        if let requestedFormats = metadata["requested_formats"] as? [[String: Any]] {
            let sizes = requestedFormats.compactMap(formatBytes)
            guard !sizes.isEmpty else { return nil }
            return sizes.reduce(0, +)
        }

        return formatBytes(metadata)
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

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
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
        nsView.update(text: text, placeholder: placeholder)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        weak var host: PlaceholderTextEditorHost?

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
            host?.setPlaceholderVisible(textView.string.isEmpty)
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
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = NSColor.white.withAlphaComponent(0.94)
        textView.insertionPointColor = NSColor.systemRed
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
        placeholderLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        placeholderLabel.textColor = NSColor.white.withAlphaComponent(0.36)
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
            model.scheduleLinkScan()
        }
        .onChange(of: model.urls) {
            model.scheduleLinkScan()
        }
        .onChange(of: model.kind) {
            model.scheduleLinkScan()
        }
        .onChange(of: model.quality) {
            model.scheduleLinkScan()
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
        .overlay(alignment: .bottomTrailing) {
            Text("version 1.0.0 by W11T")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(muted)
                .padding(.trailing, 22)
                .padding(.bottom, 12)
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
                .font(.system(size: 20, weight: .semibold))
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
        .frame(width: 120)
    }

    private func linkInput(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(model.language.links, systemImage: "link")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(primary)

                Spacer()

                Text(localized(
                    en: model.parsedURLs.count == 1 ? "1 link" : "\(model.parsedURLs.count) links",
                    zh: "\(model.parsedURLs.count) 个链接",
                    zhHant: "\(model.parsedURLs.count) 個連結",
                    th: "\(model.parsedURLs.count) ลิงก์"
                ))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(muted)
            }

            PlaceholderTextEditor(text: $model.urls, placeholder: model.language.linksPlaceholder)
                .frame(height: height)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay(alignment: .top) { Rectangle().fill(separator).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(separator).frame(height: 1) }
        }
    }

    private var optionsPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(model.language.options, icon: "slider.horizontal.3")

            HStack(spacing: 10) {
                modeButton(.video)
                modeButton(.audio)
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
                            ForEach(Quality.allCases) { quality in
                                segmentButton(
                                    title: model.language.qualityLabel(quality),
                                    isSelected: model.quality == quality,
                                    hoverTarget: .quality(quality)
                                ) {
                                    model.quality = quality
                                }
                            }
                        }
                    }
                }
            } else {
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
            }

            outputDirectoryRow

            VStack(alignment: .leading, spacing: 9) {
                Toggle(model.language.metadata, isOn: $model.embedMetadata)
                Toggle(model.language.subtitles, isOn: $model.includeSubtitles)
            }
            .toggleStyle(.checkbox)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(secondary)
        }
    }

    private var progressPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(localized(en: "Status", zh: "状态", zhHant: "狀態", th: "สถานะ"), icon: "waveform.path.ecg")

            ProgressView(value: displayedProgress)
                .tint(primary)
                .progressViewStyle(.linear)

            VStack(alignment: .leading, spacing: 8) {
                statusLine(
                    localized(en: "Progress", zh: "进度", zhHant: "進度", th: "ความคืบหน้า"),
                    value: "\(Int(displayedProgress * 100))%"
                )
                statusLine(localized(en: "Speed", zh: "速度", zhHant: "速度", th: "ความเร็ว"), value: model.speedLabel)
                statusLine(localized(en: "Remaining", zh: "剩余", zhHant: "剩餘", th: "เหลือ"), value: model.etaLabel)
            }

            HStack(spacing: 10) {
                Button(action: model.startDownload) {
                    let isHovered = hoveredTarget == .download && model.canDownload
                    Label(model.language.download, systemImage: "arrow.down")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(downloadButtonBackground(isHovered: isHovered), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .foregroundStyle(model.canDownload ? Color.black.opacity(0.90) : Color.white.opacity(0.52))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .stroke(Color.white.opacity(isHovered ? 0.22 : 0))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!model.canDownload)
                .contentShape(Rectangle())
                .onHover { setHover(.download, $0 && model.canDownload) }

                Button(action: model.cancelDownload) {
                    let isHovered = hoveredTarget == .cancel && model.isRunning
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .frame(width: 36, height: 36)
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
        }
    }

    private var linkStatusBadge: some View {
        return HStack(spacing: 6) {
            Image(systemName: linkStatusIcon)
            Text(linkStatusText)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(linkStatusColor)
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(Color.white.opacity(0.06), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.09)))
    }

    private var linkStatusIcon: String {
        switch model.linkScanState {
        case .empty:
            return "link"
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
        case .checking:
            return model.language.checkingLinks
        case let .ready(totalBytes, count):
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
        case .empty:
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text(model.language.choose)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 9)
            .background(Color.white.opacity(isHovered ? 0.055 : 0), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(alignment: .top) { Rectangle().fill(separator).frame(height: 1) }
            .overlay(alignment: .bottom) { Rectangle().fill(separator).frame(height: 1) }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { setHover(.outputDirectory, $0) }
    }

    private func downloadButtonBackground(isHovered: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(model.canDownload ? (isHovered ? 1.00 : 0.96) : 0.13),
                Color.white.opacity(model.canDownload ? (isHovered ? 0.82 : 0.72) : 0.08)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var displayedProgress: Double {
        if model.isRunning {
            return max(model.progressFraction, 0.03)
        }

        if model.completedJobCount > 0 {
            return 1
        }

        return 0
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
                Image(systemName: kind == .video ? "play.rectangle" : "waveform")
                    .font(.system(size: 12, weight: .semibold))
                Text(model.language.kindLabel(kind))
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(selected || isHovered ? primary : secondary)
            .padding(.horizontal, 12)
            .frame(height: 32)
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
        .font(.system(size: 12, weight: .medium))
    }

    private func pickerRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(secondary)
            Spacer()
            content()
        }
    }

    private func optionRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                pickerLabel(title)
                    .frame(width: 70, alignment: .leading)
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
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white.opacity(0.96) : (isHovered ? primary : secondary))
                .lineLimit(1)
                .frame(minWidth: 54)
                .frame(height: 24)
                .padding(.horizontal, 4)
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
            .font(.system(size: 12, weight: .semibold))
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
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(.system(size: 14, weight: .bold))
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

@main
struct DownlinkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appSettings) {}
        }
    }
}
