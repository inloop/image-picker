//
//  AssetCell.swift
//  ImagePicker
//
//  Created by Peter Stajger on 27/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

///
/// Each image picker asset cell must conform to this protocol.
///
public protocol ImagePickerAssetCell : class {
    
    //TODO: why is this also set? do we need set?
    /// This image view will be used when setting an asset's image
    var imageView: UIImageView! { get set }
    
    /// This is a helper identifier that is used when properly displaying cells asynchronously
    var representedAssetIdentifier: String? { get set }
}

///
/// A default implementation of `ImagePickerAssetCell`. If user does not register
/// her custom cell, Image Picker will use this one.
///
class AssetCell : UICollectionViewCell, ImagePickerAssetCell {
    
    var imageView: UIImageView! = UIImageView(frame: .zero)
    let selectedImageView = UIImageView(frame: .zero)
    
    var representedAssetIdentifier: String?
    
    override var isSelected: Bool {
        didSet { selectedImageView.isHidden = !isSelected }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        selectedImageView.backgroundColor = UIColor.red //TODO: we need an default asset for selected image
        contentView.addSubview(imageView)
        contentView.addSubview(selectedImageView)
        selectedImageView.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        selectedImageView.frame = bounds
    }
    
}
