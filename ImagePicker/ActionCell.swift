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
    @IBOutlet var topOffset: NSLayoutConstraint!
    @IBOutlet var bottomOffset: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.backgroundColor = UIColor.clear
    }
    
}

extension ActionCell {
    
    func update(withIndex index: Int, outOf: Int) {
        
        titleLabel.textColor = UIColor.black
        switch index {
        case 0:
            titleLabel.text = "Camera"
            imageView.image = #imageLiteral(resourceName: "button-camera")
        case 1:
            titleLabel.text = "Photos"
            imageView.image = #imageLiteral(resourceName: "button-photo-library")
        default: break
        }
        
        let isFirst = index == 0
        topOffset.constant = isFirst ? 10 : 5
        
        let isLast = index == outOf - 1
        bottomOffset.constant = isLast ? 10 : 5
    }
    
}
