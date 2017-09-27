//
//  CameraCollectionViewCell.swift
//  ExampleApp
//
//  Created by Peter Stajger on 08/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol CameraCollectionViewCellDelegate : class {
    func takePicture()
    func takeLivePhoto()
    func flipCamera(_ completion: (() -> Void)?)
}

///
/// Each custom camera cell must inherit from this base class.
///
open class CameraCollectionViewCell : UICollectionViewCell {

    deinit {
        log("deinit: \(String(describing: self))")
    }
    
    /// contains video preview layer
    var previewView = AVPreviewView(frame: .zero)
    
    ///
    /// holds static image that is above blur view to achieve nicer presentation
    /// - note: when capture session is interrupted, there is no input stream so
    /// output is black, adding image here will nicely hide this black background
    ///
    var imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    weak var delegate: CameraCollectionViewCellDelegate?
    
    // MARK: View Lifecycle Methods
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundView = previewView
        previewView.addSubview(imageView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundView = previewView
        previewView.addSubview(imageView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = previewView.bounds
    }
    
    // MARK: Public Methods
    
    /// The cell can have multiple visual states based on autorization status
    public internal(set) var authorizationStatus: AVAuthorizationStatus? {
        didSet { updateCameraAuthorizationStatus() }
    }
    
    open func updateCameraAuthorizationStatus() {
        
    }
    
    open func updateLivePhotoStatus(isProcessing: Bool, shouldAnimate: Bool) {
        
    }
    
    public func flipCamera(_ completion: (() -> Void)?) {
        delegate?.flipCamera(completion)
    }
    
    public func takePicture() {
        delegate?.takePicture()
    }
    
    public func takeLivePhoto() {
        delegate?.takeLivePhoto()
    }
    
    // MARK: Internal Methods
    
    func blurIfNeeded(blurImage: UIImage?, animated: Bool, completion: ((Bool) -> Void)?) {
        
        guard imageView.image == nil else {
            return
        }
        
        imageView.alpha = 0
        imageView.image = blurImage

        if animated == false {
            imageView.alpha = 1
            completion?(true)
        }
        else {
            UIView.animate(withDuration: 0.1, delay: 0, options: .allowAnimatedContent, animations: {
                self.imageView.alpha = 1
            }, completion: completion)
        }
    }
    
    func unblurIfNeeded(unblurImage: UIImage?, animated: Bool, completion: ((Bool) -> Void)?) {
        
        guard imageView.image != nil else {
            return
        }

        if animated == false {
            imageView.alpha = 0
            imageView.image = nil
            completion?(true)
        }
        else {
            
            if let image = unblurImage {
                imageView.image = image
            }
            
            UIView.animate(withDuration: 0.1, delay: 0, options: .allowAnimatedContent, animations: {
                self.imageView.alpha = 0
            }, completion: { (finished) in
                self.imageView.image = nil
                completion?(finished)
            })
        }
    }
    
    func touchIsCaptureEffective(point: CGPoint) -> Bool {
        // find the topmost view that detected the touch at point and check if it's not any button or anything other than contentView
        if bounds.contains(point), let testedView = hitTest(point, with: nil), testedView === contentView {
            return true
        }
        return false
    }
 
    
}
