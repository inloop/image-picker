//
//  LayoutConfiguration.swift
//  Image Picker
//
//  Created by Peter Stajger on 05/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

///
/// A helper struct that is used by ImagePickerLayout when configuring and laying out
/// collection view items.
///
public struct LayoutConfiguration {
    
    public var showsFirstActionItem = true
    public var showsSecondActionItem = true
 
    public var showsCameraItem = true
    
    let showsAssetItems = true
    
    ///
    /// Scroll and layout direction
    ///
    public var scrollDirection: UICollectionViewScrollDirection = .horizontal
    
    ///
    /// Defines how many image assets will be in a row. Must be > 0
    ///
    public var numberOfAssetItemsInRow: Int = 2
    
    ///
    /// Spacing between items within a section
    ///
    public var interitemSpacing: CGFloat = 1
    
    ///
    /// Spacing between actions section and camera section
    ///
    public var actionSectionSpacing: CGFloat = 1
    
    ///
    /// Spacing between camera section and assets section
    ///
    public var cameraSectionSpacing: CGFloat = 10
}

extension LayoutConfiguration {
    
    var hasAnyAction: Bool {
        return showsFirstActionItem || showsSecondActionItem
    }
    
    var sectionIndexForActions: Int {
        return 0
    }
    
    var sectionIndexForCamera: Int {
        return 1
    }
    
    var sectionIndexForAssets: Int {
        return 2
    }
    
    public static var `default` = LayoutConfiguration()
    
}

extension UICollectionView {
    
    /// Helper method for convenienet access to camera cell
    func cameraCell(layout: LayoutConfiguration) -> CameraCollectionViewCell? {
        return cellForItem(at: IndexPath(row: 0, section: layout.sectionIndexForCamera)) as? CameraCollectionViewCell
    }
    
}
