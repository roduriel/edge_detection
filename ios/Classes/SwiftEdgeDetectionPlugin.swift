import Flutter
import UIKit
import WeScan

public class SwiftEdgeDetectionPlugin: NSObject, FlutterPlugin, UIApplicationDelegate {

    private static var keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        }
        return UIApplication.shared.delegate?.window ?? nil
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

        if (call.method == "edge_detect") {
            let window = UIApplication.shared.delegate?.window ?? Self.keyWindow
            guard let viewController = (window ?? Self.keyWindow)?.rootViewController as? FlutterViewController else {
                result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No root view controller available.", details: nil))
                return
            }
            let destinationViewController = HomeViewController()
            destinationViewController.setParams(saveTo: saveTo, canUseGallery: canUseGallery)
            destinationViewController._result = result
            viewController.present(destinationViewController, animated: true, completion: nil)
        }
        if (call.method == "edge_detect_gallery") {
            let window = UIApplication.shared.delegate?.window ?? Self.keyWindow
            guard let viewController = (window ?? Self.keyWindow)?.rootViewController as? FlutterViewController else {
                result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No root view controller available.", details: nil))
                return
            }
            let destinationViewController = HomeViewController()
            destinationViewController.setParams(saveTo: saveTo, canUseGallery: canUseGallery)
            destinationViewController._result = result
            destinationViewController.selectPhoto()
        }
    }
}