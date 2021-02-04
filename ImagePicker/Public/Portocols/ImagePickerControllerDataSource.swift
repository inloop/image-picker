// Copyright © 2018 INLOOPX. All rights reserved.

import Foundation
import Photos

/// Image picker may ask for additional resources, implement this protocol to fully support
/// all features.

public protocol ImagePickerControllerDataSource: class {
    /// Asks for a view that is placed as overlay view with permissions info
    /// when user did not grant or has restricted access to photo library.
    func imagePicker(controller: ImagePickerController,  viewForAuthorizationStatus status: PHAuthorizationStatus) -> UIView
}
