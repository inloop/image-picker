//
//  AssetCell.swift
//  ImagePicker
//
//  Created by Peter Stajger on 27/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

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
