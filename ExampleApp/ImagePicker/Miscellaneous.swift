//
//  Logger.swift
//  ImagePicker
//
//  Created by Peter Stajger on 19/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import AVFoundation

func log(_ message: String) {
    #if DEBUG
        debugPrint(message)
    #endif
}

extension UIInterfaceOrientation : CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .unknown: return "unknown"
        case .portrait: return "portrait"
        case .portraitUpsideDown: return "portrait upside down"
        case .landscapeRight: return "landscape right"
        case .landscapeLeft: return "landscape left"
        }
    }
    
}
