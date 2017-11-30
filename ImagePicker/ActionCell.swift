//
//  IconWithTextCell.swift
//  ExampleApp
//
//  Created by Peter Stajger on 06/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit

final class ActionCell : UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet var leadingOffset: NSLayoutConstraint!
    @IBOutlet var trailingOffset: NSLayoutConstraint!
    @IBOutlet var topOffset: NSLayoutConstraint!
    @IBOutlet var bottomOffset: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.backgroundColor = UIColor.clear
    }
    
}

extension ActionCell {
    
    func update(withIndex index: Int, layoutConfiguration: LayoutConfiguration) {
        
        let layoutModel = LayoutModel(configuration: layoutConfiguration, assets: 0)
        let actionCount = layoutModel.numberOfItems(in: layoutConfiguration.sectionIndexForActions)
        
        titleLabel.textColor = UIColor.black
        switch index {
        case 0:
            titleLabel.text = "Camera"
            imageView.image = UIImage(named: "button-camera", in: Bundle(for: type(of: self)), compatibleWith: nil)
        case 1:
            titleLabel.text = "Photos"
            imageView.image = UIImage(named: "button-photo-library", in: Bundle(for: type(of: self)), compatibleWith: nil)
        default: break
        }
        
        let isFirst = index == 0
        let isLast = index == actionCount - 1
        
        switch layoutConfiguration.scrollDirection {
        case .horizontal:
            topOffset.constant = isFirst ? 10 : 5
            bottomOffset.constant = isLast ? 10 : 5
            leadingOffset.constant = 5
            trailingOffset.constant = 5
        case .vertical:
            topOffset.constant = 5
            bottomOffset.constant = 5
            leadingOffset.constant = isFirst ? 10 : 5
            trailingOffset.constant = isLast ? 10 : 5
        }
        
    }
    
}
