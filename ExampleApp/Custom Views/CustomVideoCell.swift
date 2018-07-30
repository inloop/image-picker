// Copyright © 2018 INLOOPX. All rights reserved.

import ImagePicker

class CustomVideoCell: UICollectionViewCell, ImagePickerAssetCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var representedAssetIdentifier: String?
}
