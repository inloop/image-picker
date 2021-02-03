// Copyright © 2018 INLOOPX. All rights reserved.

import AVFoundation

/// Groups a method that informs a delegate about progress and state of photo capturing.
protocol CaptureSessionPhotoCapturingDelegate : class {
    /// called as soon as the photo was taken, use this to update UI - for example show flash animation or live photo icon
    func captureSession(_ session: CaptureSession, willCapturePhotoWith settings: AVCapturePhotoSettings)

    /// called when captured photo is processed and ready for use
    func captureSession(_ session: CaptureSession, didCapturePhotoData: Data, with settings: AVCapturePhotoSettings)
    
    /// called when captured live photo is processed and ready for use
    func captureSession(_ session: CaptureSession, didCapturePhotoData: Data, withCompanionMovieUrl: URL, with settings: AVCapturePhotoSettings)

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
