//
//  LivePhotoCameraCell.swift
//  ExampleApp
//
//  Created by Peter Stajger on 25/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit

class VideoCameraCell : CameraCollectionViewCell {
    
    @IBOutlet weak var recordButton: RecordVideoButton!
    @IBOutlet weak var flipButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        recordButton.isEnabled = false
        recordButton.alpha = 0.5
    }
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        if sender.isSelected {
            stopVideoRecording()
        }
        else {
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
    
}
