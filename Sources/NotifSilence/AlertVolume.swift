import Foundation

/// Lit et écrit le « Volume des alertes » de macOS (Réglages Système → Son).
/// C'est un pourcentage (0–100) du volume de sortie, appliqué aux sons de
/// notifications et aux bips système. Le volume de sortie n'est pas touché.
@MainActor
enum AlertVolume {
    static func get() -> Int? {
        guard let result = run("alert volume of (get volume settings)"),
              result.descriptorType != typeNull else { return nil }
        return Int(result.int32Value)
    }

    static func set(_ value: Int) {
        let clamped = min(max(value, 0), 100)
        _ = run("set volume alert volume \(clamped)")
    }

    private static func run(_ source: String) -> NSAppleEventDescriptor? {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error { NSLog("NotifSilence AppleScript error: \(error)") }
        return result
    }
}
