//
//  CaptureSession.swift
//  Image Picker
//
//  Created by Peter Stajger on 27/03/17.
//  Copyright © 2017 Peter Stajger. All rights reserved.
//

import AVFoundation
import Photos
import UIKit

// MARK: - CaptureSessionError
private enum CaptureSessionError: Error {
    case failToCreateCaptureDevice
    case failToAddVideoDeviceInput
    case failToCreateVideoDeviceInput(Error)
    case failToAddVideoOutput
    case failToCreateAudioDevice
    case failToAddAudioDeviceInput
    case failToCreateAudioDeviceInput(Error)
    case failToAddPhotoOutput
    case failToAddVideoDataOutput
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
    
    enum SessionPresetConfiguration {
        case photos, livePhotos
        case videos

        var preset: AVCaptureSession.Preset {
            switch self {
            case .livePhotos, .photos:
                return .photo
            case .videos:
                return .high
            }
        }
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
    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil)
    private var setupResult = SessionSetupResult.success
    private var videoDeviceInput: AVCaptureDeviceInput!
    private lazy var videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDuoCamera], mediaType: .video, position: .unspecified)
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private let videoOutpuSampleBufferDelegate = VideoOutputSampleBufferDelegate()
    
    /// returns latest captured image
    var latestVideoBufferImage: UIImage? {
        return videoOutpuSampleBufferDelegate.latestImage
    }

    var blurredBufferImage: UIImage? {
        guard let image = latestVideoBufferImage else { return nil }
        return UIImageEffects.imageByApplyingLightEffect(to: image)
    }
    
    // MARK: Video Recoding
    weak var videoRecordingDelegate: CaptureSessionVideoRecordingDelegate?
    private var videoFileOutput: AVCaptureMovieFileOutput?
    private var videoCaptureDelegate: VideoCaptureDelegate?
    
    var isReadyForVideoRecording: Bool {
        return videoFileOutput != nil
    }
    var isRecordingVideo: Bool {
        return videoFileOutput?.isRecording ?? false
    }
    
    // MARK: Photo Capturing
    enum LivePhotoMode {
        case on
        case off
    }
    
    weak var photoCapturingDelegate: CaptureSessionPhotoCapturingDelegate?
    
    // this is provided by argument of capturePhoto()
    private let photoOutput = AVCapturePhotoOutput()
    private var inProgressPhotoCaptureDelegates = [Int64 : PhotoCaptureDelegate]()
    
    /// contains number of currently processing live photos
    private(set) var inProgressLivePhotoCapturesCount = 0
    
    // MARK: Public Methods
    
    func prepare() {
        /*
         Check video authorization status. Video access is required and audio
         access is optional. If audio access is denied, audio is not recorded
         during movie recording.
         */
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: break
        case .notDetermined:
            /*
             The user has not yet been presented with the option to grant
             video access. We suspend the session queue to delay session
             setup until the access request has completed.
             
             Note that audio access will be implicitly requested when we
             create an AVCaptureDeviceInput for audio during session setup.
             */
            sessionQueue.suspend()
            requestAccessToCaptureDevice()
        case .restricted, .denied:
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
            guard !self.isSessionRunning else {
                return log("capture session: warning - trying to resume already running session")
            }
            self.processSetupResult()
        }
    }

    func suspend() {
        guard setupResult == .success else { return }
        
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

    // MARK: Helpers
    private func requestAccessToCaptureDevice() {
        AVCaptureDevice.requestAccess(for: .video) { [capturedSelf = self] granted in
            if granted {
                DispatchQueue.main.async {
                    capturedSelf.delegate?.captureSession(capturedSelf, authorizationStatusGranted: .authorized)
                }
            }
            else {
                capturedSelf.setupResult = .notAuthorized
            }
            capturedSelf.sessionQueue.resume()
        }
    }

    private func processSetupResult() {
        switch setupResult {
        case .success:
            processSuccess()
        case .notAuthorized:
            log("capture session: not authorized")
            DispatchQueue.main.async { [weak self] in
                self?.processNotAuthorized()
            }
        case .configurationFailed:
            log("capture session: configuration failed")
            DispatchQueue.main.async { [weak self] in
                self?.processConfigurationFailed()
            }
        }
    }

    private func processSuccess() {
        // Only setup observers and start the session running if setup succeeded.
        addObservers()
        session.startRunning()
        isSessionRunning = self.session.isRunning
        // We are not calling the delegate here explicitly, because we are observing
        // `running` KVO on session itself.
    }

    private func processNotAuthorized() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        delegate?.captureSession(self, authorizationStatusFailed: status)
    }

    private func processConfigurationFailed() {
        delegate?.captureSessionDidFailConfiguringSession(self)
    }

    // MARK: - Private Methods
    ///
    /// Cinfigures a session before it can be used, following steps are done:
    /// 1. adds video input
    /// 2. adds video output (for recording videos)
    /// 3. adds audio input (for video recording with audio)
    /// 4. adds photo output (for capturing photos)
    ///

    private func configureSession() {
        guard setupResult == .success else { return }
        session.beginConfiguration()
        session.sessionPreset = presetConfiguration.preset
        do {
            try addVideoInput()
            try addMovieFileOutputIfNeeded()
            try addAudioInputIfNeeded()
            try addPhotoOutputIfNeeded()
            try addVideoDataOutputIfNeeded()
            session.commitConfiguration()
        } catch {
            guard let error = error as? CaptureSessionError else { return }
            processCaptureSessionError(error)
        }
    }

    // MARK: KVO and Notifications
    
    private var sessionRunningObserveContext = 0
    private var addedObservers = false
    
    private func addObservers() {
        guard !addedObservers else { return }
        
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
        guard addedObservers else { return }
        
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
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    enum RuntimeError: Error {
        case unableToRestart
    }

    @objc func sessionRuntimeError(notification: NSNotification) {
        guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else { return }
        
        let error = AVError(_nsError: errorValue)
        log("capture session: runtime error: \(error)")

        /*
         Automatically try to restart the session running if media services were
         reset and the last start running succeeded. Otherwise, enable the user
         to try to resume the session running.
         */
        guard error.code == .mediaServicesWereReset else { return failToRestart(error) }

        sessionQueue.async { [capturedSelf = self] in
            if capturedSelf.isSessionRunning {
                capturedSelf.session.startRunning()
                capturedSelf.isSessionRunning = capturedSelf.session.isRunning
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.failToRestart(error)
                }
            }
        }
    }

    private func failToRestart(_ error: AVError) {
        delegate?.captureSession(self, didFail: error)
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
                guard let `self` = self else { return }
                self.delegate?.captureSession(self, wasInterrupted: reason)
            }
        } else {
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

// MARK: - Configure capture session
private extension CaptureSession {
    func addVideoInput() throws {
        log("capture session: configuring - adding video input")
        guard let defaultVideoDevice = AVCaptureDevice.defaultVideoDevice else { throw CaptureSessionError.failToCreateCaptureDevice }

        let videoDeviceInput: AVCaptureDeviceInput
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
        } catch {
            throw CaptureSessionError.failToCreateVideoDeviceInput(error)
        }
        guard session.canAddInput(videoDeviceInput) else { throw CaptureSessionError.failToAddVideoDeviceInput }
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

    func addMovieFileOutputIfNeeded() throws {
        guard presetConfiguration == .videos else { return }
        // A capture session cannot support at the same time:
        // - Live Photo capture and
        // - movie file output
        // - video data output
        // If your capture session includes an AVCaptureMovieFileOutput object, the
        // isLivePhotoCaptureSupported property becomes false.
        log("capture session: configuring - adding movie file input")

        let movieFileOutput = AVCaptureMovieFileOutput()
        guard session.canAddOutput(movieFileOutput) else { throw CaptureSessionError.failToAddVideoOutput }
        session.addOutput(movieFileOutput)
        videoFileOutput = movieFileOutput

        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.videoRecordingDelegate?.captureSessionDidBecomeReadyForVideoRecording(self)
        }
    }

    func addAudioInputIfNeeded() throws {
        guard presetConfiguration == .livePhotos || presetConfiguration == .videos else { return }
        log("capture session: configuring - adding audio input")
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else { throw CaptureSessionError.failToCreateAudioDevice }
        let audioDeviceInput: AVCaptureDeviceInput
        do {
            audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
        } catch {
            throw CaptureSessionError.failToCreateAudioDeviceInput(error)
        }

        guard session.canAddInput(audioDeviceInput) else { throw CaptureSessionError.failToAddAudioDeviceInput }
        session.addInput(audioDeviceInput)
    }

    func addPhotoOutputIfNeeded() throws {
        guard presetConfiguration == .livePhotos || presetConfiguration == .photos || presetConfiguration == .videos else { return }
        log("capture session: configuring - adding photo output")
        guard session.canAddOutput(photoOutput) else { throw CaptureSessionError.failToAddPhotoOutput }
        session.addOutput(photoOutput)
        photoOutput.isHighResolutionCaptureEnabled = true
        enableLivePhotosIfNeeded()
        log("capture session: configuring - live photo mode is \(photoOutput.isLivePhotoCaptureEnabled ? "enabled" : "disabled")")
    }

    func enableLivePhotosIfNeeded() {
        guard presetConfiguration == .livePhotos else { return }
        photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
        if !photoOutput.isLivePhotoCaptureSupported {
            log("capture session: configuring - requested live photo mode is not supported by the device")
        }
    }

    func addVideoDataOutputIfNeeded() throws {
        guard presetConfiguration != .videos else { return }
        // Add video data output - we use this to capture last video sample that is
        // used when blurring video layer - for example when capture session is suspended, changing configuration etc.
        // NOTE: video data output can not be connected at the same time as video file output!
        let videoDataOutput = AVCaptureVideoDataOutput()
        self.videoDataOutput = videoDataOutput
        guard session.canAddOutput(videoDataOutput) else { throw CaptureSessionError.failToAddVideoDataOutput }
        session.addOutput(videoDataOutput)

        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(videoOutpuSampleBufferDelegate, queue: videoOutpuSampleBufferDelegate.processQueue)

        if let connection = videoDataOutput.connection(with: .video) {
            connection.videoOrientation = videoOrientation
            connection.automaticallyAdjustsVideoMirroring = false
        }
    }

    func processCaptureSessionError(_ error: CaptureSessionError) {
        error.logError()
        if !error.isWarning {
            setupResult = .configurationFailed
            session.commitConfiguration()
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
                preferredDeviceType = AVCaptureDevice.DeviceType.builtInDuoCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = AVCaptureDevice.DeviceType.builtInWideAngleCamera
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

private extension CaptureSessionError {
    var isWarning: Bool {
        switch self {
        case .failToAddAudioDeviceInput, .failToCreateAudioDeviceInput, .failToCreateAudioDevice, .failToAddVideoDataOutput: return true
        default: return false
        }
    }

    private var description: String {
        switch self {
        case .failToCreateCaptureDevice: return "capture session: could not create capture device"
        case .failToAddVideoDeviceInput: return "capture session: could not add video device input to the session"
        case let .failToCreateVideoDeviceInput(error): return "capture session: could not create video device input: \(error)"
        case .failToAddVideoOutput: return "capture session: could not add video output to the session"
        case .failToCreateAudioDevice: return "capture session: could not create audio device"
        case .failToAddAudioDeviceInput: return "capture session: could not add audio device input to the session"
        case let .failToCreateAudioDeviceInput(error): return "capture session: could not create audio device input: \(error)"
        case .failToAddPhotoOutput: return "capture session: could not add photo output to the session"
        case .failToAddVideoDataOutput: return "capture session: warning - could not add video data output to the session"
        }
    }

    func logError() {
        log(description)
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

private extension AVCaptureDevice {
    static var defaultVideoDevice: AVCaptureDevice? {
        return backDualCamera ?? backWideAngleCamera ?? frontWideAngleCamera
    }

    static var backDualCamera: AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInDuoCamera, for: .video, position: .back)
    }

    static var backWideAngleCamera: AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }

    static var frontWideAngleCamera: AVCaptureDevice? {
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
    }
}
