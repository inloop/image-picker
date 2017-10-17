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

class RecordVideoButton : StationaryButton {
    
    var outerBorderWidth: CGFloat = 6 { didSet { setNeedsUpdateCircleLayers() } }
    var innerBorderWidth: CGFloat = 1.5 { didSet { setNeedsUpdateCircleLayers()  } }
    var pressDepthFactor: CGFloat = 0.9 { didSet { setNeedsUpdateCircleLayers() } }
    
    override var isHighlighted: Bool {
        get { return super.isHighlighted }
        set {
            if isSelected == false && newValue != isHighlighted && newValue == true {
                updateCircleLayers(state: .pressed, animated: true)
            }
            super.isHighlighted = newValue
        }
    }
    
    override func selectionDidChange(animated: Bool) {
        super.selectionDidChange(animated: animated)
        
        if isSelected {
            updateCircleLayers(state: .recording, animated: animated)
        }
        else {
            updateCircleLayers(state: .initial, animated: animated)
        }
    }
    
    private var innerCircleLayerInset: CGFloat {
        return outerBorderWidth + innerBorderWidth
    }
    
    private var needsUpdateCircleLayers = true
    private var outerCircleLayer: CALayer
    private var innerCircleLayer: CALayer
    
    private enum State: String {
        case initial
        case pressed
        case recording
    }
    
    private var layersState: State = .initial
    
    required init?(coder aDecoder: NSCoder) {
        outerCircleLayer = CALayer()
        innerCircleLayer = CALayer()
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        layer.addSublayer(outerCircleLayer)
        layer.addSublayer(innerCircleLayer)
        CATransaction.setDisableActions(true)
        
        outerCircleLayer.backgroundColor = UIColor.clear.cgColor
        outerCircleLayer.cornerRadius = bounds.width/2
        outerCircleLayer.borderWidth = outerBorderWidth
        outerCircleLayer.borderColor = tintColor.cgColor
        
        innerCircleLayer.backgroundColor = UIColor.red.cgColor
        
        CATransaction.commit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if needsUpdateCircleLayers {
            CATransaction.setDisableActions(true)
            outerCircleLayer.frame = bounds
            innerCircleLayer.frame = bounds.insetBy(dx: innerCircleLayerInset, dy: innerCircleLayerInset)
            innerCircleLayer.cornerRadius = bounds.insetBy(dx: innerCircleLayerInset, dy: innerCircleLayerInset).width/2
            needsUpdateCircleLayers = false
            CATransaction.commit()
        }
    }
    
    private func setNeedsUpdateCircleLayers() {
        needsUpdateCircleLayers = true
        setNeedsLayout()
    }
    
    private func updateCircleLayers(state: State, animated: Bool) {
        guard layersState != state else { return }
        
        layersState = state
        
        switch layersState {
        case .initial:
            setInnerLayer(recording: false, animated: animated)
        case .pressed:
            setInnerLayerPressed(animated: animated)
        case .recording:
            setInnerLayer(recording: true, animated: animated)
        }
    }
    
    private func setInnerLayerPressed(animated: Bool) {
        
        if animated {
            innerCircleLayer.add(transformAnimation(to: pressDepthFactor, duration: 0.25), forKey: nil)
        }
        else {
            CATransaction.setDisableActions(true)
            innerCircleLayer.setValue(pressDepthFactor, forKeyPath: "transform.scale")
            CATransaction.commit()
        }
    }
    
    private func setInnerLayer(recording: Bool, animated: Bool) {
        
        if recording {
            innerCircleLayer.add(transformAnimation(to: 0.5, duration: 0.15), forKey: nil)
            innerCircleLayer.cornerRadius = 8
        }
        else {
            innerCircleLayer.add(transformAnimation(to: 1, duration: 0.25), forKey: nil)
            innerCircleLayer.cornerRadius = bounds.insetBy(dx: innerCircleLayerInset, dy: innerCircleLayerInset).width/2
        }
        
    }
    
    private func transformAnimation(to value: CGFloat, duration: CFTimeInterval) -> CAAnimation {
        let animation = CABasicAnimation()
        animation.keyPath = "transform.scale"
        animation.fromValue = innerCircleLayer.presentation()?.value(forKeyPath: "transform.scale")
        animation.toValue = value
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.beginTime = CACurrentMediaTime()
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        return animation
    }
    
}

class VideoCameraCell : CameraCollectionViewCell {
    
    @IBOutlet weak var recordButton: RecordVideoButton!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var recIndicator: UILabel!
    @IBOutlet weak var stateView: StateView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        recIndicator.alpha = 0
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
