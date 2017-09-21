//
//  CameraCollectionViewCell.swift
//  ExampleApp
//
//  Created by Peter Stajger on 08/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit

protocol CameraCollectionViewCellDelegate : class {
    func takePicture()
    func flipCamera()
}

open class CameraCollectionViewCell : UICollectionViewCell {

    deinit {
        log("deinit: \(String(describing: self))")
    }
    
    /// contains video preview layer
    internal var previewView = AVPreviewView(frame: .zero)
    
    /// visual view that is blurring preview view
    internal var blurView: UIVisualEffectView = {
       let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.isHidden = true
        return view
    }()
    
    ///
    /// holds static image that is above blur view to achieve nicer presentation
    /// - note: when capture session is interrupted, there is no input stream so
    /// output is black, adding image here will nicely hide this black background
    ///
    internal var imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundView = previewView
        previewView.addSubview(imageView)
        previewView.addSubview(blurView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundView = previewView
        previewView.addSubview(imageView)
        previewView.addSubview(blurView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = previewView.bounds
        blurView.frame = previewView.bounds
    }
    
    // MARK: Internal Methods
    
    func blurIfNeeded(blurImage: UIImage?, animated: Bool) {
        
        guard blurView.isHidden == true else {
            return
        }
        
        imageView.alpha = 0
        imageView.image = blurImage
        
        if animated == false {
            imageView.alpha = 1
            blurView.alpha = 1
            blurView.isHidden = false
        }
        else {
            UIView.animate(withDuration: 0.25, delay: 0, options: .allowAnimatedContent, animations: {
                self.imageView.alpha = 1
                self.blurView.alpha = 1
            }, completion: { (finished) in
                self.blurView.isHidden = false
            })
        }
        
    }
    
    func unblurIfNeeded(blurImage: UIImage?, animated: Bool) {
        
        guard blurView.isHidden == false else {
            return
        }
        
        if animated == false {
            blurView.alpha = 0
            imageView.alpha = 0
            blurView.isHidden = true
            imageView.image = nil
        }
        else {
            
            UIView.animate(withDuration: 0.25, delay: 0, options: .allowAnimatedContent, animations: {
                self.blurView.alpha = 0
                self.imageView.alpha = 0
            }, completion: { (finished) in
                self.blurView.isHidden = true
                self.imageView.image = nil
            })
        }
    }
    
    // MARK: Camera API
    
    weak var delegate: CameraCollectionViewCellDelegate?
    
    public func flipCamera() {
        delegate?.flipCamera()
    }
    
    public func takePicture() {
        delegate?.takePicture()
    }
    
}
