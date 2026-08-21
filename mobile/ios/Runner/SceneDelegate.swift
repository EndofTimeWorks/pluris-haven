import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var privacyOverlay: UIView?

  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    guard let window else { return }

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

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    privacyOverlay?.isHidden = true
  }
}
