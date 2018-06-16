//
//  UIInterfaceOrientation+Video.swift
//  ImagePicker
//
//  Created by Anna Shirokova on 16/06/2018.
//  Copyright © 2018 Inloop. All rights reserved.
//

import AVFoundation

extension UIInterfaceOrientation {
    var captureVideoOrientation: AVCaptureVideoOrientation {
        switch self {
        case .portrait, .unknown: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeRight: return .landscapeRight
        case .landscapeLeft: return .landscapeLeft
        }
    }
}
