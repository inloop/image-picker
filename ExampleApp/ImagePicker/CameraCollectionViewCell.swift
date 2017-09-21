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
    
    internal var previewView = AVPreviewView(frame: .zero)
    
    internal var blurView: UIVisualEffectView = {
       let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.isHidden = true
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundView = previewView
        previewView.addSubview(blurView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundView = previewView
        previewView.addSubview(blurView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
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
