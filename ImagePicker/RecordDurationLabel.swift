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
        layer.masksToBounds = true
        layer.backgroundColor = UIColor(red: 234/255, green: 53/255, blue: 52/255, alpha: 1).cgColor
        layer.frame.size = CGSize(width: 6, height: 6)
        layer.cornerRadius = layer.frame.width/2
        layer.opacity = 0
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        indicatorLayer.position = CGPoint(x: -7, y: bounds.height/2)
    }
    
    // MARK: Public Methods
    
    private var timer: Timer?
    private var backingSeconds: TimeInterval = 0 {
        didSet { updateLabel() }
    }
    
    func start() {
        
        guard timer == nil else {
            return
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
            self?.backingSeconds += 1
        })
        timer?.tolerance = 0.1
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        backingSeconds = 0
    }
    
    // MARK: Private Methods
    
    private func updateLabel() {
        text = RecordDurationLabel.durationFormatter.string(from: backingSeconds)
    }
    
    private func commonInit() {
        layer.addSublayer(indicatorLayer)
        clipsToBounds = false
    }
    
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
