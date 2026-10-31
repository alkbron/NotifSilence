import AppKit
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let defaults = UserDefaults.standard
    private let savedVolumeKey = "previousAlertVolume"
    private var refreshTimer: Timer?

    private var isSilent = false {
        didSet { updateIcon() }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        updateIcon()
        refreshState()

        // Garde l'icône juste si le réglage est changé ailleurs (Réglages Système…).
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            MainActor.assumeIsolated { [weak self] in self?.refreshState() }
        }
    }

    // MARK: - État

    private func refreshState() {
        guard let volume = AlertVolume.get() else { return }
        let silent = volume == 0
        if silent != isSilent { isSilent = silent }
        if !silent { defaults.set(volume, forKey: savedVolumeKey) }
    }

    private func toggle() {
        refreshState()
        if isSilent {
            let saved = defaults.integer(forKey: savedVolumeKey)
            AlertVolume.set(saved > 0 ? saved : 100)
        } else {
            if let current = AlertVolume.get(), current > 0 {
                defaults.set(current, forKey: savedVolumeKey)
            }
            AlertVolume.set(0)
        }
        refreshState()
    }

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let symbol = isSilent ? "bell.slash.fill" : "bell"
        let label = isSilent ? "Notifications silencieuses" : "Notifications sonores"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        image?.isTemplate = true
        button.image = image
        button.toolTip = label + " — clic droit pour les options"
    }

    // MARK: - Clics

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let wantsMenu = event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true
        if wantsMenu {
            showMenu(from: sender)
        } else {
            toggle()
        }
    }

    private func showMenu(from button: NSStatusBarButton) {
        refreshState()
        let menu = NSMenu()

        let silentItem = NSMenuItem(title: "Mode silencieux", action: #selector(menuToggle), keyEquivalent: "")
        silentItem.target = self
        silentItem.state = isSilent ? .on : .off
        menu.addItem(silentItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Ouvrir au démarrage", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        let quitItem = NSMenuItem(title: "Quitter", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    @objc private func menuToggle() { toggle() }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Impossible de modifier l'ouverture au démarrage"
            alert.informativeText = error.localizedDescription
                + "\n\nAstuce : place l'app dans le dossier Applications."
            alert.runModal()
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
