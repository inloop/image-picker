// Copyright © 2018 INLOOPX. All rights reserved.

import UIKit

class IconWithTextCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var topOffset: NSLayoutConstraint!
    @IBOutlet weak var bottomOffset: NSLayoutConstraint!
    
    private var originalBackgroundColor: UIColor?
    
    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? UIColor.red : originalBackgroundColor }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        originalBackgroundColor = backgroundColor
        imageView.backgroundColor = UIColor.clear
    }    
}
