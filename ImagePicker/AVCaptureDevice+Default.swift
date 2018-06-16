//
//  AVCaptureDevice+Default.swift
//  ImagePicker
//
//  Created by Anna Shirokova on 16/06/2018.
//  Copyright © 2018 Inloop. All rights reserved.
//

import AVFoundation

extension AVCaptureDevice {
    static var defaultVideoDevice: AVCaptureDevice? {
        return backDualCamera ?? backWideAngleCamera ?? frontWideAngleCamera
    }

    private static var backDualCamera: AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInDuoCamera, for: .video, position: .back)
    }

    private static var backWideAngleCamera: AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    private static var frontWideAngleCamera: AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    }
}
