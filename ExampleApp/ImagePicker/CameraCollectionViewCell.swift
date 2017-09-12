//
//  CameraCollectionViewCell.swift
//  ExampleApp
//
//  Created by Peter Stajger on 08/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit

//TODO: not sure if cameraController should be in this cell, we need nicer pattern for this
open class CameraCollectionViewCell : UICollectionViewCell {

    deinit {
        print("deinit: \(self.classForCoder)")
    }
    
    weak var cameraController: UIImagePickerController?
    
    public func flipCamera() {
        guard let controller = cameraController else {
            return
        }
        controller.cameraDevice = (controller.cameraDevice == .rear) ? .front : .rear
    }
    
    public func takePicture() {
        cameraController?.takePicture()
    }
    
    var cameraView: UIView? {
        didSet {
            backgroundView = cameraView
        }
    }
    
}
