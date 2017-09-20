//
//  CaptureSession.swift
//  ExampleApp
//
//  Created by Peter Stajger on 27/03/17.
//  Copyright © 2017 Peter Stajger. All rights reserved.
//

import Foundation
import AVFoundation
import Photos
import UIKit

/// Groups a method that informs a delegate about progress and state of photo capturing.
protocol CaptureSessionPhotoCapturingDelegate : class {
    
    /// called as soon as the photo was taken, use this to update UI - for example show flash animation or live photo icon
    func captureSession(_ session: CaptureSession, willCapturePhotoWith settings: AVCapturePhotoSettings)
    
    /// called when captured photo is processed and ready for use
    func captureSession(_ session: CaptureSession, didCapturePhotoWith settings: AVCapturePhotoSettings)
}

/// Groups a method that informs a delegate about progress and state of video recording.
protocol CaptureSessionVideoRecordingDelegate : class {
 
    ///called when video file recording output is added to the session
    func captureSessionDidBecomeReadyForVideoRecording(_ session: CaptureSession)
    
    ///called when recording started
    func captureSessionDidStartVideoRecording(_ session: CaptureSession)
    
    ///called when cancel recording as a result of calling `cancelVideoRecording` func.
    func captureSessionDidCancelVideoRecording(_ session: CaptureSession)
    func captureSessionDid(_ session: CaptureSession, didFinishVideoRecording videoURL: URL)
    func captureSessionDid(_ session: CaptureSession, didFailVideoRecording error: Error)
}

protocol CaptureSessionDelegate : class {
    
    ///called when session is successfully configured and started running
    func captureSessionDidResume(_ session: CaptureSession)
    
    ///called when session is was manually suspended
    func captureSessionDidSuspend(_ session: CaptureSession)
    
    ///capture session was running but did fail due to any AV error reason.
    func captureSession(_ session: CaptureSession, didFail error: AVError)
    
    ///called when creating and configuring session but something failed (e.g. input or output could not be added, etc
    func captureSessionDidFailConfiguringSession(_ session: CaptureSession)
    
    ///called when user did not authorize using audio or video
    func captureSession(_ session: CaptureSession, authorizationStatusFailed status: AVAuthorizationStatus)
    
    ///called when session is interrupted due to various reasons, for example when a phone call or user starts an audio using control center, etc.
    func captureSession(_ session: CaptureSession, wasInterrupted reason: AVCaptureSessionInterruptionReason)
    
    ///called when and interruption is ended and the session was automatically resumed.
    func captureSessionInterruptionDidEnd(_ session: CaptureSession)
}

///
/// Manages AVCaptureSession
///
final class CaptureSession : NSObject {
    
    deinit {
        log("deinit: \(String(describing: self))")
    }
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    weak var delegate: CaptureSessionDelegate?
    
    let session = AVCaptureSession()
    var isSessionRunning = false
    weak var previewLayer: AVCaptureVideoPreviewLayer?
    
    /// Communicate with the session and other session objects on this queue.
    fileprivate let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil)
    private var setupResult: SessionSetupResult = .success
    
    // MARK: Video Recoding
    
    weak var videoRecordingDelegate: CaptureSessionVideoRecordingDelegate?
    fileprivate var videoFileOutput: AVCaptureMovieFileOutput?
    fileprivate var backgroundRecordingID: UIBackgroundTaskIdentifier? = nil
    fileprivate var recordingIsBeingCancelled = false
    var isReadyForVideoRecording: Bool {
        return videoFileOutput != nil
    }
    
    // MARK: Photo Capturing
    
    fileprivate enum LivePhotoMode {
        case on
        case off
    }
    
    weak var photoCapturingDelegate: CaptureSessionPhotoCapturingDelegate?
    fileprivate var livePhotoMode: LivePhotoMode = .off
    fileprivate let photoOutput = AVCapturePhotoOutput()
    fileprivate var inProgressPhotoCaptureDelegates = [Int64 : PhotoCaptureDelegate]()
    fileprivate var inProgressLivePhotoCapturesCount = 0
    
    // MARK: Public Methods
    
    func prepare() {
        /*
         Check video authorization status. Video access is required and audio
         access is optional. If audio access is denied, audio is not recorded
         during movie recording.
         */
        //TODO: support also media type audio later!
        let mediaType = AVMediaTypeVideo
        switch AVCaptureDevice.authorizationStatus(forMediaType: mediaType) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
            
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. We suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [capturedSelf = self] granted in
                if !granted {
                    capturedSelf.setupResult = .notAuthorized
                }
                capturedSelf.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
        }
        
        /*
         Setup the capture session.
         In general it is not safe to mutate an AVCaptureSession or any of its
         inputs, outputs, or connections from multiple threads at the same time.
         
         Why not do all of this on the main queue?
         Because AVCaptureSession.startRunning() is a blocking call which can
         take a long time. We dispatch session setup to the sessionQueue so
         that the main queue isn't blocked, which keeps the UI responsive.
         */
        sessionQueue.async { [capturedSelf = self] in
            capturedSelf.configureSession()
        }
    }
    
    func resume() {
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                // Only setup observers and start the session running if setup succeeded.
                self.addObservers()
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
                // We are not calling the delegate here explicitly, because we are observing
                // `running` KVO on session itself.
                
            case .notAuthorized:
                log("capture session: not authorized")
                
                //TODO: be carefull, here we explicitly add media type video!
                DispatchQueue.main.async { [weak self] in
                    let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
                    self?.delegate?.captureSession(self!, authorizationStatusFailed: status)
                }
                
            case .configurationFailed:
                log("capture session: configuration failed")
                
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.captureSessionDidFailConfiguringSession(self!)
                }
            }
        }
    }
    
    func suspend() {
        
        guard setupResult == .success else {
            return
        }
        
        //we need to capture self in order to postpone deallocation while
        //session is properly stopped and cleaned up
        sessionQueue.async { [capturedSelf = self] in
            capturedSelf.session.stopRunning()
            capturedSelf.isSessionRunning = self.session.isRunning
            capturedSelf.removeObservers()
            //we are not calling delegate from here because
            //we are KVOing `isRunning` on session itself so it's called from there
        }
    }
    
    // MARK: Private Methods
    
    ///
    /// Cinfigures a session before it can be used, following steps are done:
    /// 1. adds video input
    /// 2. adds video output (for recording videos)
    /// 3. adds audio input (for video recording with audio)
    /// 4. adds photo output (for capturing photos)
    ///
    private func configureSession() {
        
        guard setupResult == .success else {
            return
        }
        
        log("capture session: configuring - adding video input")
        
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPresetHigh
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInDualCamera, mediaType: AVMediaTypeVideo, position: .back) {
                defaultVideoDevice = dualCameraDevice
            }
            else if let backCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
                // If the back dual camera is not available, default to the back wide angle camera.
                defaultVideoDevice = backCameraDevice
            }
            else if let frontCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
                // In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                
                DispatchQueue.main.async {
                    /*
                     Why are we dispatching this to the main queue?
                     Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
                     can only be manipulated on the main thread.
                     Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     */
                    self.previewLayer?.connection.videoOrientation = UIApplication.shared.statusBarOrientation.captureVideoOrientation
                }
            }
            else {
                log("capture session: could not add video device input to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        }
        catch {
            log("capture session: could not create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        log("capture session: configuring - adding video output")
        
        // Add video output.
        let movieFileOutput = AVCaptureMovieFileOutput()
        if self.session.canAddOutput(movieFileOutput) {
            self.session.addOutput(movieFileOutput)
            self.videoFileOutput = movieFileOutput
            
            DispatchQueue.main.async { [weak self] in
                self?.videoRecordingDelegate?.captureSessionDidBecomeReadyForVideoRecording(self!)
            }
        }
        else {
            log("capture session: could not add video output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        log("capture session: configuring - adding audio input")
        
        // Add audio input, if fails no need to fail whole configuration
        do {
            let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if session.canAddInput(audioDeviceInput) {
                session.addInput(audioDeviceInput)
            }
            else {
                log("capture session: could not add audio device input to the session")
            }
        }
        catch {
            log("capture session: could not create audio device input: \(error)")
        }
        
        log("capture session: configuring - adding photo output")

        // Add photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            if livePhotoMode == .on {
                photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
                if photoOutput.isLivePhotoCaptureSupported == false {
                    log("capture session: configuring - requested live photo mode is not supported by the device")
                }
            }
            log("capture session: configuring - live photo mode is \(photoOutput.isLivePhotoCaptureEnabled ? "enabled" : "disabled")")
        }
        else {
            log("capture session: could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }
    
    // MARK: KVO and Notifications
    
    private var sessionRunningObserveContext = 0
    private var addedObservers = false
    
    private func addObservers() {

        guard addedObservers == false else { return }
        
        session.addObserver(self, forKeyPath: "running", options: .new, context: &sessionRunningObserveContext)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: Notification.Name("AVCaptureSessionRuntimeErrorNotification"), object: session)
        
        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: Notification.Name("AVCaptureSessionWasInterruptedNotification"), object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: Notification.Name("AVCaptureSessionInterruptionEndedNotification"), object: session)
        
        addedObservers = true
    }
    
    private func removeObservers() {
        
        guard addedObservers == true else { return }
        
        NotificationCenter.default.removeObserver(self)
        session.removeObserver(self, forKeyPath: "running", context: &sessionRunningObserveContext)
        
        addedObservers = false
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &sessionRunningObserveContext {
            let newValue = change?[.newKey] as AnyObject?
            guard let isSessionRunning = newValue?.boolValue else { return }
            
            DispatchQueue.main.async { [capturedSelf = self] in
                log("capture session: is running - \(isSessionRunning)")
                if isSessionRunning {
                    self.delegate?.captureSessionDidResume(capturedSelf)
                }
                else {
                    self.delegate?.captureSessionDidSuspend(capturedSelf)
                }
            }
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
            return
        }
        
        let error = AVError(_nsError: errorValue)
        log("capture session: runtime error: \(error)")
        
        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        if error.code == .mediaServicesWereReset {
            sessionQueue.async { [capturedSelf = self] in
                if capturedSelf.isSessionRunning {
                    capturedSelf.session.startRunning()
                    capturedSelf.isSessionRunning = capturedSelf.session.isRunning
                }
                else {
                    DispatchQueue.main.async {
                        capturedSelf.delegate?.captureSession(capturedSelf, didFail: error)
                    }
                }
            }
        }
        else {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.captureSession(self!, didFail: error)
            }
        }
    }
    
    func sessionWasInterrupted(notification: NSNotification) {
        /*
         In some scenarios we want to enable the user to resume the session running.
         For example, if music playback is initiated via control center while
         using AVCam, then the user can let AVCam resume
         the session running, which will stop music playback. Note that stopping
         music playback in control center will not automatically resume the session
         running. Also note that it is not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSessionInterruptionReason(rawValue: reasonIntegerValue) {
            log("capture session: session was interrupted with reason \(reason)")
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.captureSession(self!, wasInterrupted: reason)
            }
        }
        else {
            log("capture session: session was interrupted due to unknown reason")
        }
    }
    
    func sessionInterruptionEnded(notification: NSNotification) {
        log("capture session: interruption ended")
        
        //this is called automatically when interruption is done and session
        //is automatically resumed. Delegate should know that this happened so
        //the UI can be updated
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.captureSessionInterruptionDidEnd(self!)
        }
    }
}

extension CaptureSession {
    
    func capturePhoto() {
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. We do this to ensure UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        guard let videoPreviewLayerOrientation = previewLayer?.connection?.videoOrientation else {
            return log("capture session: trying to capture a photo but no preview layer is set")
        }
        
        sessionQueue.async {
            // Update the photo output's connection to match the video orientation of the video preview layer.
            if let photoOutputConnection = self.photoOutput.connection(withMediaType: AVMediaTypeVideo) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation
            }
            
            // Capture a JPEG photo with flash set to auto and high resolution photo enabled.
            let photoSettings = AVCapturePhotoSettings()
            photoSettings.flashMode = .auto
            photoSettings.isHighResolutionPhotoEnabled = true
            
            //TODO: we dont need preview photo, we need thumbnail format, read `previewPhotoFormat` docs
            //photoSettings.embeddedThumbnailPhotoFormat
            //if photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 {
            //    photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String : photoSettings.availablePreviewPhotoPixelFormatTypes.first!]
            //}
            
            if self.livePhotoMode == .on && self.photoOutput.isLivePhotoCaptureSupported {
                let livePhotoMovieFileName = NSUUID().uuidString
                let livePhotoMovieFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((livePhotoMovieFileName as NSString).appendingPathExtension("mov")!)
                photoSettings.livePhotoMovieFileURL = URL(fileURLWithPath: livePhotoMovieFilePath)
            }
            
            // Use a separate object for the photo capture delegate to isolate each capture life cycle.
            let photoCaptureDelegate = PhotoCaptureDelegate(with: photoSettings, willCapturePhotoAnimation: {
                DispatchQueue.main.async { [unowned self] in
                    self.photoCapturingDelegate?.captureSession(self, willCapturePhotoWith: photoSettings)
                }
            }, capturingLivePhoto: { capturing in
                /*
                 Because Live Photo captures can overlap, we need to keep track of the
                 number of in progress Live Photo captures to ensure that the
                 Live Photo label stays visible during these captures.
                 */
                self.sessionQueue.async { [unowned self] in
                    if capturing {
                        self.inProgressLivePhotoCapturesCount += 1
                    }
                    else {
                        self.inProgressLivePhotoCapturesCount -= 1
                    }
                    
                    let inProgressLivePhotoCapturesCount = self.inProgressLivePhotoCapturesCount
                    DispatchQueue.main.async { //[unowned self] in
                        if inProgressLivePhotoCapturesCount > 0 {
                            //TODO: live photo is in progress so update delegate about this - it can show nice UI based on this
                        }
                        else if inProgressLivePhotoCapturesCount == 0 {
                            //TODO: live photo is not capturing anymore
                        }
                        else {
                            log("capture session: error - in progress live photo capture count is less than 0");
                        }
                    }
                }
            }, completed: { [unowned self] photoCaptureDelegate in
                // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                self.sessionQueue.async { [unowned self] in
                    self.inProgressPhotoCaptureDelegates[photoCaptureDelegate.requestedPhotoSettings.uniqueID] = nil
                }
                
                DispatchQueue.main.async {
                    self.photoCapturingDelegate?.captureSession(self, didCapturePhotoWith: photoCaptureDelegate.requestedPhotoSettings)
                }
            })
            
            /*
             The Photo Output keeps a weak reference to the photo capture delegate so
             we store it in an array to maintain a strong reference to this object
             until the capture is completed.
             */
            self.inProgressPhotoCaptureDelegates[photoCaptureDelegate.requestedPhotoSettings.uniqueID] = photoCaptureDelegate
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureDelegate)
        }
    }
    
}

extension CaptureSession: AVCaptureFileOutputRecordingDelegate {
    
    func startVideoRecording() {
        
        guard let movieFileOutput = self.videoFileOutput else {
            return
        }
        
        guard let previewLayer = self.previewLayer else {
            return
        }
        
        /*
         Retrieve the video preview layer's video orientation on the main queue
         before entering the session queue. We do this to ensure UI elements are
         accessed on the main thread and session configuration is done on the session queue.
         */
        let videoPreviewLayerOrientation = previewLayer.connection.videoOrientation
        
        sessionQueue.async { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            //if already recording do nothing
            guard movieFileOutput.isRecording == false else {
                return
            }
            
            if UIDevice.current.isMultitaskingSupported {
                /*
                 Setup background task.
                 This is needed because the `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)`
                 callback is not received until AVCam returns to the foreground unless you request background execution time.
                 This also ensures that there will be time to write the file to the photo library when AVCam is backgrounded.
                 To conclude this background execution, endBackgroundTask(_:) is called in
                 `capture(_:, didFinishRecordingToOutputFileAt:, fromConnections:, error:)` after the recorded file has been saved.
                 */
                strongSelf.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            }
            
            // Update the orientation on the movie file output video connection before starting recording.
            let movieFileOutputConnection = strongSelf.videoFileOutput?.connection(withMediaType: AVMediaTypeVideo)
            movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation
            
            // Start recording to a temporary file.
            //let outputFileName = NSUUID().uuidString
            let outputFileName = "exporting_video_to_this_file"
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("mov")
            movieFileOutput.startRecording(toOutputFileURL: outputURL, recordingDelegate: self)
        }
    }

    ///
    /// If there is any recording in progres it will be stopped.
    ///
    /// - parameter cancel: if true, recorded file will be deleted and corresponding delegate method will be called.
    ///
    func stopVideoRecording(cancel: Bool = false) {
    
        guard let movieFileOutput = self.videoFileOutput else {
            return
        }
        
        sessionQueue.async { [capturedSelf = self] in
            
            guard movieFileOutput.isRecording else {
                return
            }
            
            capturedSelf.recordingIsBeingCancelled = cancel
            movieFileOutput.stopRecording()
        }
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        DispatchQueue.main.async { [weak self] in
            self?.videoRecordingDelegate?.captureSessionDidStartVideoRecording(self!)
        }
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        func cleanup(deleteFile: Bool) {
            if let currentBackgroundRecordingID = backgroundRecordingID {
                backgroundRecordingID = UIBackgroundTaskInvalid
                if currentBackgroundRecordingID != UIBackgroundTaskInvalid {
                    UIApplication.shared.endBackgroundTask(currentBackgroundRecordingID)
                }
            }
            if deleteFile {
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
            recordingIsBeingCancelled = false
        }
        
        //var success = true
        if let error = error {
            log("capture session: movie recording failed error: \(error)")
            //this can be true even if recording is stopped due to a reason (no disk space)
            //let successfullyFinished = (((error as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as AnyObject).boolValue)
            cleanup(deleteFile: true)
            videoRecordingDelegate?.captureSessionDid(self, didFailVideoRecording: error)
        }
        else if recordingIsBeingCancelled == true {
            cleanup(deleteFile: true)
            self.videoRecordingDelegate?.captureSessionDidCancelVideoRecording(self)
        }
        else {
            cleanup(deleteFile: false)
            videoRecordingDelegate?.captureSessionDid(self, didFinishVideoRecording: outputFileURL)
        }

    }
    
}

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
