// Copyright © 2018 INLOOPX. All rights reserved.

import Foundation

/// Label that can be used to show duration during recording or just any duration in general.

final class RecordDurationLabel: UILabel {
    private var indicatorLayer = CALayer()
    private let disappearDelay: CFTimeInterval = 0.25
    private var secondTimer: Timer?
    private var indicatorTimer: Timer?
    private var backingSeconds: TimeInterval = 10000 {
        didSet {
            updateLabel()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeViews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        indicatorLayer.position = CGPoint(x: -7, y: bounds.height/2)
    }

    func start() {
        guard secondTimer == nil else { return }
        
        secondTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
            self?.backingSeconds += 1
        })
        secondTimer?.tolerance = 0.1
        
        indicatorTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in
            self?.updateIndicator(appearDelay: 0.2)
        })
        indicatorTimer?.tolerance = 0.1
        
        updateIndicator()
    }
    
    func stop() {
        secondTimer?.invalidate()
        secondTimer = nil
        backingSeconds = 0
        updateLabel()
        
        indicatorTimer?.invalidate()
        indicatorTimer = nil
        indicatorLayer.removeAllAnimations()
        indicatorLayer.opacity = 0
    }
    
    private func initializeViews() {
        indicatorLayer.masksToBounds = true
        indicatorLayer.backgroundColor = UIColor(red: 234/255, green: 53/255, blue: 52/255, alpha: 1).cgColor
        indicatorLayer.frame.size = CGSize(width: 6, height: 6)
        indicatorLayer.cornerRadius = layer.frame.width / 2
        indicatorLayer.opacity = 0
        layer.addSublayer(indicatorLayer)
        clipsToBounds = false
    }
    
    private func updateLabel() {
        // we are not using DateComponentsFormatter because it does not pad zero to hours component
        // so it regurns pattern 0:00:00, we need 00:00:00
        let hours = Int(backingSeconds) / 3600
        let minutes = Int(backingSeconds) / 60 % 60
        let seconds = Int(backingSeconds) % 60
        text = String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    private func updateIndicator(appearDelay: CFTimeInterval = 0) {
        let appear = appearAnimation(delay: appearDelay)
        let disappear = disappearAnimation(delay: appear.beginTime + appear.duration + disappearDelay)
        
        let animation = CAAnimationGroup()
        animation.animations = [appear, disappear]
        animation.duration = appear.duration + disappear.duration + appearDelay + disappearDelay
        animation.isRemovedOnCompletion = true
        indicatorLayer.add(animation, forKey: "blinkAnimationKey")
    }

    private func appearAnimation(delay: CFTimeInterval = 0) -> CAAnimation {
        let appear = CABasicAnimation(keyPath: "opacity")
        appear.fromValue = indicatorLayer.presentation()?.opacity
        appear.toValue = 1
        appear.duration = 0.15
        appear.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        appear.beginTime = delay
        appear.fillMode = CAMediaTimingFillMode.forwards
        
        return appear
    }
    
    private func disappearAnimation(delay: CFTimeInterval = 0) -> CAAnimation {
        let disappear = CABasicAnimation(keyPath: "opacity")
        disappear.fromValue = indicatorLayer.presentation()?.opacity
        disappear.toValue = 0
        disappear.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        disappear.beginTime = delay
        disappear.duration = 0.25
        
        return disappear
    }
}
