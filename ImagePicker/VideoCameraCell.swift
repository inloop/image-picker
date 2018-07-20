// Copyright © 2018 INLOOPX. All rights reserved.

import Foundation

//TODO: add a recording indicator (red dot with timer)
final class VideoCameraCell: CameraCollectionViewCell {
    @IBOutlet weak var recordLabel: RecordDurationLabel!
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
        } else {
            startVideoRecording()
        }
    }
    
    @IBAction func flipButtonTapped(_ sender: UIButton) {
        flipCamera()
    }
    
    override func updateRecordingVideoStatus(isRecording: Bool, shouldAnimate: Bool) {
        recordButton.isSelected = isRecording
        isRecording ? recordLabel.start() : recordLabel.stop()
        
        let updates = { self.flipButton.alpha = isRecording ? 0 : 1 }
        shouldAnimate ? UIView.animate(withDuration: 0.25, animations: updates) : updates()
    }
    
    override func videoRecodingDidBecomeReady() {
        recordButton.isEnabled = true
        UIView.animate(withDuration: 0.25) {
            self.recordButton.alpha = 1.0
        }
    }
}
