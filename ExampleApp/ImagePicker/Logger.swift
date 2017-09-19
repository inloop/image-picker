//
//  Logger.swift
//  ImagePicker
//
//  Created by Peter Stajger on 19/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

func log(_ message: String) {
    #if DEBUG
        print(message)
    #endif
}
