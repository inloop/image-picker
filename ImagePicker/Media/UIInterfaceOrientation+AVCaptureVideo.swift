// Copyright © 2018 INLOOPX. All rights reserved.

import AVFoundation
import UIKit

extension UIInterfaceOrientation {
    var captureVideoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeRight
        case .landscapeLeft: return .landscapeLeft
        default: return .portrait
        }
    }
}