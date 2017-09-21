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
 TODO: [not possible!] If your frame processing is consistently unable to keep up with the rate of incoming frames, you should consider using the minFrameDuration property, which will generally yield better performance characteristics and more consistent frame rates than frame dropping alone.
 TODO: try to optimize this so it's really eanbled only when we need it, not all the time
 NOTE: if video file output is provided, video data output is not working!!! there must be only 1 output at the same time
 */

final class VideoOutputSampleBufferDelegate : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    deinit {
        log("deinit: \(String(describing: self))")
    }
    
    let processQueue = DispatchQueue(label: "eu.inloop.video-output-sample-buffer-delegate.queue")
    var latestImage: UIImage?
    
    func captureOutput(_ output: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if let image = sampleBuffer.imageRepresentation {
            latestImage = image
            //log("output size: \(image.size)")
        }
    }
    
}

extension CMSampleBuffer {
    
    var imageRepresentation: UIImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(self) else {
            return nil
        }
        return UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
    }
}
