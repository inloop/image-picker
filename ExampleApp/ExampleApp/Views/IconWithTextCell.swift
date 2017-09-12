//
//  IconWithTextCell.swift
//  ExampleApp
//
//  Created by Peter Stajger on 06/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit

//example of action cell that can be used by ImagePickerViewController
class IconWithTextCell : UICollectionViewCell {
    
    deinit {
        print("deinit: \(self.classForCoder)")
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    private var originalBackgroundColor: UIColor?
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UIColor.red
            }
            else {
                backgroundColor = originalBackgroundColor
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        originalBackgroundColor = backgroundColor
        imageView.backgroundColor = UIColor.clear
    }
    
}
