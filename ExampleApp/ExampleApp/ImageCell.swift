//
//  ImageCell.swift
//  ExampleApp
//
//  Created by Peter Stajger on 07/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit
import ImagePicker

class ImageCell : UICollectionViewCell, ImagePickerImageCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var selectedImageView: UIImageView!
    
    override var isSelected: Bool {
        didSet {
            selectedImageView.isHidden = !isSelected
        }
    }
    
    override func prepareForReuse() {
        imageView.image = nil
    }
    
}
