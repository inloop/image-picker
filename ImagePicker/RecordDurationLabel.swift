//
//  RecordDurationLabel.swift
//  ImagePicker
//
//  Created by Peter Stajger on 25/10/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import UIKit

///
/// Label that can be used to show duration during recording or just any
/// duration in general.
///
final class RecordDurationLabel : UILabel {

    private static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    private var indicatorLayer: CALayer = {
        let layer = CALayer()
        layer.backgroundColor = UIColor(red: 234/255, green: 53/255, blue: 52/255, alpha: 1).cgColor
        layer.masksToBounds = true
        layer.cornerRadius = layer.frame.width/2
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(indicatorLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.addSublayer(indicatorLayer)
    }
    
    // MARK: Public Methods
    
    
    
    // MARK: Private Methods
    
    private func fadeAnimation(fromValue: CGFloat, toValue: CGFloat, duration: CFTimeInterval) -> CAAnimation {
        let animation = CABasicAnimation()
        animation.keyPath = "opacity"
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        animation.beginTime = CACurrentMediaTime()
        animation.fillMode = kCAFillModeForwards
        animation.isRemovedOnCompletion = false
        return animation
    }
    
}
