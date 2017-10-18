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
        liveIndicator.layer.cornerRadius = 2
        liveIndicator.layer.masksToBounds = true
        liveIndicator.textColor = liveIndicator.backgroundColor
        
        //TODO: we need to do text layer reversed, it appears that best way is to
        //render in image mask using core graphics
        let textMask = CATextLayer()
        textMask.contentsScale = UIScreen.main.scale
        textMask.frame = liveIndicator.bounds
        textMask.foregroundColor = UIColor.white.cgColor
        textMask.string = "Live"
        textMask.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize, weight: .medium)
        textMask.fontSize = UIFont.smallSystemFontSize
        textMask.alignmentMode = kCAAlignmentCenter
        liveIndicator.layer.mask = textMask
        
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
