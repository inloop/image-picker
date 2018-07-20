// Copyright © 2018 INLOOPX. All rights reserved.

import AVFoundation

/// A view whose layer is AVCaptureVideoPreviewLayer so it's used for previewing
/// output from a capture session.
final class AVPreviewView: UIView {
    enum VideoDisplayMode {
        /// Preserve aspect ratio, fit within layer bounds.
        case aspectFit
        /// Preserve aspect ratio, fill view bounds.
        case aspectFill
        ///Stretch to fill layer bounds
        case resize
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get { return previewLayer.session }
        set {
            guard previewLayer.session !== newValue else { return }
            previewLayer.session = newValue
        }
    }
    
    var displayMode: VideoDisplayMode = .aspectFill {
        didSet { applyVideoDisplayMode() }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        applyVideoDisplayMode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        applyVideoDisplayMode()
    }
    
    deinit {
        log("deinit: \(String(describing: self))")
    }
    
    private func applyVideoDisplayMode() {
        switch displayMode {
        case .aspectFill: previewLayer.videoGravity = .resizeAspectFill
        case .aspectFit: previewLayer.videoGravity = .resizeAspect
        case .resize: previewLayer.videoGravity = .resize
        }
    }
}
