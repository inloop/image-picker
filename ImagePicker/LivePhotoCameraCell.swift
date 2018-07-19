// Copyright © 2018 INLOOPX. All rights reserved.

import Foundation

final class LivePhotoCameraCell: CameraCollectionViewCell {
    @IBOutlet weak var snapButton: UIButton!
    @IBOutlet weak var enableLivePhotosButton: StationaryButton!
    @IBOutlet weak var liveIndicator: CarvedLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        liveIndicator.alpha = 0
        liveIndicator.tintColor = UIColor(red: 245/255, green: 203/255, blue: 47/255, alpha: 1)
        
        enableLivePhotosButton.unselectedTintColor = .white
        enableLivePhotosButton.selectedTintColor = UIColor(red: 245/255, green: 203/255, blue: 47/255, alpha: 1)
    }
    
    @IBAction func snapButtonTapped(_ sender: UIButton) {
        if enableLivePhotosButton.isSelected {
            takeLivePhoto()
        } else {
            takePicture()
        }
    }
    
    @IBAction func flipButtonTapped(_ sender: UIButton) {
        flipCamera()
    }
    
    func updateWithCameraMode(_ mode: CaptureSettings.CameraMode) {
        switch mode {
        case .photo:
            liveIndicator.isHidden = true
            enableLivePhotosButton.isHidden = true
        case .photoAndLivePhoto:
            liveIndicator.isHidden = false
            enableLivePhotosButton.isHidden = false
        default:
            fatalError("Image Picker - unsupported camera mode for \(type(of: self))")
        }
    }
    
    override func updateLivePhotoStatus(isProcessing: Bool, shouldAnimate: Bool) {
        let updates = {
            self.liveIndicator.alpha = isProcessing ? 1 : 0
        }
        
        if shouldAnimate {
            UIView.animate(withDuration: 0.25, animations: updates)
        } else {
            updates()
        }
    }
}
