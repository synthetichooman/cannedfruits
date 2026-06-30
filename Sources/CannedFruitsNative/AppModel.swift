import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class AppModel: ObservableObject {
    @Published var projectURL: URL?
    @Published var previewURL: URL?
    @Published var config: SiteConfig?
    @Published var statusText = "준비 중"
    @Published var sellerSummary = "셀러 미확인"
    @Published var exportPath = "아직 내보낸 폴더가 없습니다."
    @Published var logoStatus = "로고 미설정"
    @Published var errorMessage: String?

    private var server: LocalPreviewServer?
    private let fruitsClient = FruitsClient()
    private var didBoot = false

    init(autoBoot: Bool = false) {
        if autoBoot {
            Task { await boot() }
        }
    }

    var projectsHome: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CannedFruits Projects", isDirectory: true)
    }

    var stateURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CannedFruitsNative", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        return support.appendingPathComponent("state.json")
    }

    func boot() async {
        guard !didBoot else { return }
        didBoot = true

        do {
            let project = try ensureProject()
            try await useProject(project)
        } catch {
            errorMessage = error.localizedDescription
            statusText = "초기화 실패"
        }
    }

    func requestNewProject() {
        let panel = NSSavePanel()
        panel.title = "새 프로젝트 만들기"
        panel.nameFieldStringValue = "cannedfruits-shop"
        panel.directoryURL = projectsHome
        panel.canCreateDirectories = true
        panel.prompt = "생성"
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                do {
                    try copyTemplate(to: url, overwrite: FileManager.default.fileExists(atPath: url.path))
                    try await useProject(url)
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func requestOpenProject() {
        let panel = NSOpenPanel()
        panel.title = "기존 프로젝트 열기"
        panel.directoryURL = projectsHome
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "열기"
        if panel.runModal() == .OK, let url = panel.url {
            Task {
                do {
                    try validateProject(url)
                    try await useProject(url)
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func resolveSeller(url: String) async {
        do {
            let seller = try await fruitsClient.resolveSeller(from: url)
            sellerSummary = "\(seller.nickname) / \(seller.productCount) products"
            if var next = config {
                next.site.name = seller.nickname
                next.seller.id = seller.id
                next.seller.base36Id = seller.base36Id
                next.seller.username = seller.username
                next.seller.canonicalUrl = seller.canonicalUrl
                next.seller.sourceUrl = seller.sourceUrl
                try save(config: next)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveBasic(siteName: String, sellerURL: String, description: String, domain: String) {
        guard var next = config else { return }
        next.site.name = siteName
        next.site.description = description
        next.site.domain = domain
        next.seller.sourceUrl = sellerURL
        do {
            try save(config: next)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveDesign(referenceURL: String, notes: String, accent: String, background: String, text: String) {
        guard var next = config else { return }
        next.design.referenceUrl = referenceURL
        next.design.notes = notes
        next.theme.accent = accent
        next.theme.background = background
        next.theme.text = text
        do {
            try save(config: next)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func chooseLogoFile() {
        let panel = NSOpenPanel()
        panel.title = "웹사이트 로고 선택"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            .png,
            .jpeg,
            .tiff,
            .gif,
            .pdf,
            UTType(filenameExtension: "webp") ?? .image,
            UTType(filenameExtension: "icns") ?? .image,
        ]
        panel.prompt = "로고 선택"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try installLogo(from: url)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func exportProject() {
        guard let projectURL else { return }
        let panel = NSSavePanel()
        panel.title = "완성된 프로젝트 폴더 내보내기"
        panel.nameFieldStringValue = "cannedfruits-shop"
        panel.canCreateDirectories = true
        panel.prompt = "내보내기"
        if panel.runModal() == .OK, let url = panel.url {
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                try FileManager.default.copyItem(at: projectURL, to: url)
                try validateProject(url)
                exportPath = url.path
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func openCurrentProjectInFinder() {
        guard let projectURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([projectURL])
    }

    func copyLLMHarness() {
        copyToClipboard(llmHarnessText())
    }

    func llmHarnessText() -> String {
        guard let projectURL else { return "프로젝트 폴더를 아직 불러오지 못했습니다." }
        let promptURL = projectURL.appendingPathComponent("harness/LLM_PROMPT.md")
        return (try? String(contentsOf: promptURL)) ?? "하네스 파일을 읽지 못했습니다: \(promptURL.path)"
    }

    func copyToClipboard(_ body: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(body, forType: .string)
    }

    private func ensureProject() throws -> URL {
        try FileManager.default.createDirectory(at: projectsHome, withIntermediateDirectories: true)
        if
            let state = try? Data(contentsOf: stateURL),
            let object = try? JSONSerialization.jsonObject(with: state) as? [String: Any],
            let path = object["currentProject"] as? String
        {
            let saved = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: saved.path) {
                try validateProject(saved)
                return saved
            }
        }
        let defaultProject = projectsHome.appendingPathComponent("hooman-shop", isDirectory: true)
        if !FileManager.default.fileExists(atPath: defaultProject.path) {
            try copyTemplate(to: defaultProject, overwrite: false)
        }
        return defaultProject
    }

    private func useProject(_ url: URL) async throws {
        try validateProject(url)
        projectURL = url
        let loadedConfig = try loadConfig(from: url)
        config = loadedConfig
        logoStatus = loadedConfig.design.logo?.symbol ?? "로고 미설정"
        try saveState(project: url)
        server?.stop()
        let nextServer = LocalPreviewServer(projectURL: url)
        server = nextServer
        previewURL = try await nextServer.start()
        statusText = "작업 폴더 실행 중"
    }

    private func copyTemplate(to url: URL, overwrite: Bool) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            if overwrite {
                try FileManager.default.removeItem(at: url)
            } else {
                return
            }
        }
        try FileManager.default.copyItem(at: templateURL(), to: url)
        try validateProject(url)
    }

    private func templateURL() throws -> URL {
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let candidates: [URL?] = [
            Bundle.main.resourceURL?.appendingPathComponent("app-engine-template", isDirectory: true),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/app-engine-template", isDirectory: true),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Resources/app-engine-template", isDirectory: true),
            sourceRoot.appendingPathComponent("Resources/app-engine-template", isDirectory: true),
        ]

        for candidate in candidates.compactMap({ $0 }) {
            if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("site.config.json").path) {
                return candidate
            }
        }

        throw AppError.message("앱 템플릿을 찾지 못했습니다. Resources/app-engine-template 폴더를 확인해주세요.")
    }

    private func validateProject(_ url: URL) throws {
        let required = [
            "README.md",
            "site.config.json",
            "public/index.html",
            "functions/_config.js",
            "harness/LLM_PROMPT.md"
        ]
        for item in required {
            if !FileManager.default.fileExists(atPath: url.appendingPathComponent(item).path) {
                throw AppError.message("cannedfruits 프로젝트 폴더가 아닙니다. 누락: \(item)")
            }
        }
    }

    private func loadConfig(from url: URL) throws -> SiteConfig {
        let data = try Data(contentsOf: url.appendingPathComponent("site.config.json"))
        return try JSONDecoder().decode(SiteConfig.self, from: data)
    }

    private func save(config next: SiteConfig) throws {
        guard let projectURL else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(next)
        try data.write(to: projectURL.appendingPathComponent("site.config.json"))
        try configModuleSource(next).write(to: projectURL.appendingPathComponent("functions/_config.js"), atomically: true, encoding: .utf8)
        config = next
    }

    private func installLogo(from sourceURL: URL) throws {
        guard let projectURL else { return }
        guard var next = config else { return }
        guard let image = NSImage(contentsOf: sourceURL), image.isValid else {
            throw AppError.message("이미지 파일을 읽지 못했습니다. PNG, JPG, PDF, ICNS 파일을 선택해주세요.")
        }

        let contentURL = projectURL.appendingPathComponent("content", isDirectory: true)
        let publicURL = projectURL.appendingPathComponent("public", isDirectory: true)
        let assetsURL = publicURL.appendingPathComponent("assets", isDirectory: true)
        try FileManager.default.createDirectory(at: contentURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: assetsURL, withIntermediateDirectories: true)

        let originalExtension = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension.lowercased()
        let originalURL = contentURL.appendingPathComponent("logo-source.\(originalExtension)")
        let symbolURL = assetsURL.appendingPathComponent("logo-symbol.png")
        let faviconURL = publicURL.appendingPathComponent("favicon.png")

        if FileManager.default.fileExists(atPath: originalURL.path) {
            try FileManager.default.removeItem(at: originalURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: originalURL)
        try writePNG(from: image, to: symbolURL, size: 512)
        try writePNG(from: image, to: faviconURL, size: 512)

        next.design.logo = SiteConfig.Logo(
            source: "content/logo-source.\(originalExtension)",
            symbol: "/assets/logo-symbol.png",
            favicon: "/favicon.png"
        )
        try save(config: next)
        logoStatus = "로고 저장 완료: public/assets/logo-symbol.png, public/favicon.png"
    }

    private func writePNG(from image: NSImage, to url: URL, size: CGFloat) throws {
        let canvasSize = NSSize(width: size, height: size)
        let output = NSImage(size: canvasSize)
        output.lockFocus()
        NSColor.clear.setFill()
        NSRect(origin: .zero, size: canvasSize).fill()

        let sourceSize = image.size
        guard sourceSize.width > 0, sourceSize.height > 0 else {
            output.unlockFocus()
            throw AppError.message("로고 이미지의 크기를 확인하지 못했습니다.")
        }

        let scale = min(size / sourceSize.width, size / sourceSize.height)
        let drawSize = NSSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let drawRect = NSRect(
            x: (size - drawSize.width) / 2,
            y: (size - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        image.draw(in: drawRect, from: NSRect(origin: .zero, size: sourceSize), operation: .sourceOver, fraction: 1)
        output.unlockFocus()

        guard
            let tiff = output.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let data = bitmap.representation(using: .png, properties: [:])
        else {
            throw AppError.message("로고 PNG 파일을 생성하지 못했습니다.")
        }

        try data.write(to: url)
    }

    private func saveState(project: URL) throws {
        let body = try JSONSerialization.data(withJSONObject: ["currentProject": project.path], options: [.prettyPrinted])
        try body.write(to: stateURL)
    }

    private func configModuleSource(_ config: SiteConfig) throws -> String {
        let object = try config.jsonObject()
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        let json = String(data: data, encoding: .utf8) ?? "{}"
        return """
        export const SITE_CONFIG = \(json);

        export function getSiteConfig(env = {}) {
          const runtimeConfig = globalThis.__CANNED_FRUITS_SITE_CONFIG__ || SITE_CONFIG;
          const domain = env.SITE_DOMAIN || runtimeConfig.site.domain;
          return {
            ...runtimeConfig,
            site: {
              ...runtimeConfig.site,
              domain,
            },
          };
        }
        """
    }
}
