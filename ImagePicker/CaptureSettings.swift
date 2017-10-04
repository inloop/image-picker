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
    
    public enum CameraMode {
        ///
        /// If you support only photos use this preset. Default value.
        ///
        case photo
        ///
        /// If you know you will use live photos use this preset.
        ///
        case photoAndLivePhoto
        
        /// If you wish to record videos or take photos.
        case photoAndVideo
    }
    
    ///
    /// Capture session uses this preset when configuring. Select a preset of
    /// media types you wish to support.
    ///
    /// - note: currently you can not change preset at runtime
    ///
    public var cameraMode: CameraMode
    
    ///
    /// Return true if captured assets will be saved to photo library. Image picker
    /// will prompt user with request for permisssions when needed. Default value is false.
    ///
    public var savesCapturedAssetToPhotoLibrary: Bool
    
    /// Default configuration
    public static var `default`: CaptureSettings {
        return CaptureSettings(
            cameraMode: .photo,
            savesCapturedAssetToPhotoLibrary: false
        )
    }
}

extension CaptureSettings.CameraMode {
    
    /// transforms user related enum to specific internal capture session enum
    var captureSessionPresetConfiguration: CaptureSession.SessionPresetConfiguration {
        switch self {
        case .photo: return .photos
        case .photoAndLivePhoto: return .livePhotos
        case .photoAndVideo: return .videos
        }
    }
    
}
