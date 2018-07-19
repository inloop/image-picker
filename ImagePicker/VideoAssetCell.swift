// Copyright © 2018 INLOOPX. All rights reserved.

import Foundation
import Photos

/// A default collection view cell that represents asset item. It supports:
/// - shows image view of image thumbnail
/// - icon and duration for videos
/// - selected icon when isSelected is true

final class VideoAssetCell: AssetCell {
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    private let durationLabel = UILabel(frame: .zero)
    private var iconView = UIImageView(frame: .zero)
    private var gradientView = UIImageView(frame: .zero)
    private let contentMargin: CGFloat = 5
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientView.frame.size = CGSize(width: bounds.width, height: 40)
        gradientView.frame.origin = CGPoint(x: 0, y: bounds.height - 40)
        
        durationLabel.frame.size = CGSize(width: 50, height: 20)
        durationLabel.frame.origin = CGPoint(
            x: contentView.bounds.width - durationLabel.frame.size.width - contentMargin,
            y: contentView.bounds.height - durationLabel.frame.size.height - contentMargin
        )
        
        iconView.frame.size = CGSize(width: 21, height: 21)
        iconView.frame.origin = CGPoint(
            x: contentMargin,
            y: contentView.bounds.height - iconView.frame.height - contentMargin
        )
    }
    
    func update(with asset: PHAsset) {
        if asset.mediaType == .image {
            updateImage(asset: asset)
        } else if asset.mediaType == .video {
            updateVideo(asset: asset)
        }
    }
    
    private func initializeViews() {
        gradientView.isHidden = true
        
        iconView.tintColor = .white
        iconView.contentMode = .center
        
        durationLabel.textColor = .white
        durationLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        durationLabel.textAlignment = .right
        
        contentView.addSubview(gradientView)
        contentView.addSubview(durationLabel)
        contentView.addSubview(iconView)
    }
    
    private func updateImage(asset: PHAsset) {
        if asset.mediaSubtypes.contains(.photoLive) {
            gradientView.isHidden = false
            iconView.isHidden = false
            durationLabel.isHidden = true
            
            iconView.image = UIImage(named: "icon-badge-livephoto", in: Bundle(for: type(of: self)), compatibleWith: nil)
            gradientView.image = UIImage(named: "gradient", in: Bundle(for: type(of: self)), compatibleWith: nil)?
                .resizableImage(withCapInsets: .zero, resizingMode: .stretch)
        } else {
            gradientView.isHidden = true
            iconView.isHidden = true
            durationLabel.isHidden = true
        }
    }
    
    private func updateVideo(asset: PHAsset) {
        gradientView.isHidden = false
        iconView.isHidden = false
        durationLabel.isHidden = false
        
        iconView.image = UIImage(named: "icon-badge-video", in: Bundle(for: type(of: self)), compatibleWith: nil)
        gradientView.image = UIImage(named: "gradient", in: Bundle(for: type(of: self)), compatibleWith: nil)?
            .resizableImage(withCapInsets: .zero, resizingMode: .stretch)
        
        durationLabel.text = VideoAssetCell.durationFormatter.string(from: asset.duration)
    }
}
