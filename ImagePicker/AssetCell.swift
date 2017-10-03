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
    fileprivate var selectedImageView = CheckView(frame: .zero)
    
    var representedAssetIdentifier: String?
    
    override var isSelected: Bool {
        didSet { selectedImageView.isHidden = !isSelected }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        selectedImageView.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        selectedImageView.image = UIImage(named: "icon-check-background", in: Bundle(for: type(of: self)), compatibleWith: nil)
        selectedImageView.foregroundImage = UIImage(named: "icon-check", in: Bundle(for: type(of: self)), compatibleWith: nil)
        
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
        selectedImageView.frame.origin = CGPoint(
            x: bounds.width - selectedImageView.frame.width - 5,
            y: bounds.height - selectedImageView.frame.height - 5
        )
    }
    
}

private final class CheckView : UIImageView {
    
    var foregroundImage: UIImage? {
        get { return foregroundView.image }
        set { foregroundView.image = newValue }
    }
    
    private let foregroundView = UIImageView(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(foregroundView)
        contentMode = .center
        foregroundView.contentMode = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        foregroundView.frame = bounds
    }
}
