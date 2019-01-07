//
//  CaptureSession.swift
//  Image Picker
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
    func captureSession(_ session: CaptureSession, didCapturePhotoData: Data, with settings: AVCapturePhotoSettings)

    /// called when captured photo is processed and ready for use
    func captureSession(_ session: CaptureSession, didFailCapturingPhotoWith error: Error)

    /// called when number of processing live photos changed, see inProgressLivePhotoCapturesCount for current count
    func captureSessionDidChangeNumberOfProcessingLivePhotos(_ session: CaptureSession)
}

/// Groups a method that informs a delegate about progress and state of video recording.
protocol CaptureSessionVideoRecordingDelegate : class {

    ///called when video file recording output is added to the session
    func captureSessionDidBecomeReadyForVideoRecording(_ session: CaptureSession)

    ///called when recording started
    func captureSessionDidStartVideoRecording(_ session: CaptureSession)

    ///called when cancel recording as a result of calling `cancelVideoRecording` func.
    func captureSessionDidCancelVideoRecording(_ session: CaptureSession)

    ///called when a recording was successfully finished
    func captureSessionDid(_ session: CaptureSession, didFinishVideoRecording videoURL: URL)

    ///called when a recording was finished prematurely due to a system interruption
    ///(empty disk, app put on bg, etc). Video is however saved on provided URL or in
    ///assets library if turned on.
    func captureSessionDid(_ session: CaptureSession, didInterruptVideoRecording videoURL: URL, reason: Error)

    ///called when a recording failed
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

    ///called when user denied access to video device when prompte
    func captureSession(_ session: CaptureSession, authorizationStatusFailed status: AVAuthorizationStatus)

    ///Called when user grants access to video device when prompted
    func captureSession(_ session: CaptureSession, authorizationStatusGranted status: AVAuthorizationStatus)

    ///called when session is interrupted due to various reasons, for example when a phone call or user starts an audio using control center, etc.
    func captureSession(_ session: CaptureSession, wasInterrupted reason: AVCaptureSession.InterruptionReason)

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

    fileprivate enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }

    enum SessionPresetConfiguration {
        case photos, livePhotos
        case videos
    }

    weak var delegate: CaptureSessionDelegate?

    let session = AVCaptureSession()
    var isSessionRunning = false
    weak var previewLayer: AVCaptureVideoPreviewLayer?

    var presetConfiguration: SessionPresetConfiguration = .photos

    ///
    /// Set this method to orientation that mathches UI orientation before `prepare()`
    /// method is called. If you need to update orientation when session is running,
    /// use `updateVideoOrientation()` method instead
    ///
    var videoOrientation: AVCaptureVideoOrientation = .portrait

    ///
    /// Updates orientaiton on video outputs
    ///
    func updateVideoOrientation(new: AVCaptureVideoOrientation) {

        videoOrientation = new

        //we need to change orientation on all outputs
        self.previewLayer?.connection?.videoOrientation = new

        //TODO: we have to update orientation of video data output but it's blinking a bit which is
        //uggly, I have no idea how to fix this
        //note: when I added these 2 updates into a configuration block the lag was even worse
        sessionQueue.async {
            //when device is disconnected also video data output connection orientation is reset, so we need to set to new proper value
            self.videoDataOutput?.connection(with: AVMediaType.video)?.videoOrientation = new
        }

    }

    /// Communicate with the session and other session objects on this queue.
    fileprivate let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil)
    fileprivate var setupResult: SessionSetupResult = .success
    fileprivate var videoDeviceInput: AVCaptureDeviceInput!
    fileprivate lazy var videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera, AVCaptureDevice.DeviceType.builtInDualCamera], mediaType: AVMediaType.video, position: .unspecified)
    fileprivate var videoDataOutput: AVCaptureVideoDataOutput?
    fileprivate let videoOutpuSampleBufferDelegate = VideoOutputSampleBufferDelegate()

    /// returns latest captured image
    var latestVideoBufferImage: UIImage? {
        return videoOutpuSampleBufferDelegate.latestImage
    }

    // MARK: Video Recoding

    weak var videoRecordingDelegate: CaptureSessionVideoRecordingDelegate?
    fileprivate var videoFileOutput: AVCaptureMovieFileOutput?
    fileprivate var videoCaptureDelegate: VideoCaptureDelegate?

    var isReadyForVideoRecording: Bool {
        return videoFileOutput != nil
    }
    var isRecordingVideo: Bool {
        return videoFileOutput?.isRecording ?? false
    }

    // MARK: Photo Capturing

    enum LivePhotoMode {
        // swiftlint:disable next identifier_name
        case on
        case off
    }

    weak var photoCapturingDelegate: CaptureSessionPhotoCapturingDelegate?

    // this is provided by argument of capturePhoto()
    //fileprivate var livePhotoMode: LivePhotoMode = .off
    fileprivate let photoOutput = AVCapturePhotoOutput()
    fileprivate var inProgressPhotoCaptureDelegates = [Int64 : PhotoCaptureDelegate]()

    /// contains number of currently processing live photos
    fileprivate(set) var inProgressLivePhotoCapturesCount = 0

    // MARK: Public Methods

    func prepare() {
        /*
         Check video authorization status. Video access is required and audio
         access is optional. If audio access is denied, audio is not recorded
         during movie recording.
         */
        let mediaType = AVMediaType.video
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
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
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { [capturedSelf = self] granted in
                if granted {
                    DispatchQueue.main.async {
                        capturedSelf.delegate?.captureSession(capturedSelf, authorizationStatusGranted: .authorized)
                    }
                }
                else {
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

            guard self.isSessionRunning == false else {
                return log("capture session: warning - trying to resume already running session")
            }

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
                DispatchQueue.main.async { [weak self] in
                    let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
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

            guard self.isSessionRunning == true else {
                return log("capture session: warning - trying to suspend non running session")
            }

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

        switch presetConfiguration {
        case .livePhotos, .photos:
            session.sessionPreset = AVCaptureSession.Preset.photo
        case .videos:
            session.sessionPreset = AVCaptureSession.Preset.high
        }

        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?

            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera, for: AVMediaType.video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            }
            else if let backCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
                // If the back dual camera is not available, default to the back wide angle camera.
                defaultVideoDevice = backCameraDevice
            }
            else if let frontCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
                // In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            else {
                log("capture session: could not create capture device")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }

            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)

            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)

                self.videoDeviceInput = videoDeviceInput

                DispatchQueue.main.async {
                    /*
                     Why are we dispatching this to the main queue?
                     Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
                     can only be manipulated on the main thread.
                     Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                     on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                     */
                    self.previewLayer?.connection?.videoOrientation = self.videoOrientation
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


        // Add movie file output.
        if presetConfiguration == .videos {

            // A capture session cannot support at the same time:
            // - Live Photo capture and
            // - movie file output
            // - video data output
            // If your capture session includes an AVCaptureMovieFileOutput object, the
            // isLivePhotoCaptureSupported property becomes false.

            log("capture session: configuring - adding movie file input")

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
        }

        if presetConfiguration == .livePhotos || presetConfiguration == .videos {

            log("capture session: configuring - adding audio input")

            // Add audio input, if fails no need to fail whole configuration
            do {
                let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
                let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)

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
        }

        if presetConfiguration == .livePhotos || presetConfiguration == .photos || presetConfiguration == .videos {
            // Add photo output.
            log("capture session: configuring - adding photo output")

            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.isHighResolutionCaptureEnabled = true

                //enable live photos only if we intend to use it explicitly
                if presetConfiguration == .livePhotos {
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
        }

        if presetConfiguration != .videos {
            // Add video data output - we use this to capture last video sample that is
            // used when blurring video layer - for example when capture session is suspended, changing configuration etc.
            // NOTE: video data output can not be connected at the same time as video file output!
            videoDataOutput = AVCaptureVideoDataOutput()
            if session.canAddOutput(videoDataOutput!) {
                session.addOutput(videoDataOutput!)
                videoDataOutput!.alwaysDiscardsLateVideoFrames = true
                videoDataOutput!.setSampleBufferDelegate(videoOutpuSampleBufferDelegate, queue: videoOutpuSampleBufferDelegate.processQueue)

                if let connection = videoDataOutput!.connection(with: AVMediaType.video) {
                    connection.videoOrientation = self.videoOrientation
                    connection.automaticallyAdjustsVideoMirroring = false
                }
            }
            else {
                log("capture session: warning - could not add video data output to the session")
            }
        }

        session.commitConfiguration()
    }

    // MARK: KVO and Notifications

    private var sessionRunningObserveContext = 0
    private var addedObservers = false

    private func addObservers() {

        guard addedObservers == false else { return }

        session.addObserver(self, forKeyPath: "running", options: .new, context: &sessionRunningObserveContext)
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: Notification.Name("AVCaptureDeviceSubjectAreaDidChangeNotification"), object: videoDeviceInput.device)
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

    @objc func sessionRuntimeError(notification: NSNotification) {
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

    @objc func sessionWasInterrupted(notification: NSNotification) {
        /*
         In some scenarios we want to enable the user to resume the session running.
         For example, if music playback is initiated via control center while
         using AVCam, then the user can let AVCam resume
         the session running, which will stop music playback. Note that stopping
         music playback in control center will not automatically resume the session
         running. Also note that it is not always possible to resume, see `resumeInterruptedSession(_:)`.
         */
        if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
            log("capture session: session was interrupted with reason \(reason)")
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.captureSession(self!, wasInterrupted: reason)
            }
        }
        else {
            log("capture session: session was interrupted due to unknown reason")
        }
    }

    @objc func sessionInterruptionEnded(notification: NSNotification) {
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

    @objc func subjectAreaDidChange(notification: NSNotification) {
        //        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        //        focus(with: .autoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
    }

    func changeCamera(completion: (() -> Void)?) {

        guard setupResult == .success else {
            return log("capture session: warning - trying to change camera but capture session setup failed")
        }

        sessionQueue.async { [unowned self] in
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position

            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType

            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = AVCaptureDevice.DeviceType.builtInDualCamera

            case .back:
                preferredPosition = .front
                preferredDeviceType = AVCaptureDevice.DeviceType.builtInWideAngleCamera
            default:
                preferredPosition = .back
                preferredDeviceType = AVCaptureDevice.DeviceType.builtInDualCamera
            }

            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil

            // First, look for a device with both the preferred position and device type. Otherwise, look for a device with only the preferred position.
            if let device = devices.filter({ $0.position == preferredPosition && $0.deviceType == preferredDeviceType }).first {
                newVideoDevice = device
            }
            else if let device = devices.filter({ $0.position == preferredPosition }).first {
                newVideoDevice = device
            }

            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

                    self.session.beginConfiguration()

                    // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
                    self.session.removeInput(self.videoDeviceInput)

                    if self.session.canAddInput(videoDeviceInput) {
                        NotificationCenter.default.removeObserver(self, name: Notification.Name("AVCaptureDeviceSubjectAreaDidChangeNotification"), object: currentVideoDevice)
                        NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange), name: Notification.Name("AVCaptureDeviceSubjectAreaDidChangeNotification"), object: videoDeviceInput.device)

                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    }
                    else {
                        self.session.addInput(self.videoDeviceInput);
                    }

                    if let connection = self.videoFileOutput?.connection(with: AVMediaType.video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }

                    /*
                     Set Live Photo capture enabled if it is supported. When changing cameras, the
                     `isLivePhotoCaptureEnabled` property of the AVCapturePhotoOutput gets set to NO when
                     a video device is disconnected from the session. After the new video device is
                     added to the session, re-enable Live Photo capture on the AVCapturePhotoOutput if it is supported.
                     */
                    self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported && self.presetConfiguration == .livePhotos;

                    // when device is disconnected:
                    // - video data output connection orientation is reset, so we need to set to new proper value
                    // - video mirroring is set to true if camera is front, make sure we use no mirroring
                    if let videoDataOutputConnection = self.videoDataOutput?.connection(with: AVMediaType.video) {
                        videoDataOutputConnection.videoOrientation = self.videoOrientation
                        if videoDataOutputConnection.isVideoMirroringSupported {
                            videoDataOutputConnection.isVideoMirrored = true
                        }
                        else {
                            log("capture session: warning - video mirroring on video data output is not supported")
                        }

                    }

                    self.session.commitConfiguration()

                    DispatchQueue.main.async { //[unowned self] in
                        completion?()
                    }
                }
                catch {
                    print("Error occured while creating video device input: \(error)")
                }
            }
        }
    }

}

extension CaptureSession {

    func capturePhoto(livePhotoMode: LivePhotoMode, saveToPhotoLibrary: Bool) {
        /*
         Retrieve the video preview layer's video orientation on the main queue before
         entering the session queue. We do this to ensure UI elements are accessed on
         the main thread and session configuration is done on the session queue.
         */
        guard let videoPreviewLayerOrientation = previewLayer?.connection?.videoOrientation else {
            return log("capture session: warning - trying to capture a photo but no preview layer is set")
        }

        sessionQueue.async {
            // Update the photo output's connection to match the video orientation of the video preview layer.
            if let photoOutputConnection = self.photoOutput.connection(with: AVMediaType.video) {
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

            //TODO: I dont know how it works, need to find out
            if #available(iOS 11.0, *) {
                if photoSettings.availableEmbeddedThumbnailPhotoCodecTypes.count > 0 {
                    //TODO: specify thumb size somehow, this does crash!
                    //let size = CGSize(width: 200, height: 200)
                    photoSettings.embeddedThumbnailPhotoFormat = [
                        //kCVPixelBufferWidthKey as String : size.width as CFNumber,
                        //kCVPixelBufferHeightKey as String : size.height as CFNumber,
                        AVVideoCodecKey : photoSettings.availableEmbeddedThumbnailPhotoCodecTypes[0]
                    ]
                }
            }

            if livePhotoMode == .on {
                if self.presetConfiguration == .livePhotos && self.photoOutput.isLivePhotoCaptureSupported {
                    let livePhotoMovieFileName = NSUUID().uuidString
                    let livePhotoMovieFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((livePhotoMovieFileName as NSString).appendingPathExtension("mov")!)
                    photoSettings.livePhotoMovieFileURL = URL(fileURLWithPath: livePhotoMovieFilePath)
                }
                else {
                    log("capture session: warning - trying to capture live photo but it's not supported by current configuration, capturing regular photo instead")
                }
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
                    DispatchQueue.main.async { [unowned self] in
                        if inProgressLivePhotoCapturesCount >= 0 {
                            self.photoCapturingDelegate?.captureSessionDidChangeNumberOfProcessingLivePhotos(self)
                        }
                        else {
                            log("capture session: error - in progress live photo capture count is less than 0");
                        }
                    }
                }
            }, completed: { [unowned self] delegate in
                // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                self.sessionQueue.async { [unowned self] in
                    self.inProgressPhotoCaptureDelegates[delegate.requestedPhotoSettings.uniqueID] = nil
                }

                DispatchQueue.main.async {
                    if let data = delegate.photoData {
                        self.photoCapturingDelegate?.captureSession(self, didCapturePhotoData: data, with: delegate.requestedPhotoSettings)
                    }
                    else if let error = delegate.processError {
                        self.photoCapturingDelegate?.captureSession(self, didFailCapturingPhotoWith: error)
                    }
                }
            })

            photoCaptureDelegate.savesPhotoToLibrary = saveToPhotoLibrary

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

extension CaptureSession {

    func startVideoRecording(saveToPhotoLibrary: Bool) {

        guard let movieFileOutput = self.videoFileOutput else {
            return log("capture session: trying to record a video but no movie file output is set")
        }

        guard let previewLayer = self.previewLayer else {
            return log("capture session: trying to record a video but no preview layer is set")
        }

        /*
         Retrieve the video preview layer's video orientation on the main queue
         before entering the session queue. We do this to ensure UI elements are
         accessed on the main thread and session configuration is done on the session queue.
         */
        let videoPreviewLayerOrientation = previewLayer.connection?.videoOrientation

        sessionQueue.async { [weak self] in

            guard let strongSelf = self else {
                return
            }

            // if already recording do nothing
            guard movieFileOutput.isRecording == false else {
                return log("capture session: trying to record a video but there is one already being recorded")
            }

            // update the orientation on the movie file output video connection before starting recording.
            let movieFileOutputConnection = strongSelf.videoFileOutput?.connection(with: AVMediaType.video)
            movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation!

            // start recording to a temporary file.
            let outputFileName = NSUUID().uuidString
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("mov")

            // create a recording delegate
            let recordingDelegate = VideoCaptureDelegate(didStart: {
                DispatchQueue.main.async { [weak self] in
                    self?.videoRecordingDelegate?.captureSessionDidStartVideoRecording(self!)
                }
            }, didFinish: { (delegate) in

                // we need to remove reference to the delegate so it can be deallocated
                self?.sessionQueue.async {
                    self?.videoCaptureDelegate = nil
                }

                DispatchQueue.main.async { [weak self] in
                    if delegate.isBeingCancelled {
                        self?.videoRecordingDelegate?.captureSessionDidCancelVideoRecording(self!)
                    }
                    else {
                        self?.videoRecordingDelegate?.captureSessionDid(self!, didFinishVideoRecording: outputURL)
                    }
                }

            }, didFail: { (delegate, error) in

                // we need to remove reference to the delegate so it can be deallocated
                self?.sessionQueue.async {
                    self?.videoCaptureDelegate = nil
                }

                DispatchQueue.main.async { [weak self] in
                    if delegate.recordingWasInterrupted {
                        self?.videoRecordingDelegate?.captureSessionDid(self!, didInterruptVideoRecording: outputURL, reason: error)
                    }
                    else {
                        self?.videoRecordingDelegate?.captureSessionDid(self!, didFailVideoRecording: error)
                    }
                }
            })
            recordingDelegate.savesVideoToLibrary = saveToPhotoLibrary

            // start recording
            movieFileOutput.startRecording(to: outputURL, recordingDelegate: recordingDelegate)
            strongSelf.videoCaptureDelegate = recordingDelegate
        }
    }

    ///
    /// If there is any recording in progres it will be stopped.
    ///
    /// - parameter cancel: if true, recorded file will be deleted and corresponding delegate method will be called.
    ///
    func stopVideoRecording(cancel: Bool = false) {

        guard let movieFileOutput = self.videoFileOutput else {
            return log("capture session: trying to stop a video recording but no movie file output is set")
        }

        sessionQueue.async { [capturedSelf = self] in

            guard movieFileOutput.isRecording else {
                return log("capture session: trying to stop a video recording but no recording is in progress")
            }

            guard let recordingDelegate = capturedSelf.videoCaptureDelegate else {
                fatalError("capture session: trying to stop a video recording but video capture delegate is nil")
            }

            recordingDelegate.isBeingCancelled = cancel
            movieFileOutput.stopRecording()
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


