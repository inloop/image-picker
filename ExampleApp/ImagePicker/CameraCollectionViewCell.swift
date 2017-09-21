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
    
    // MARK: Camera API
    
    weak var delegate: CameraCollectionViewCellDelegate?
    
    public func flipCamera() {
        delegate?.flipCamera()
    }
    
    public func takePicture() {
        delegate?.takePicture()
    }
    
}
