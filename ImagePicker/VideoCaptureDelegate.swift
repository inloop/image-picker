//
//  VideoCaptureDelegate.swift
//  ImagePicker
//
//  Created by Peter Stajger on 04/10/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import AVFoundation
import Photos

final class VideoCaptureDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    deinit {
        log("deinit: \(String(describing: self))")
    }

    // MARK: Public Methods

    /// set this to false if you dont wish to save video to photo library
    var savesVideoToLibrary = true

    /// true if user manually requested to cancel recording (stop without saving)
    var isBeingCancelled = false

    /// if system interrupts recording due to various reasons (empty space, phone call, background, ...)
    var recordingWasInterrupted = false

    /// non nil if failed or interrupted, nil if cancelled
    private(set) var recordingError: Error?

    init(didStart: @escaping ()->(), didFinish: @escaping (VideoCaptureDelegate)->(), didFail: @escaping (VideoCaptureDelegate, Error)->()) {
        self.didStart = didStart
        self.didFinish = didFinish
        self.didFail = didFail

        if UIDevice.current.isMultitaskingSupported {
            /*
             Setup background task.
             This is needed because the `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)`
             callback is not received until AVCam returns to the foreground unless you request background execution time.
             This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
             To conclude this background execution, endBackgroundTask(_:) is called in
             `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)` after the recorded file has been saved.
             */
            self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        }
    }

    // MARK: Private Methods

    private var backgroundRecordingID: UIBackgroundTaskIdentifier? = nil
    private var didStart: ()->()
    private var didFinish: (VideoCaptureDelegate)->()
    private var didFail: (VideoCaptureDelegate, Error)->()

    private func cleanUp(deleteFile: Bool, saveToAssets: Bool, outputFileURL: URL) {

        func deleteFileIfNeeded() {

            guard deleteFile == true else { return }

            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                }
                catch let error {
                    log("capture session: could not remove recording at url: \(outputFileURL)")
                    log("capture session: error: \(error)")
                }
            }
        }

        if let currentBackgroundRecordingID = backgroundRecordingID {
            backgroundRecordingID = UIBackgroundTaskIdentifier.invalid
            if currentBackgroundRecordingID != UIBackgroundTaskIdentifier.invalid {
                UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
            }
        }

        if saveToAssets {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        let videoResourceOptions = PHAssetResourceCreationOptions()
                        videoResourceOptions.shouldMoveFile = true
                        creationRequest.addResource(with: .video, fileURL: outputFileURL, options: videoResourceOptions)
                    }, completionHandler: { success, error in
                        if let error = error {
                            log("capture session: Error occurered while saving video to photo library: \(error)")
                            deleteFileIfNeeded()
                        }
                    })
                }
                else {
                    deleteFileIfNeeded()
                }
            }
        }
        else {
            deleteFileIfNeeded()
        }
    }

    // MARK: AVCaptureFileOutputRecordingDelegate Methods

    func fileOutput(_ captureOutput: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        didStart()
    }

    func fileOutput(_ captureOutput: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

        if let error = error {
            recordingError = error

            log("capture session: movie recording failed error: \(error)")

            //this can be true even if recording is stopped due to a reason (no disk space, ...) so the video can still be delivered.
            let successfullyFinished = (((error as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue) ?? false

            if successfullyFinished {
                recordingWasInterrupted = true
                cleanUp(deleteFile: true, saveToAssets: savesVideoToLibrary, outputFileURL: outputFileURL)
                didFail(self, error)
            }
            else {
                cleanUp(deleteFile: true, saveToAssets: false, outputFileURL: outputFileURL)
                didFail(self, error)
            }
        }
        else if isBeingCancelled == true {
            cleanUp(deleteFile: true, saveToAssets: false, outputFileURL: outputFileURL)
            didFinish(self)
        }
        else {
            cleanUp(deleteFile: true, saveToAssets: savesVideoToLibrary, outputFileURL: outputFileURL)
            didFinish(self)
        }

    }


}

