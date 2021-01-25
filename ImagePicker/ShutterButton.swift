// Copyright © 2018 INLOOPX. All rights reserved.

import Foundation

/// A rounded button that has a circle inside and is used when taking pictures.

final class ShutterButton: UIButton {
    override var isHighlighted: Bool {
        didSet { setInnerLayer(tapped: isHighlighted, animated: true) }
    }
    
    private var outerBorderWidth: CGFloat = 3
    private var innerBorderWidth: CGFloat = 1.5
    private var pressDepthFactor: CGFloat = 0.9
    private var innerCircleLayerInset: CGFloat { return outerBorderWidth + innerBorderWidth }
    private var outerCircleLayer = CALayer()
    private var innerCircleLayer = CALayer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeViews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.setDisableActions(true)
        outerCircleLayer.frame = bounds
        innerCircleLayer.frame = bounds.insetBy(dx: innerCircleLayerInset, dy: innerCircleLayerInset)
        innerCircleLayer.cornerRadius = bounds.insetBy(dx: innerCircleLayerInset, dy: innerCircleLayerInset).width/2
        CATransaction.commit()
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
        innerCircleLayer.backgroundColor = tintColor.cgColor
        CATransaction.commit()
    }
    
    private func setInnerLayer(tapped: Bool, animated: Bool) {
        if animated {
            let animation = createInnerLayerAnimation(tapped: tapped)
            innerCircleLayer.add(animation, forKey: nil)
        } else {
            let value = tapped ? pressDepthFactor : 1
            CATransaction.setDisableActions(true)
            innerCircleLayer.setValue(value, forKeyPath: "transform.scale")
            CATransaction.commit()
        }
    }
    
    private func createInnerLayerAnimation(tapped: Bool) -> CABasicAnimation{
        let animation = CABasicAnimation()
        animation.keyPath = "transform.scale"
        
        if tapped {
            animation.fromValue = innerCircleLayer.presentation()?.value(forKeyPath: "transform.scale")
            animation.toValue = pressDepthFactor
            animation.duration = 0.25
        } else {
            animation.fromValue = pressDepthFactor
            animation.toValue = 1.0
            animation.duration = 0.25
        }
        
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        animation.beginTime = CACurrentMediaTime()
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        
        return animation
    }
}
