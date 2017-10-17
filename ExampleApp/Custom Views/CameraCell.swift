//
//  CameraView.swift
//  ExampleApp
//
//  Created by Peter Stajger on 08/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit
import ImagePicker

class ShutterButton : UIButton {
    
    var outerBorderWidth: CGFloat = 3
    var innerBorderWidth: CGFloat = 1.5
    var pressDepthFactor: CGFloat = 0.9
    
    override var isHighlighted: Bool {
        didSet { setInnerLayer(tapped: isHighlighted, animated: true) }
    }
    
    private var innerCircleLayerInset: CGFloat {
        return outerBorderWidth + innerBorderWidth
    }
    
    private var outerCircleLayer: CALayer
    private var innerCircleLayer: CALayer
    
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
        
        innerCircleLayer.backgroundColor = tintColor.cgColor
        
        CATransaction.commit()
    }
    
    func setInnerLayer(tapped: Bool, animated: Bool) {
        
        if animated {
            let animation = CABasicAnimation()
            animation.keyPath = "transform.scale"
            
            if tapped {
                animation.fromValue = innerCircleLayer.presentation()?.value(forKeyPath: "transform.scale")
                animation.toValue = pressDepthFactor
                animation.duration = 0.25
            }
            else {
                animation.fromValue = pressDepthFactor
                animation.toValue = 1.0
                animation.duration = 0.25
            }
            
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            animation.beginTime = CACurrentMediaTime()
            animation.fillMode = kCAFillModeForwards
            animation.isRemovedOnCompletion = false
            
            innerCircleLayer.add(animation, forKey: nil)
        }
        else {
            CATransaction.setDisableActions(true)
            if tapped {
                innerCircleLayer.setValue(pressDepthFactor, forKeyPath: "transform.scale")
            }
            else {
                innerCircleLayer.setValue(CGFloat(1), forKeyPath: "transform.scale")
            }
            CATransaction.commit()
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.setDisableActions(true)
        outerCircleLayer.frame = bounds
        innerCircleLayer.frame = bounds.insetBy(dx: innerCircleLayerInset, dy: innerCircleLayerInset)
        innerCircleLayer.cornerRadius = bounds.insetBy(dx: innerCircleLayerInset, dy: innerCircleLayerInset).width/2
        CATransaction.commit()
    }
    
}

class CameraCell : CameraCollectionViewCell {
    
    @IBOutlet weak var snapButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    
    @IBAction func snapButtonTapped(_ sender: UIButton) {
        takePicture()
    }
    
    @IBAction func flipButtonTapped(_ sender: UIButton) {
        flipCamera()
    }
    
}
