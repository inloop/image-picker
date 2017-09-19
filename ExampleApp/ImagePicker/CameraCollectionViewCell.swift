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
        #if DEBUG
            print("deinit: \(String(describing: self))")
        #endif
    }
    
    var previewView = AVPreviewView(frame: .zero)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(previewView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        contentView.addSubview(previewView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        previewView.bounds = bounds
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
