//
//  CaptureSettings.swift
//  ImagePicker
//
//  Created by Peter Stajger on 25/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

///
/// Configure capture session using this struct.
///
public struct CaptureSettings {
    ///
    /// Return true if captured assets will be saved to photo library. Image picker
    /// will prompt user with request for permisssions when needed.
    ///
    public var savesCapturedAssetToPhotoLibrary: Bool
    
    /// Default configuration
    public static var `default`: CaptureSettings {
        return CaptureSettings(
            savesCapturedAssetToPhotoLibrary: true
        )
    }
}
