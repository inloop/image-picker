//  Copyright © 2018 INLOOPX. All rights reserved.

import Foundation

protocol CameraCollectionViewCellDelegate: class {
    func takePicture()
    func takeLivePhoto()
    func startVideoRecording()
    func stopVideoRecording()
    func flipCamera(_ completion: (() -> Void)?)
}
