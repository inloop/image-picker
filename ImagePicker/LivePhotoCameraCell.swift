//
//  LivePhotoCameraCell.swift
//  ExampleApp
//
//  Created by Peter Stajger on 25/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit

class LivePhotoCameraCell : CameraCollectionViewCell {
    
    @IBOutlet weak var snapButton: UIButton!
    @IBOutlet weak var enableLivePhotosButton: StationaryButton!
    @IBOutlet weak var liveIndicator: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        liveIndicator.alpha = 0
        enableLivePhotosButton.unselectedTintColor = UIColor.white
        enableLivePhotosButton.selectedTintColor = UIColor(red: 245/255, green: 203/255, blue: 47/255, alpha: 1)
    }
    
    @IBAction func snapButtonTapped(_ sender: UIButton) {
        if enableLivePhotosButton.isSelected {
            takeLivePhoto()
        }
        else {
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
    
    // MARK: Override Methods
    
    override func updateLivePhotoStatus(isProcessing: Bool, shouldAnimate: Bool) {
        
        let updates: () -> Void = {
            self.liveIndicator.alpha = isProcessing ? 1 : 0
        }
        
        shouldAnimate ? UIView.animate(withDuration: 0.25, animations: updates) : updates()
    }

}
