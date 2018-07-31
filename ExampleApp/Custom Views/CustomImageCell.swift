// Copyright © 2018 INLOOPX. All rights reserved.

import ImagePicker

class CustomImageCell: UICollectionViewCell, ImagePickerAssetCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var subtypeImageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!
    
    var representedAssetIdentifier: String?
    
    override var isSelected: Bool {
        didSet { selectedImageView.isHidden = !isSelected }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        subtypeImageView.backgroundColor = UIColor.clear
        selectedImageView.isHidden = !isSelected
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        subtypeImageView.image = nil
    }
}
