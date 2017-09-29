//
//  ImagePickerSelectionPolicy.swift
//  Image Picker
//
//  Created by Peter Stajger on 06/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

///
/// Helper class that determines which cells are selected, multiple selected or
/// highlighted.
///
/// We allow selecting only asset items, action items are only highlighted,
/// camera item is untouched.
///
struct ImagePickerSelectionPolicy {
    
    //TODO: this logic here is hardcoded (secon indexes), there should be a layout model instance
    //and ti should be used to dermine what section is what index
    
    func shouldSelectItem(atSection section: Int, layoutConfiguration: LayoutConfiguration) -> Bool {
        switch section {
        case 0, 1:
            return false
        default:
            return true
        }
    }
    
    func shouldHighlightItem(atSection section: Int, layoutConfiguration: LayoutConfiguration) -> Bool {
        switch section {
        case 1:
            return false
        default:
            return true
        }
    }
    
}
