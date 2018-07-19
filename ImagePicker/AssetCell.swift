// Copyright © 2018 INLOOPX. All rights reserved.

import Foundation

/// A default implementation of `ImagePickerAssetCell`. If user does not register a custom cell.
/// Image Picker will use this one. Also contains  default icon for selected state.

class AssetCell: UICollectionViewCell, ImagePickerAssetCell {
    var imageView: UIImageView! = UIImageView(frame: .zero)
    var representedAssetIdentifier: String?
    
    override var isSelected: Bool {
        didSet {
            selectedImageView.isHidden = !isSelected
            if !selectedImageView.isHidden {
                selectedImageView.image = UIImage(named: "icon-check-background", in: Bundle(for: type(of: self)), compatibleWith: nil)
                selectedImageView.foregroundImage = UIImage(named: "icon-check", in: Bundle(for: type(of: self)), compatibleWith: nil)
            }
        }
    }
    
    private var selectedImageView = CheckView(frame: .zero)
    private let contentMargin: CGFloat = 5

    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeViews()
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
            x: bounds.width - selectedImageView.frame.width - contentMargin,
            y: contentMargin
        )
    }
    
    private func initializeViews() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        selectedImageView.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        selectedImageView.isHidden = true
        
        contentView.addSubview(imageView)
        contentView.addSubview(selectedImageView)
    }
}


