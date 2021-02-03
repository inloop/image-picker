// Copyright © 2018 INLOOPX. All rights reserved.

import UIKit

/// A rounded button with 2 circles where middle circle animates based on 3 states - initial, pressed, recording.

final class RecordVideoButton: StationaryButton {
    override var isHighlighted: Bool {
        get { return super.isHighlighted }
        set {
            if isSelected == false && newValue == true && newValue != isHighlighted {
                updateCircleLayers(state: .pressed, animated: true)
            }
            super.isHighlighted = newValue
        }
    }
    
    private enum State: String {
        case initial
        case pressed
        case recording
    }
    
    private var outerBorderWidth: CGFloat = 3 { didSet { setNeedsUpdateCircleLayers() }}
    private var innerBorderWidth: CGFloat = 1.5 { didSet { setNeedsUpdateCircleLayers() }}
    private var pressDepthFactor: CGFloat = 0.9 { didSet { setNeedsUpdateCircleLayers() }}
    private var needsUpdateCircleLayers = true
    private var outerCircleLayer = CALayer()
    private var innerCircleLayer = CALayer()
    private var innerCircleLayerInset: CGFloat { return outerBorderWidth + innerBorderWidth }
    private var layersState = State.initial
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeViews()
    }
    
    override func selectionDidChange(animated: Bool) {
        super.selectionDidChange(animated: animated)

        if isSelected {
            updateCircleLayers(state: .recording, animated: animated)
        } else {
            updateCircleLayers(state: .initial, animated: animated)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if needsUpdateCircleLayers {
            CATransaction.setDisableActions(true)
            outerCircleLayer.frame = bounds
            innerCircleLayer.frame = bounds.insetBy(dx: innerCircleLayerInset, dy: innerCircleLayerInset)
            innerCircleLayer.cornerRadius = bounds.insetBy(dx: innerCircleLayerInset, dy: innerCircleLayerInset).width / 2
            needsUpdateCircleLayers = false
            CATransaction.commit()
        }
    }
    
    private func initializeViews() {
        backgroundColor = .clear
        layer.addSublayer(outerCircleLayer)
        layer.addSublayer(innerCircleLayer)
        
        CATransaction.setDisableActions(true)
        outerCircleLayer.backgroundColor = UIColor.clear.cgColor
        outerCircleLayer.cornerRadius = bounds.width / 2
        outerCircleLayer.borderWidth = outerBorderWidth
        outerCircleLayer.borderColor = tintColor.cgColor
        innerCircleLayer.backgroundColor = UIColor.red.cgColor
        CATransaction.commit()
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
        } else {
            CATransaction.setDisableActions(true)
            innerCircleLayer.setValue(pressDepthFactor, forKeyPath: "transform.scale")
            CATransaction.commit()
        }
    }
    
    private func setInnerLayer(recording: Bool, animated: Bool) {
        if recording {
            innerCircleLayer.add(transformAnimation(to: 0.5, duration: 0.15), forKey: nil)
            innerCircleLayer.cornerRadius = 8
        } else {
            innerCircleLayer.add(transformAnimation(to: 1, duration: 0.25), forKey: nil)
            innerCircleLayer.cornerRadius = bounds.insetBy(dx: innerCircleLayerInset, dy: innerCircleLayerInset).width / 2
        }
    }
    
    private func transformAnimation(to value: CGFloat, duration: CFTimeInterval) -> CAAnimation {
        let animation = CABasicAnimation()
        animation.keyPath = "transform.scale"
        animation.fromValue = innerCircleLayer.presentation()?.value(forKeyPath: "transform.scale")
        animation.toValue = value
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.beginTime = CACurrentMediaTime()
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        return animation
    }
}
