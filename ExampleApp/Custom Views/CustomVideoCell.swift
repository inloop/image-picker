//
//  VideoCell.swift
//  ExampleApp
//
//  Created by Peter Stajger on 11/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import UIKit
import ImagePicker

class CustomVideoCell: UICollectionViewCell, ImagePickerAssetCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var representedAssetIdentifier: String?
    
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
