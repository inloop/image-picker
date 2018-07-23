// Copyright © 2018 INLOOPX. All rights reserved.

import Foundation

enum CaptureSessionError: Error {
    case failToCreateCaptureDevice
    case failToAddVideoDeviceInput
    case failToCreateVideoDeviceInput(Error)
    case failToAddVideoOutput
    case failToCreateAudioDevice
    case failToAddAudioDeviceInput
    case failToCreateAudioDeviceInput(Error)
    case failToAddPhotoOutput
    case failToAddVideoDataOutput

    var isWarning: Bool {
        switch self {
        case .failToAddAudioDeviceInput, .failToCreateAudioDeviceInput, .failToCreateAudioDevice, .failToAddVideoDataOutput: return true
        default: return false
        }
    }

    func logError() {
        log(description)
    }
}

private extension CaptureSessionError {
    var description: String {
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
}
