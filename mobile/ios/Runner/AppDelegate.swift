import Flutter
import UIKit
import UniformTypeIdentifiers
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var fileDialogHandler: NativeFileDialogHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    WorkmanagerPlugin.registerBGProcessingTask(
      withIdentifier: "works.endoftime.plurishaven.import_archive"
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "works.endoftime.plurishaven/file_dialog",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    let handler = NativeFileDialogHandler(presenter: { [weak self] in
      self?.topViewController()
    })
    channel.setMethodCallHandler(handler.handle)
    fileDialogHandler = handler
  }

  private func topViewController() -> UIViewController? {
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }
}

private final class NativeFileDialogHandler: NSObject, UIDocumentPickerDelegate {
  private enum Operation {
    case opening
    case exporting
  }

  private let presenter: () -> UIViewController?
  private var pendingResult: FlutterResult?
  private var operation: Operation?

  init(presenter: @escaping () -> UIViewController?) {
    self.presenter = presenter
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "picker_busy", message: "A file dialog is already open.", details: nil))
      return
    }
    guard let presenter = presenter() else {
      result(FlutterError(code: "no_presenter", message: "No active window can present the file dialog.", details: nil))
      return
    }
    let arguments = call.arguments as? [String: Any]
    switch call.method {
    case "pickFiles":
      let type = arguments?["type"] as? String
      let extensions = arguments?["allowedExtensions"] as? [String] ?? []
      let contentTypes: [UTType]
      if type == "image" {
        contentTypes = [.image]
      } else {
        let resolved = extensions.compactMap { UTType(filenameExtension: $0) }
        contentTypes = resolved.isEmpty ? [.data] : resolved
      }
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
      picker.allowsMultipleSelection = arguments?["allowMultiple"] as? Bool ?? false
      picker.delegate = self
      pendingResult = result
      operation = .opening
      presenter.present(picker, animated: true)
    case "saveFile":
      guard
        let sourcePath = arguments?["sourcePath"] as? String,
        FileManager.default.fileExists(atPath: sourcePath)
      else {
        result(FlutterError(code: "invalid_save", message: "Missing export source.", details: nil))
        return
      }
      let picker = UIDocumentPickerViewController(
        forExporting: [URL(fileURLWithPath: sourcePath)],
        asCopy: true
      )
      picker.delegate = self
      pendingResult = result
      operation = .exporting
      presenter.present(picker, animated: true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    let result = pendingResult
    let currentOperation = operation
    pendingResult = nil
    operation = nil
    guard currentOperation == .opening else {
      result?(true)
      return
    }
    do {
      let files = try urls.map(copySelectionToTemporaryDirectory)
      result?(files)
    } catch {
      result?(FlutterError(code: "pick_failed", message: error.localizedDescription, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = pendingResult
    let currentOperation = operation
    pendingResult = nil
    operation = nil
    result?(currentOperation == .exporting ? false : nil)
  }

  private func copySelectionToTemporaryDirectory(_ source: URL) throws -> [String: Any] {
    let accessed = source.startAccessingSecurityScopedResource()
    defer {
      if accessed { source.stopAccessingSecurityScopedResource() }
    }
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("pluris-haven-picked-files", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let destination = directory.appendingPathComponent(
      "\(UUID().uuidString)-\(source.lastPathComponent)"
    )
    try FileManager.default.copyItem(at: source, to: destination)
    let values = try destination.resourceValues(forKeys: [.fileSizeKey])
    return [
      "name": source.lastPathComponent,
      "path": destination.path,
      "size": values.fileSize ?? 0,
    ]
  }
}
