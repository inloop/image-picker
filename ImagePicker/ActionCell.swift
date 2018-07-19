// Copyright © 2018 INLOOPX. All rights reserved.

import Foundation

/// Camera and photo library cell

final class ActionCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var leadingOffset: NSLayoutConstraint!
    @IBOutlet var trailingOffset: NSLayoutConstraint!
    @IBOutlet var topOffset: NSLayoutConstraint!
    @IBOutlet var bottomOffset: NSLayoutConstraint!
    
    private let normalOffset: CGFloat = 5
    private let largeOffset: CGFloat = 10
    
    private enum SubType {
        static let camera = 0
        static let library = 1
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.backgroundColor = .clear
    }
    
    func update(withIndex index: Int, layoutConfiguration: LayoutConfiguration) {
        updateLayout(withIndex: index, layoutConfiguration: layoutConfiguration)
        
        titleLabel.textColor = .black
        if index == SubType.camera {
            titleLabel.text = "Camera"
            imageView.image = UIImage(named: "button-camera", in: Bundle(for: type(of: self)), compatibleWith: nil)
        } else if index == SubType.library {
            titleLabel.text = "Photos"
            imageView.image = UIImage(named: "button-photo-library", in: Bundle(for: type(of: self)), compatibleWith: nil)
        }
    }
    
    private func updateLayout(withIndex index: Int, layoutConfiguration: LayoutConfiguration) {
        let layoutModel = LayoutModel(configuration: layoutConfiguration, assets: 0)
        let actionCount = layoutModel.numberOfItems(in: layoutConfiguration.sectionIndexForActions)
        
        let isFirst = index == 0
        let isLast = index == actionCount - 1
        
        switch layoutConfiguration.scrollDirection {
        case .horizontal:
            topOffset.constant = isFirst ? largeOffset : normalOffset
            bottomOffset.constant = isLast ? largeOffset : normalOffset
            leadingOffset.constant = normalOffset
            trailingOffset.constant = normalOffset
        case .vertical:
            topOffset.constant = 5
            bottomOffset.constant = 5
            leadingOffset.constant = isFirst ? largeOffset : normalOffset
            trailingOffset.constant = isLast ? largeOffset : normalOffset
        }
    }
}
