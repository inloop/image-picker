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

class VideoCameraCell : CameraCollectionViewCell {
    
    @IBOutlet weak var recordButton: StationaryButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var recIndicator: UILabel!
    @IBOutlet weak var stateView: StateView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        recIndicator.alpha = 0
        recordButton.unselectedTintColor = UIColor.red
        recordButton.selectedTintColor = UIColor.white
        recordButton.isEnabled = false
        recordButton.alpha = 0.5
    }
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        if sender.isSelected {
            print("should stop recording")
            stopVideoRecording()
        }
        else {
            print("should start recording")
            startVideoRecording()
        }
    }
    
    @IBAction func flipButtonTapped(_ sender: UIButton) {
        flipCamera()
    }
    
    // MARK: Override Methods
    
    override func updateRecordingVideoStatus(isRecording: Bool, shouldAnimate: Bool) {

        //update button state
        recordButton.isSelected = isRecording
        
        //update other buttons
        let updates: () -> Void = {
            self.recIndicator.alpha = isRecording ? 1 : 0
            self.flipButton.alpha = isRecording ? 0 : 1
        }

        shouldAnimate ? UIView.animate(withDuration: 0.25, animations: updates) : updates()
    }
    
    override func videoRecodingDidBecomeReady() {
        recordButton.isEnabled = true
        UIView.animate(withDuration: 0.25) {
            self.recordButton.alpha = 1.0
        }
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
