// Copyright © 2018 INLOOPX. All rights reserved.

import Photos

/// Manages AVCaptureSession

final class CaptureSession: NSObject {
    weak var delegate: CaptureSessionDelegate?
    weak var previewLayer: AVCaptureVideoPreviewLayer?
    weak var videoRecordingDelegate: CaptureSessionVideoRecordingDelegate?
    weak var photoCapturingDelegate: CaptureSessionPhotoCapturingDelegate?
    
    let session = AVCaptureSession()
    var isSessionRunning = false
    var presetConfiguration: SessionPresetConfiguration = .photos
    var isReadyForVideoRecording: Bool { return videoFileOutput != nil }
    var isRecordingVideo: Bool { return videoFileOutput?.isRecording ?? false }
    var latestVideoBufferImage: UIImage? { return videoOutpuSampleBufferDelegate.latestImage }
    var blurredBufferImage: UIImage? {
        guard let image = latestVideoBufferImage else { return nil }
        return UIImageEffects.imageByApplyingLightEffect(to: image)
    }
    
    /// Set this method to orientation that mathches UI orientation before `prepare()`
    /// method is called. If you need to update orientation when session is running,
    /// use `updateVideoOrientation()` method instead
    var videoOrientation: AVCaptureVideoOrientation = .portrait
    
    /// Communicate with the session and other session objects on this queue.
    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil)
    private var setupResult = SessionSetupResult.success
    private var videoDeviceInput: AVCaptureDeviceInput!
    private lazy var videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDuoCamera], mediaType: .video, position: .unspecified)
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private let videoOutpuSampleBufferDelegate = VideoOutputSampleBufferDelegate()
    private var videoFileOutput: AVCaptureMovieFileOutput?
    private var videoCaptureDelegate: VideoCaptureDelegate?
    private let photoOutput = AVCapturePhotoOutput()
    private var inProgressPhotoCaptureDelegates = [Int64 : PhotoCaptureDelegate]()
    private(set) var inProgressLivePhotoCapturesCount = 0
    private var sessionRunningObserveContext = 0
    private var addedObservers = false

    private let subjectAreaDidChangeNotificationKey = "AVCaptureDeviceSubjectAreaDidChangeNotification"
    private let runtimeErrorNotificationKey = "AVCaptureSessionRuntimeErrorNotification"
    private let sessionWasInterruptedNotificationKey = "AVCaptureSessionWasInterruptedNotification"
    private let interruptionEndedNotificationKey = "AVCaptureSessionInterruptionEndedNotification"
    
    enum SessionPresetConfiguration {
        case photos, livePhotos, videos
        
        var preset: AVCaptureSession.Preset {
            switch self {
            case .livePhotos, .photos:
                return .photo
            case .videos:
                return .high
            }
        }
    }
    
    enum LivePhotoMode {
        case on, off
    }
    
    enum RuntimeError: Error {
        case unableToRestart
    }
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    deinit {
        log("deinit: \(String(describing: self))")
    }
    
    /// Updates orientaiton on video outputs
    func updateVideoOrientation(new: AVCaptureVideoOrientation) {
        videoOrientation = new
        
        // We need to change orientation on all outputs
        previewLayer?.connection?.videoOrientation = new
        
        // TODO: we have to update orientation of video data output but it's blinking a bit which is
        // uggly, I have no idea how to fix this
        // note: when I added these 2 updates into a configuration block the lag was even worse
        sessionQueue.async {
            // When device is disconnected also video data output connection orientation is reset, so we need to set to new proper value
            self.videoDataOutput?.connection(with: AVMediaType.video)?.videoOrientation = new
        }
    }
    
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
        
        // We need to capture self in order to postpone deallocation while
        // session is properly stopped and cleaned up
        sessionQueue.async { [capturedSelf = self] in
            guard self.isSessionRunning == true else {
                return log("capture session: warning - trying to suspend non running session")
            }
            
            capturedSelf.session.stopRunning()
            capturedSelf.isSessionRunning = self.session.isRunning
            capturedSelf.removeObservers()
            // We are not calling delegate from here because
            // we are KVOing `isRunning` on session itself so it's called from there
        }
    }

    // MARK: Helpers
    private func requestAccessToCaptureDevice() {
        AVCaptureDevice.requestAccess(for: .video) { [capturedSelf = self] granted in
            if granted {
                DispatchQueue.main.async {
                    capturedSelf.delegate?.captureSession(capturedSelf, authorizationStatusGranted: .authorized)
                }
            } else {
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

    // MARK: - Configure Session
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
    private func addObservers() {
        guard !addedObservers else { return }
        
        session.addObserver(self, forKeyPath: "running", options: .new, context: &sessionRunningObserveContext)
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: Notification.Name(subjectAreaDidChangeNotificationKey), object: videoDeviceInput.device)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: Notification.Name(runtimeErrorNotificationKey), object: session)
        
        /*
         A session can only run when the app is full screen. It will be interrupted
         in a multi-app layout, introduced in iOS 9, see also the documentation of
         AVCaptureSessionInterruptionReason. Add observers to handle these session
         interruptions and show a preview is paused message. See the documentation
         of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
         */
        NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: Notification.Name(sessionWasInterruptedNotificationKey), object: session)
        NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: Notification.Name(interruptionEndedNotificationKey), object: session)
        
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
                } else {
                    self.delegate?.captureSessionDidSuspend(capturedSelf)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
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

// MARK: - Camera Change
extension CaptureSession {
    @objc func subjectAreaDidChange(notification: NSNotification) {
    }

    func changeCamera(completion: (() -> Void)?) {
        guard setupResult == .success else {
            return log("capture session: warning - trying to change camera but capture session setup failed")
        }

        sessionQueue.async { [unowned self] in
            let currentVideoDevice = self.videoDeviceInput.device
            let devices = self.videoDeviceDiscoverySession.devices
            guard let videoDevice = devices.getPreferredDevice(for: currentVideoDevice) else {
                return log("capture session: fail to find preferred device")
            }
            do {
                try self.configureVideoCapturingSession(for: videoDevice)
                DispatchQueue.main.async {
                    completion?()
                }
            }
            catch {
                print("Error occured while creating video device input: \(error)")
            }
        }
    }
}

// MARK: - Camera Change Helpers
extension CaptureSession {
    private func configureVideoCapturingSession(for videoDevice: AVCaptureDevice) throws {
        let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

        session.beginConfiguration()

        updateVideoDeviceInputIfPossible(newVideoDeviceInput: videoDeviceInput)
        updateStabilizationModeIfPossible()
        updateLivePhotoStatus()
        updateVideoDataOutputConnectionIfNeeded()

        session.commitConfiguration()
    }

    private func updateObserversForDevices(currentDevice: AVCaptureDevice, newDevice: AVCaptureDevice) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(subjectAreaDidChangeNotificationKey), object: currentDevice)
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: Notification.Name(subjectAreaDidChangeNotificationKey), object: newDevice)
    }

    private func updateVideoDeviceInputIfPossible(newVideoDeviceInput: AVCaptureDeviceInput) {
        // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
        session.removeInput(videoDeviceInput)

        if session.canAddInput(self.videoDeviceInput) {
            updateObserversForDevices(currentDevice: videoDeviceInput.device, newDevice: newVideoDeviceInput.device)

            session.addInput(newVideoDeviceInput)
            videoDeviceInput = newVideoDeviceInput
        } else {
            session.addInput(videoDeviceInput);
        }
    }

    private func updateStabilizationModeIfPossible() {
        guard let connection = self.videoFileOutput?.connection(with: AVMediaType.video), connection.isVideoStabilizationSupported else { return }
        connection.preferredVideoStabilizationMode = .auto
    }

    private func updateLivePhotoStatus() {
        photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported && presetConfiguration == .livePhotos
    }

    private func updateVideoDataOutputConnectionIfNeeded() {
        guard let videoDataOutputConnection = videoDataOutput?.connection(with: .video) else { return }
        videoDataOutputConnection.videoOrientation = videoOrientation
        if videoDataOutputConnection.isVideoMirroringSupported {
            videoDataOutputConnection.isVideoMirrored = true
        } else {
            log("capture session: warning - video mirroring on video data output is not supported")
        }
    }
}

// MARK: - Capture Photo
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
            self.updatePhotoOutputConnection(with:  videoPreviewLayerOrientation)
            let photoSettings = self.configurePhotoSettings(for: livePhotoMode)
            let photoCaptureDelegate = self.getCaptureDelegate(for: photoSettings, saveToPhotoLibrary: saveToPhotoLibrary)
            self.addReferenceToTheCaptureDelegate(photoCaptureDelegate)
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureDelegate)
        }
    }
}

// MARK: - Capture Photo Helper Methods
private extension CaptureSession {
    func updatePhotoOutputConnection(with videoPreviewLayerOrientation: AVCaptureVideoOrientation) {
        guard let photoOutputConnection = photoOutput.connection(with: AVMediaType.video) else { return }
        photoOutputConnection.videoOrientation = videoPreviewLayerOrientation
    }

    func updatePhotoSettingsForLiveMode(_ photoSettings: AVCapturePhotoSettings) {
        guard presetConfiguration == .livePhotos && photoOutput.isLivePhotoCaptureSupported else {
            return log("capture session: warning - trying to capture live photo but it's not supported by current configuration, capturing regular photo instead")
        }
        let livePhotoMovieFileName = NSUUID().uuidString
        let livePhotoMovieFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((livePhotoMovieFileName as NSString).appendingPathExtension("mov")!)
        photoSettings.livePhotoMovieFileURL = URL(fileURLWithPath: livePhotoMovieFilePath)
    }

    func capturePhotoAnimation(_ photoSettings: AVCapturePhotoSettings) {
        DispatchQueue.main.async { [unowned self] in
            self.photoCapturingDelegate?.captureSession(self, willCapturePhotoWith: photoSettings)
        }
    }

    func capturingLivePhoto(_ capturing: Bool) {
        self.sessionQueue.async { [unowned self] in
            /*
             Because Live Photo captures can overlap, we need to keep track of the
             number of in progress Live Photo captures to ensure that the
             Live Photo label stays visible during these captures.
             */
            let inProgressLivePhotoCapturesCount = self.updateInProgressLivePhotoCapturesCount(for: capturing)
            DispatchQueue.main.async { [unowned self] in
                if inProgressLivePhotoCapturesCount >= 0 {
                    self.photoCapturingDelegate?.captureSessionDidChangeNumberOfProcessingLivePhotos(self)
                } else {
                    log("capture session: error - in progress live photo capture count is less than 0");
                }
            }
        }
    }

    func updateInProgressLivePhotoCapturesCount(for capturing: Bool) -> Int {
        if capturing {
            inProgressLivePhotoCapturesCount += 1
        } else {
            inProgressLivePhotoCapturesCount -= 1
        }

        return inProgressLivePhotoCapturesCount
    }

    func processPhotoCaptureCompletion(delegate: PhotoCaptureDelegate) {
        removeReferenceToCaptureDelegate(delegate)

        DispatchQueue.main.async {
            self.finishCaptureSession(delegate: delegate)
        }
    }

    func removeReferenceToCaptureDelegate(_ delegate: PhotoCaptureDelegate) {
        self.sessionQueue.async { [unowned self] in
            self.inProgressPhotoCaptureDelegates[delegate.requestedPhotoSettings.uniqueID] = nil
        }
    }

    func finishCaptureSession(delegate: PhotoCaptureDelegate) {
        if let data = delegate.photoData {
            photoCapturingDelegate?.captureSession(self, didCapturePhotoData: data, with: delegate.requestedPhotoSettings)
        } else if let error = delegate.processError {
            photoCapturingDelegate?.captureSession(self, didFailCapturingPhotoWith: error)
        }
    }

    func addReferenceToTheCaptureDelegate(_ photoCaptureDelegate: PhotoCaptureDelegate) {
        inProgressPhotoCaptureDelegates[photoCaptureDelegate.requestedPhotoSettings.uniqueID] = photoCaptureDelegate
    }

    func getCaptureDelegate(for photoSettings: AVCapturePhotoSettings, saveToPhotoLibrary: Bool) -> PhotoCaptureDelegate {
        let delegate = PhotoCaptureDelegate(with: photoSettings, willCapturePhotoAnimation: {
            self.capturePhotoAnimation(photoSettings)
        }, capturingLivePhoto: { capturing in
            self.capturingLivePhoto(capturing)
        }, completed: { [unowned self] delegate in
            self.processPhotoCaptureCompletion(delegate: delegate)
        })

        delegate.savesPhotoToLibrary = saveToPhotoLibrary
        return delegate
    }

    func configurePhotoSettings(for livePhotoMode: LivePhotoMode) -> AVCapturePhotoSettings {
        let photoSettings = AVCapturePhotoSettings.defaultSettings
        photoSettings.configureThumbnail()

        if livePhotoMode == .on {
            updatePhotoSettingsForLiveMode(photoSettings)
        }
        return photoSettings
    }
}

// MARK: - Video Recording
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
        guard let videoPreviewLayerOrientation = previewLayer.connection?.videoOrientation else {
            return log("capture session: fail to retrieve video orientation")
        }
        
        sessionQueue.async { [weak self] in
            self?.recordVideo(output: movieFileOutput, orientation: videoPreviewLayerOrientation, saveToPhotoLibrary: saveToPhotoLibrary)
        }
    }

    /// If there is any recording in progres it will be stopped.
    ///
    /// - parameter cancel: if true, recorded file will be deleted and corresponding delegate method will be called.
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

// MARK: - Video Recording Helpers
private extension CaptureSession {
    func recordVideo(output movieFileOutput: AVCaptureMovieFileOutput, orientation videoPreviewLayerOrientation: AVCaptureVideoOrientation, saveToPhotoLibrary: Bool) {
        // If already recording do nothing
        guard movieFileOutput.isRecording == false else {
            return log("capture session: trying to record a video but there is one already being recorded")
        }

        self.updateVideoOrientation(videoPreviewLayerOrientation)
        let outputURL = self.temporaryVideoOutputURL
        let recordingDelegate = self.createVideoRecordingDelegate(outputURL: outputURL, saveToPhotoLibrary: saveToPhotoLibrary)
        self.startRecording(movieFileOutput: movieFileOutput,
                            outputURL: outputURL,
                            recordingDelegate: recordingDelegate)
    }

    func startRecording(movieFileOutput: AVCaptureMovieFileOutput, outputURL: URL, recordingDelegate: VideoCaptureDelegate) {
        movieFileOutput.startRecording(to: outputURL, recordingDelegate: recordingDelegate)
        videoCaptureDelegate = recordingDelegate
    }

    func updateVideoOrientation(_ videoPreviewLayerOrientation: AVCaptureVideoOrientation) {
        let movieFileOutputConnection = self.videoFileOutput?.connection(with: AVMediaType.video)
        movieFileOutputConnection?.videoOrientation = videoPreviewLayerOrientation
    }

    var temporaryVideoOutputURL: URL {
        let outputFileName = NSUUID().uuidString
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension("mov")
    }

    func createVideoRecordingDelegate(outputURL: URL, saveToPhotoLibrary: Bool) -> VideoCaptureDelegate {
        let recordingDelegate = VideoCaptureDelegate(didStart: {
            DispatchQueue.main.async { [weak self] in
                self?.processStartVideoCapturing()
            }
        }, didFinish: { [weak self] delegate in
            self?.processStopVideoCapturing(delegate: delegate, outputURL: outputURL)
        }, didFail: { [weak self] delegate, error in
            self?.processFailVideoCapturing(delegate: delegate, outputURL: outputURL, error: error)
        })
        recordingDelegate.savesVideoToLibrary = saveToPhotoLibrary
        return recordingDelegate
    }

    func processStartVideoCapturing() {
        videoRecordingDelegate?.captureSessionDidStartVideoRecording(self)
    }

    func processStopVideoCapturing(delegate: VideoCaptureDelegate, outputURL: URL) {
        removeReferenceToVideoCaptureDelegate()
        DispatchQueue.main.async {
            if delegate.isBeingCancelled {
                self.videoRecordingDelegate?.captureSessionDidCancelVideoRecording(self)
            } else {
                self.videoRecordingDelegate?.captureSessionDid(self, didFinishVideoRecording: outputURL)
            }
        }
    }

    func processFailVideoCapturing(delegate: VideoCaptureDelegate, outputURL: URL, error: Error) {
        removeReferenceToVideoCaptureDelegate()
        DispatchQueue.main.async {
            if delegate.recordingWasInterrupted {
                self.videoRecordingDelegate?.captureSessionDid(self, didInterruptVideoRecording: outputURL, reason: error)
            } else {
                self.videoRecordingDelegate?.captureSessionDid(self, didFailVideoRecording: error)
            }
        }
    }

    func removeReferenceToVideoCaptureDelegate() {
        sessionQueue.async {
            self.videoCaptureDelegate = nil
        }
    }
}
