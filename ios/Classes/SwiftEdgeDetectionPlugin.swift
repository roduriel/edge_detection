import Flutter
import UIKit
import WeScan

public class SwiftEdgeDetectionPlugin: NSObject, FlutterPlugin, UIApplicationDelegate {

    /// Collect all windows (AppDelegate + all scene windows + legacy .windows).
    private static func allWindows() -> [UIWindow] {
        var list: [UIWindow] = []
        if let delegate = UIApplication.shared.delegate,
           let windowOptional = delegate.window,
           let window = windowOptional {
            list.append(window)
        }
        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                guard let ws = scene as? UIWindowScene else { continue }
                list.append(contentsOf: ws.windows)
            }
        }
        if list.isEmpty {
            list = UIApplication.shared.windows
        }
        return list
    }

    /// Recursively find FlutterViewController in the view controller tree (root, presented, children).
    private static func findFlutterViewController(from vc: UIViewController?) -> FlutterViewController? {
        guard let vc = vc else { return nil }
        if let fvc = vc as? FlutterViewController { return fvc }
        if let presented = vc.presentedViewController, let f = findFlutterViewController(from: presented) { return f }
        for child in vc.children {
            if let f = findFlutterViewController(from: child) { return f }
        }
        if let nav = vc as? UINavigationController, let f = findFlutterViewController(from: nav.visibleViewController) { return f }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController, let f = findFlutterViewController(from: selected) { return f }
        return nil
    }

    /// Key window for adding subviews (e.g. gallery button). Prefer one that has Flutter in hierarchy.
    static var keyWindow: UIWindow? {
        let windows = allWindows()
        for w in windows {
            if w.isKeyWindow, findFlutterViewController(from: w.rootViewController) != nil { return w }
        }
        for w in windows {
            if findFlutterViewController(from: w.rootViewController) != nil { return w }
        }
        for w in windows {
            if w.rootViewController != nil { return w }
        }
        return windows.first
    }

    /// Root view controller to present from: Flutter VC or topmost presented from it.
    private static func rootViewControllerForPresentation() -> UIViewController? {
        for w in allWindows() {
            guard let root = w.rootViewController else { continue }
            if let fvc = findFlutterViewController(from: root) {
                return topViewController(from: fvc)
            }
            let top = topViewController(from: root)
            if findFlutterViewController(from: top) != nil { return top }
        }
        for w in allWindows() {
            guard let root = w.rootViewController else { continue }
            return topViewController(from: root)
        }
        return nil
    }

    /// Topmost view controller so we can present the scanner on the visible screen.
    private static func topViewController(from root: UIViewController) -> UIViewController {
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "edge_detection", binaryMessenger: registrar.messenger())
        let instance = SwiftEdgeDetectionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! Dictionary<String, Any>
        let saveTo = args["save_to"] as! String
        let canUseGallery = args["can_use_gallery"] as? Bool ?? false

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let topVC = SwiftEdgeDetectionPlugin.rootViewControllerForPresentation() else {
                result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No root view controller available.", details: nil))
                return
            }

            if (call.method == "edge_detect") {
                let destinationViewController = HomeViewController()
                destinationViewController.setParams(saveTo: saveTo, canUseGallery: canUseGallery)
                destinationViewController._result = result
                topVC.present(destinationViewController, animated: true, completion: nil)
            }
            if (call.method == "edge_detect_gallery") {
                let destinationViewController = HomeViewController()
                destinationViewController.setParams(saveTo: saveTo, canUseGallery: canUseGallery)
                destinationViewController._result = result
                destinationViewController.selectPhoto()
            }
        }
    }
}