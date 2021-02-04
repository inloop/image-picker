// Copyright © 2018 INLOOPX. All rights reserved.

import AVFoundation

extension AVCapturePhotoSettings {
    static var defaultSettings: AVCapturePhotoSettings {
        let photoSettings = AVCapturePhotoSettings()
        photoSettings.flashMode = .auto
        photoSettings.isHighResolutionPhotoEnabled = true
        return photoSettings
    }

    func configureThumbnail() {
        //TODO: we dont need preview photo, we need thumbnail format, read `previewPhotoFormat` docs
        //photoSettings.embeddedThumbnailPhotoFormat
        //if photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 {
        //    photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String : photoSettings.availablePreviewPhotoPixelFormatTypes.first!]
        //}

        //TODO: I dont know how it works, need to find out
        if #available(iOS 11.0, *) {
            if availableEmbeddedThumbnailPhotoCodecTypes.count > 0 {
                //TODO: specify thumb size somehow, this does crash!
                //let size = CGSize(width: 200, height: 200)
                embeddedThumbnailPhotoFormat = [
                    //kCVPixelBufferWidthKey as String : size.width as CFNumber,
                    //kCVPixelBufferHeightKey as String : size.height as CFNumber,
                    AVVideoCodecKey : availableEmbeddedThumbnailPhotoCodecTypes[0]
                ]
            }
        }
    }
}
