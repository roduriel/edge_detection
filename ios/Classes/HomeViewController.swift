import WeScan
import Flutter
import Foundation

class HomeViewController: UIViewController, ImageScannerControllerDelegate {

    var cameraController: ImageScannerController!
    var _result:FlutterResult?
    
    var saveTo: String = ""
    var canUseGallery: Bool = true
    
    /// Timer to hide gallery button only when WeScan is on Review screen (avoids overlap with Done/back).
    private var galleryVisibilityTimer: Timer?
    
    override func viewDidAppear(_ animated: Bool) {
        if self.isBeingPresented {
            cameraController = ImageScannerController()
            cameraController.imageScannerDelegate = self

            if #available(iOS 13.0, *) {
                cameraController.isModalInPresentation = true
                cameraController.overrideUserInterfaceStyle = .dark
                cameraController.view.backgroundColor = .black
            }
            
            // Temp fix for https://github.com/WeTransfer/WeScan/issues/320
            if #available(iOS 15, *) {
                let appearance = UINavigationBarAppearance()
                let navigationBar = UINavigationBar()
                appearance.configureWithOpaqueBackground()
                appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.label]
                appearance.backgroundColor = .systemBackground
                navigationBar.standardAppearance = appearance;
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
                
                let appearanceTB = UITabBarAppearance()
                appearanceTB.configureWithOpaqueBackground()
                appearanceTB.backgroundColor = .systemBackground
                UITabBar.appearance().standardAppearance = appearanceTB
                UITabBar.appearance().scrollEdgeAppearance = appearanceTB
            }
            
            present(cameraController, animated: true) {
                if let window = SwiftEdgeDetectionPlugin.keyWindow {
                    window.addSubview(self.selectPhotoButton)
                    self.setupConstraints(for: window)
                    self.startGalleryVisibilityUpdates()
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        galleryVisibilityTimer?.invalidate()
        galleryVisibilityTimer = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if (canUseGallery == true) {
            selectPhotoButton.isHidden = false
        }
    }
    
    /// Hide gallery button only on Review screen; show on Scan and Edit.
    private func startGalleryVisibilityUpdates() {
        galleryVisibilityTimer?.invalidate()
        galleryVisibilityTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateGalleryButtonVisibility()
        }
        RunLoop.main.add(galleryVisibilityTimer!, forMode: .common)
    }
    
    private func updateGalleryButtonVisibility() {
        guard canUseGallery else {
            selectPhotoButton.isHidden = true
            return
        }
        let isOnReviewScreen: Bool
        if let nav = cameraController as? UINavigationController, let top = nav.topViewController {
            let name = String(describing: type(of: top))
            isOnReviewScreen = name.contains("ReviewViewController")
        } else {
            isOnReviewScreen = false
        }
        selectPhotoButton.isHidden = isOnReviewScreen
    }
    
    lazy var selectPhotoButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "gallery", in: Bundle(for: SwiftEdgeDetectionPlugin.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.white
        button.addTarget(self, action: #selector(selectPhoto), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
        
    @objc private func cancelImageScannerController() {
        hideButtons()
        
        _result!(false)
        cameraController?.dismiss(animated: true)
        dismiss(animated: true)
    }
    
    @objc func selectPhoto() {
        if let window = SwiftEdgeDetectionPlugin.keyWindow, let root = window.rootViewController {
            root.dismiss(animated: true, completion: nil)
            self.hideButtons()
            
            let scanPhotoVC = ScanPhotoViewController()
            scanPhotoVC._result = _result
            scanPhotoVC.saveTo = self.saveTo
            if #available(iOS 13.0, *) {
                scanPhotoVC.isModalInPresentation = true
                scanPhotoVC.overrideUserInterfaceStyle = .dark
            }
            root.present(scanPhotoVC, animated: true)
        }
    }
    
    func hideButtons() {
        galleryVisibilityTimer?.invalidate()
        galleryVisibilityTimer = nil
        selectPhotoButton.isHidden = true
    }
    
    /// Gallery button: bottom-right (hidden in Review by timer). Scan/Edit: no toolbar on right at bottom.
    private func setupConstraints(for window: UIWindow) {
        var constraints = [
            selectPhotoButton.widthAnchor.constraint(equalToConstant: 44.0),
            selectPhotoButton.heightAnchor.constraint(equalToConstant: 44.0),
        ]
        if #available(iOS 11.0, *) {
            constraints += [
                selectPhotoButton.rightAnchor.constraint(equalTo: window.safeAreaLayoutGuide.rightAnchor, constant: -24.0),
                window.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: selectPhotoButton.bottomAnchor, constant: (65.0 / 2) - 10.0),
            ]
        } else {
            constraints += [
                selectPhotoButton.rightAnchor.constraint(equalTo: window.rightAnchor, constant: -24.0),
                window.bottomAnchor.constraint(equalTo: selectPhotoButton.bottomAnchor, constant: (65.0 / 2) - 10.0),
            ]
        }
        NSLayoutConstraint.activate(constraints)
    }
    
    func setParams(saveTo: String, canUseGallery: Bool) {
        self.saveTo = saveTo
        self.canUseGallery = canUseGallery
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFailWithError error: Error) {
        print(error)
        _result!(false)
        self.hideButtons()
        self.dismiss(animated: true)
    }
    
    func imageScannerController(_ scanner: ImageScannerController, didFinishScanningWithResults results: ImageScannerResults) {
        // Your ViewController is responsible for dismissing the ImageScannerController
        scanner.dismiss(animated: true)
        self.hideButtons()
        
        saveImage(image:results.doesUserPreferEnhancedScan ? results.enhancedScan!.image : results.croppedScan.image)
        _result!(true)
        self.dismiss(animated: true)
    }
    
    func imageScannerControllerDidCancel(_ scanner: ImageScannerController) {
        // Your ViewController is responsible for dismissing the ImageScannerController
        scanner.dismiss(animated: true)
        self.hideButtons()
        
        _result!(false)
        self.dismiss(animated: true)
    }
    
    func saveImage(image: UIImage) -> Bool? {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
            return false
        }
        let pathString = self.saveTo.trimmingCharacters(in: .whitespacesAndNewlines)
        let filePath = URL(fileURLWithPath: pathString)
        let dirPath = filePath.deletingLastPathComponent().path
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: dirPath) {
            try? fileManager.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        }
        do {
            if fileManager.fileExists(atPath: pathString) {
                try fileManager.removeItem(atPath: pathString)
            }
        } catch {
            print("saveImage removeItem error: \(error)")
        }
        do {
            try data.write(to: filePath)
            return true
        } catch {
            print("saveImage write error: \(error.localizedDescription)")
            return false
        }
    }
}

