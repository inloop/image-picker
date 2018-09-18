//
//  VideoDataOuptutSampleBufferDelegate.swift
//  ImagePicker
//
//  Created by Peter Stajger on 21/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import AVFoundation

/*
 NOTE: if video file output is provided, video data output is not working!!! there must be only 1 output at the same time
 */

final class VideoOutputSampleBufferDelegate : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    deinit {
        log("deinit: \(String(describing: self))")
    }

    let processQueue = DispatchQueue(label: "eu.inloop.video-output-sample-buffer-delegate.queue")

    var latestImage: UIImage? {
        return latestSampleBuffer?.imageRepresentation
    }

    private var latestSampleBuffer: CMSampleBuffer?

    func captureOutput(_ output: AVCaptureOutput, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        latestSampleBuffer = sampleBuffer
    }

}

extension CMSampleBuffer {

    static let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])

    ///
    /// Converts Sample Buffer to UIImage with backing CGImage. This conversion
    /// is expensive, use it lazily.
    ///
    fileprivate var imageRepresentation: UIImage? {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(self) else {
            return nil
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // downscale image
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(ciImage, forKey: "inputImage")
        filter.setValue(0.25, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        let resizedCiImage = filter.value(forKey: "outputImage") as! CIImage


        // we need to convert CIImage to CGImage because we are using Apples blurring
        // functions (see UIImage+ImageEffects.h) and it requires UIImage with
        // backed CGImage. This conversion is very expensive, use it only
        // when you really need it

        if let cgImage = CMSampleBuffer.context.createCGImage(resizedCiImage, from: resizedCiImage.extent) {
            return UIImage(cgImage: cgImage)
        }

        return nil
    }
}
