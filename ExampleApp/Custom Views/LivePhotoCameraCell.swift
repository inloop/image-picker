//
//  LivePhotoCameraCell.swift
//  ExampleApp
//
//  Created by Peter Stajger on 25/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit
import ImagePicker

class StateView : UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
}

class LivePhotoCameraCell : CameraCollectionViewCell {
    
    @IBOutlet weak var snapButton: UIButton!
    //@IBOutlet weak var enableLivePhotosButton: StationaryButton!
    @IBOutlet weak var liveIndicator: UILabel!
    @IBOutlet weak var stateView: StateView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        liveIndicator.alpha = 0
        //enableLivePhotosButton.unselectedTintColor = UIColor.white
        //enableLivePhotosButton.selectedTintColor = UIColor.yellow
    }
    
    @IBAction func snapButtonTapped(_ sender: UIButton) {
//        if enableLivePhotosButton.isSelected {
//            takeLivePhoto()
//        }
//        else {
//            takePicture()
//        }
    }
    
    @IBAction func flipButtonTapped(_ sender: UIButton) {
        flipCamera()
    }
    
    // MARK: Override Methods
    
    override func updateLivePhotoStatus(isProcessing: Bool, shouldAnimate: Bool) {
        
        let updates: () -> Void = {
            self.liveIndicator.alpha = isProcessing ? 1 : 0
        }
        
        shouldAnimate ? UIView.animate(withDuration: 0.25, animations: updates) : updates()
    }
    
    override func updateCameraAuthorizationStatus() {
        switch authorizationStatus! {
        case .authorized:
            stateView.isHidden = true
        case .denied:
            stateView.isHidden = false
            stateView.titleLabel.text = "Denied"
            stateView.subtitleLabel.text = ""
        case .restricted:
            stateView.isHidden = false
            stateView.titleLabel.text = "Restricted"
            stateView.subtitleLabel.text = ""
        case .notDetermined:
            stateView.isHidden = false
            stateView.titleLabel.text = "Grant Access"
            stateView.subtitleLabel.text = ""
        }
    }
}
