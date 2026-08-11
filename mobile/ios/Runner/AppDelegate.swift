import BackgroundTasks
import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var fileDialogHandler: NativeFileDialogHandler?
  private var backgroundEngine: FlutterEngine?
  private var backgroundChannel: FlutterMethodChannel?
  private var backgroundTaskActive = false
  private let backgroundTaskIdentifier = "works.endoftime.plurishaven.import_archive"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // A killed process cannot run Dart's per-file cleanup. Clear any
    // plaintext import staging left by an interrupted previous session.
    try? FileManager.default.removeItem(
      at: FileManager.default.temporaryDirectory
        .appendingPathComponent("pluris-haven-picked-files", isDirectory: true)
    )
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: backgroundTaskIdentifier,
      using: nil
    ) { [weak self] task in
      guard let processingTask = task as? BGProcessingTask else {
        task.setTaskCompleted(success: false)
        return
      }
      self?.runBackgroundImport(processingTask)
    }
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
    let backgroundControl = FlutterMethodChannel(
      name: "works.endoftime.plurishaven/background_tasks",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    backgroundControl.setMethodCallHandler(handleBackgroundControl)
  }

  private func topViewController() -> UIViewController? {
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }

  private func handleBackgroundControl(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    switch call.method {
    case "initialize":
      guard let handle = (arguments?["callbackHandle"] as? NSNumber)?.int64Value else {
        result(FlutterError(code: "invalid_callback", message: "Missing background callback handle.", details: nil))
        return
      }
      UserDefaults.standard.set(handle, forKey: "pluris_haven_background_callback")
      result(nil)
    case "scheduleImport":
      BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
      let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
      request.requiresNetworkConnectivity = false
      request.requiresExternalPower = false
      do {
        try BGTaskScheduler.shared.submit(request)
        result(nil)
      } catch {
        result(FlutterError(code: "schedule_failed", message: error.localizedDescription, details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func runBackgroundImport(_ task: BGProcessingTask) {
    guard
      let handle = UserDefaults.standard.object(forKey: "pluris_haven_background_callback") as? NSNumber,
      let callback = FlutterCallbackCache.lookupCallbackInformation(handle.int64Value)
    else {
      task.setTaskCompleted(success: false)
      return
    }

    let engine = FlutterEngine(
      name: "PlurisHaven.BackgroundImport",
      project: nil,
      allowHeadlessExecution: true
    )
    backgroundTaskActive = true
    backgroundEngine = engine
    guard engine.run(
      withEntrypoint: callback.callbackName,
      libraryURI: callback.callbackLibraryPath
    ) else {
      finishBackgroundTask(task, success: false)
      return
    }
    GeneratedPluginRegistrant.register(with: engine)
    let channel = FlutterMethodChannel(
      name: "works.endoftime.plurishaven/background_tasks/worker",
      binaryMessenger: engine.binaryMessenger
    )
    backgroundChannel = channel
    channel.setMethodCallHandler { [weak self] call, readyResult in
      guard call.method == "backgroundReady" else {
        readyResult(FlutterMethodNotImplemented)
        return
      }
      readyResult(nil)
      channel.invokeMethod(
        "runTask",
        arguments: [
          "task": self?.backgroundTaskIdentifier ?? "",
          "inputData": [:],
        ],
        result: { value in
          self?.finishBackgroundTask(task, success: value as? Bool == true)
        }
      )
    }
    task.expirationHandler = { [weak self] in
      self?.finishBackgroundTask(task, success: false)
    }
  }

  private func finishBackgroundTask(_ task: BGTask, success: Bool) {
    guard backgroundTaskActive else { return }
    backgroundTaskActive = false
    backgroundChannel?.setMethodCallHandler(nil)
    backgroundChannel = nil
    backgroundEngine?.destroyContext()
    backgroundEngine = nil
    task.setTaskCompleted(success: success)
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
  private var maximumBytes = 32 * 1024 * 1024

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
      maximumBytes = (arguments?["maximumBytes"] as? NSNumber)?.intValue ?? 32 * 1024 * 1024
      guard maximumBytes > 0 else {
        result(FlutterError(code: "invalid_limit", message: "File size limit must be positive.", details: nil))
        return
      }
      try? FileManager.default.removeItem(at: pickedFilesDirectory)
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: false)
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
    let directory = pickedFilesDirectory
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let destination = directory.appendingPathComponent(
      "\(UUID().uuidString)-\(source.lastPathComponent)"
    )
    let sourceValues = try source.resourceValues(forKeys: [.fileSizeKey])
    if let declaredSize = sourceValues.fileSize, declaredSize > maximumBytes {
      throw NSError(
        domain: "PlurisHavenImport",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Selected file exceeds the size limit."]
      )
    }
    guard
      let input = InputStream(url: source),
      let output = OutputStream(url: destination, append: false)
    else {
      throw NSError(
        domain: "PlurisHavenImport",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Could not open the selected file."]
      )
    }
    input.open()
    output.open()
    defer {
      input.close()
      output.close()
    }
    var buffer = [UInt8](repeating: 0, count: 64 * 1024)
    var copied = 0
    do {
      while true {
        let read = input.read(&buffer, maxLength: buffer.count)
        if read < 0 { throw input.streamError ?? CocoaError(.fileReadUnknown) }
        if read == 0 { break }
        if copied > maximumBytes - read {
          throw NSError(
            domain: "PlurisHavenImport",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Selected file exceeds the size limit."]
          )
        }
        var written = 0
        while written < read {
          let count = buffer.withUnsafeBufferPointer { pointer in
            output.write(pointer.baseAddress!.advanced(by: written), maxLength: read - written)
          }
          if count <= 0 { throw output.streamError ?? CocoaError(.fileWriteUnknown) }
          written += count
        }
        copied += read
      }
    } catch {
      try? FileManager.default.removeItem(at: destination)
      throw error
    }
    let values = try destination.resourceValues(forKeys: [.fileSizeKey])
    return [
      "name": source.lastPathComponent,
      "path": destination.path,
      "size": values.fileSize ?? 0,
    ]
  }

  private var pickedFilesDirectory: URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("pluris-haven-picked-files", isDirectory: true)
  }
}
