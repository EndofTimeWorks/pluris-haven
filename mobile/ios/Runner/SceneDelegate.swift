import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var privacyOverlay: UIView?

  override init() {
    super.init()
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: UIScreen.main
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureProtectionChanged),
      name: .plurisHavenScreenCaptureProtectionChanged,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    showPrivacyOverlay()
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    if UIScreen.main.isCaptured {
      showPrivacyOverlay()
    } else {
      privacyOverlay?.isHidden = true
    }
  }

  @objc private func screenCaptureChanged() {
    if UIScreen.main.isCaptured {
      showPrivacyOverlay()
    } else if let window, window.isKeyWindow {
      privacyOverlay?.isHidden = true
    }
  }

  @objc private func screenCaptureProtectionChanged(_ notification: Notification) {
    let enabled = notification.userInfo?["enabled"] as? Bool ?? true
    if enabled && UIScreen.main.isCaptured {
      showPrivacyOverlay()
    } else {
      privacyOverlay?.isHidden = true
    }
  }

  private func showPrivacyOverlay() {
    guard UserDefaults.standard.object(
      forKey: "pluris_haven_screen_capture_protection"
    ) as? Bool ?? true, let window else { return }
    let overlay = privacyOverlay ?? {
      let view = UIView(frame: window.bounds)
      view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      view.backgroundColor = .systemBackground
      view.isAccessibilityElement = false
      window.addSubview(view)
      privacyOverlay = view
      return view
    }()
    overlay.frame = window.bounds
    overlay.isHidden = false
    window.bringSubviewToFront(overlay)
  }
}
