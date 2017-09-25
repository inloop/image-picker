//
//  CameraView.swift
//  ExampleApp
//
//  Created by Peter Stajger on 08/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit
import ImagePicker

class CameraCell : CameraCollectionViewCell {
    
    @IBOutlet weak var snapButton: UIButton!
    @IBOutlet weak var flipButton: UIButton!
    
    @IBAction func snapButtonTapped(_ sender: UIButton) {
        //takePicture()
        takeLivePhoto()
    }
    
    @IBAction func flipButtonTapped(_ sender: UIButton) {
        flipCamera(nil)
    }
    
}
