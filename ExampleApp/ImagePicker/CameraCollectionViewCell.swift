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

//TODO: not sure if cameraController should be in this cell, we need nicer pattern for this
open class CameraCollectionViewCell : UICollectionViewCell {

    deinit {
        print("deinit: \(self.classForCoder)")
    }
    
    weak var delegate: CameraCollectionViewCellDelegate?
    
    public func flipCamera() {
        delegate?.flipCamera()
    }
    
    public func takePicture() {
        delegate?.takePicture()
    }
    
    var cameraView: UIView? {
        didSet {
            backgroundView = cameraView
        }
    }
    
}
