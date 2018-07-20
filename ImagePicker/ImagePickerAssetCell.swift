//  Copyright © 2018 INLOOPX. All rights reserved.

import Foundation

/// Each image picker asset cell must conform to this protocol.

public protocol ImagePickerAssetCell: class {

    /// This image view will be used when setting an asset's image
    var imageView: UIImageView! { get }
    
    /// This is a helper identifier that is used when properly displaying cells asynchronously
    var representedAssetIdentifier: String? { get set }
}
