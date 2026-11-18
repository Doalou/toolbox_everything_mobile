import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var shareChannel: FlutterMethodChannel?
  private var pendingSharedPayload: [String: Any?]?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let launchUrl = launchOptions?[.url] as? URL {
      pendingSharedPayload = extractPayload(from: launchUrl)
    }

    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    ensureShareChannel()
    return launched
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if let payload = extractPayload(from: url) {
      if let channel = ensureShareChannel() {
        channel.invokeMethod("onNewShare", arguments: payload)
      } else {
        pendingSharedPayload = payload
      }
      return true
    }
    return super.application(app, open: url, options: options)
  }

  @discardableResult
  private func ensureShareChannel() -> FlutterMethodChannel? {
    if let channel = shareChannel {
      return channel
    }
    guard let controller = resolveFlutterViewController() else {
      return nil
    }
    let channel = FlutterMethodChannel(
      name: "com.toolbox.everything.mobile/share",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "consumeInitialShare" {
        result(self?.pendingSharedPayload)
        self?.pendingSharedPayload = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    shareChannel = channel
    return channel
  }

  private func resolveFlutterViewController() -> FlutterViewController? {
    if let controller = window?.rootViewController as? FlutterViewController {
      return controller
    }
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      for sceneWindow in windowScene.windows {
        if let controller = sceneWindow.rootViewController as? FlutterViewController {
          return controller
        }
      }
    }
    return nil
  }

  private func extractPayload(from url: URL) -> [String: Any?]? {
    if url.scheme?.lowercased() == "toolbox" {
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      let items = components?.queryItems ?? []
      let queryUrl = items.first(where: { $0.name == "url" })?.value
      let queryText = items.first(where: { $0.name == "text" })?.value
      let resolvedText = queryUrl ?? queryText ?? url.absoluteString
      return [
        "type": "text",
        "text": resolvedText,
        "target": url.host ?? "",
      ]
    }

    if url.isFileURL {
      let accessed = url.startAccessingSecurityScopedResource()
      defer {
        if accessed {
          url.stopAccessingSecurityScopedResource()
        }
      }
      do {
        let importDir = FileManager.default.temporaryDirectory.appendingPathComponent(
          "shared_imports",
          isDirectory: true
        )
        try FileManager.default.createDirectory(at: importDir, withIntermediateDirectories: true)
        let cutoff = Date().addingTimeInterval(-86400)
        if let contents = try? FileManager.default.contentsOfDirectory(
          at: importDir,
          includingPropertiesForKeys: [.contentModificationDateKey],
          options: .skipsHiddenFiles
        ) {
          for item in contents {
            let values = try? item.resourceValues(forKeys: [.contentModificationDateKey])
            if let modified = values?.contentModificationDate, modified < cutoff {
              try? FileManager.default.removeItem(at: item)
            }
          }
        }
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let fileName = url.lastPathComponent.isEmpty ? "shared_file" : url.lastPathComponent
        let destUrl = importDir.appendingPathComponent("\(timestamp)_\(fileName)")
        if FileManager.default.fileExists(atPath: destUrl.path) {
          try FileManager.default.removeItem(at: destUrl)
        }
        try FileManager.default.copyItem(at: url, to: destUrl)
        return [
          "type": "file",
          "filePath": destUrl.path,
          "fileName": fileName,
        ]
      } catch {
        return nil
      }
    }

    return nil
  }
}
