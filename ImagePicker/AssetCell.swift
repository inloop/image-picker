//
//  AssetCell.swift
//  ImagePicker
//
//  Created by Peter Stajger on 27/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import Photos

///
/// Each image picker asset cell must conform to this protocol.
///
public protocol ImagePickerAssetCell : class {
    
    /// This image view will be used when setting an asset's image
    var imageView: UIImageView! { get }
    
    /// This is a helper identifier that is used when properly displaying cells asynchronously
    var representedAssetIdentifier: String? { get set }
}

class VideoAssetCell : AssetCell {
    
    var durationLabel: UILabel
    var iconView: UIImageView
    
    override init(frame: CGRect) {
        
        durationLabel = UILabel(frame: .zero)
        iconView = UIImageView(frame: .zero)
        
        super.init(frame: frame)
        
        durationLabel.textColor = UIColor.white
        durationLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        durationLabel.textAlignment = .right
        //durationLabel.backgroundColor = UIColor.red
        contentView.addSubview(durationLabel)
        contentView.addSubview(iconView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let margin: CGFloat = 5
        durationLabel.frame.size = CGSize(width: 50, height: 20)
        durationLabel.frame.origin = CGPoint(
            x: contentView.bounds.width - durationLabel.frame.size.width - margin,
            y: contentView.bounds.height - durationLabel.frame.size.height - margin
        )
        iconView.frame.size = CGSize(width: 20, height: 20)
        iconView.frame.origin = CGPoint(
            x: margin,
            y: contentView.bounds.height - iconView.frame.height - margin
        )
    }
    
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    func update(with asset: PHAsset) {
        
        switch asset.mediaType {
        case .image:
            iconView.isHidden = true
            durationLabel.isHidden = true
        case .video:
            iconView.isHidden = false
            durationLabel.isHidden = false
            iconView.image = UIImage(named: "icon-check-background", in: Bundle(for: type(of: self)), compatibleWith: nil)
            durationLabel.text = VideoAssetCell.durationFormatter.string(from: asset.duration)
        default: break
        }
        
    }
    
}

///
/// A default implementation of `ImagePickerAssetCell`. If user does not register
/// a custom cell, Image Picker will use this one. It has an image view and
/// a camera icon with video duration if asset is of type video. Also contains
/// default icon for selected state.
///
class AssetCell : UICollectionViewCell, ImagePickerAssetCell {
    
    var imageView: UIImageView! = UIImageView(frame: .zero)
    fileprivate var selectedImageView = CheckView(frame: .zero)
    
    var representedAssetIdentifier: String?
    
    override var isSelected: Bool {
        didSet {
            selectedImageView.isHidden = !isSelected
            if selectedImageView.isHidden == false {
                selectedImageView.image = UIImage(named: "icon-check-background", in: Bundle(for: type(of: self)), compatibleWith: nil)
                selectedImageView.foregroundImage = UIImage(named: "icon-check", in: Bundle(for: type(of: self)), compatibleWith: nil)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        selectedImageView.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        
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
