// Copyright © 2018 INLOOPX. All rights reserved.

import Foundation

/// Configure capture session using this struct.

public struct CaptureSettings {
    public enum CameraMode {
        /// If you support only photos use this preset. Default value.
        case photo
        
        /// If you know you will use live photos use this preset.
        case photoAndLivePhoto
        
        /// If you wish to record videos or take photos.
        case photoAndVideo
    }
    
    /// Capture session uses this preset when configuring. Select a preset of
    /// media types you wish to support.
    ///
    /// - note: currently you can not change preset at runtime
    public var cameraMode: CameraMode
    
    /// Return true if captured photos will be saved to photo library. Image picker
    /// will prompt user with request for permisssions when needed. Default value is false
    /// for photos. Live photos and videos are always true.
    ///
    /// - note: please note, that at current implementation this applies to photos only. For
    /// live photos and videos this is always true.
    public var savesCapturedPhotosToPhotoLibrary: Bool
    
    let savesCapturedLivePhotosToPhotoLibrary = true
    let savesCapturedVideosToPhotoLibrary = true
    
    /// Default configuration
    public static var `default`: CaptureSettings {
        return CaptureSettings(
            cameraMode: .photo,
            savesCapturedPhotosToPhotoLibrary: false
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
