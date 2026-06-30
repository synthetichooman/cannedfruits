import AppKit
import SwiftUI

@main
enum CannedFruitsNativeMain {
    private static var delegate: AppDelegate?

    @MainActor
    static func main() {
        let app = NSApplication.shared
        let appDelegate = AppDelegate()
        delegate = appDelegate
        app.delegate = appDelegate
        appDelegate.start()
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel(autoBoot: true)
    private var window: NSWindow?
    private var didStart = false

    func start() {
        guard !didStart else { return }
        didStart = true
        NSApp.setActivationPolicy(.regular)
        buildMenu()
        showMainWindow()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        start()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func showMainWindow() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let content = ContentView()
            .environmentObject(model)
            .frame(minWidth: 1120, minHeight: 860)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1240, height: 940),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.minSize = NSSize(width: 1120, height: 860)
        window.title = "CannedFruits"
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.contentView = NSHostingView(rootView: content)
        window.center()
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    private func buildMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "CannedFruits")
        appMenu.addItem(NSMenuItem(title: "CannedFruits 종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let projectItem = NSMenuItem()
        let projectMenu = NSMenu(title: "프로젝트")
        projectMenu.addItem(menuItem("새 프로젝트 만들기", action: #selector(newProject), key: "N", modifiers: [.command, .shift]))
        projectMenu.addItem(menuItem("기존 프로젝트 열기", action: #selector(openProject), key: "o", modifiers: [.command]))
        projectMenu.addItem(NSMenuItem.separator())
        projectMenu.addItem(menuItem("프로젝트 폴더 열기", action: #selector(openProjectFolder), key: "R", modifiers: [.command, .shift]))
        projectItem.submenu = projectMenu
        mainMenu.addItem(projectItem)

        NSApp.mainMenu = mainMenu
    }

    private func menuItem(_ title: String, action: Selector, key: String, modifiers: NSEvent.ModifierFlags) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key.lowercased())
        item.keyEquivalentModifierMask = modifiers
        item.target = self
        return item
    }

    @objc private func newProject() {
        model.requestNewProject()
    }

    @objc private func openProject() {
        model.requestOpenProject()
    }

    @objc private func openProjectFolder() {
        model.openCurrentProjectInFinder()
    }
}
