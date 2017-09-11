//
//  ImagePickerAssetCellProtocol.swift
//  ImagePicker
//
//  Created by Peter Stajger on 11/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

public protocol ImagePickerAssetCell : class {
    
    /// This image view will be used when setting an asset's image
    var imageView: UIImageView! { get set }
    
    /// This is a helper identifier that is used when properly displaying cells asynchronously
    var representedAssetIdentifier: String? { get set }
}
