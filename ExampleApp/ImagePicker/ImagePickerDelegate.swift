//
//  ImagePickerDelegate.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

/// Informs a delegate what is going on in ImagePickerDelegate
protocol ImagePickerDelegateDelegate : class {
    
    /// Called when user selects one of action items
    func imagePicker(delegate: ImagePickerDelegate, didSelectActionItemAt index: Int)
    
    /// Called when user selects one of asset items
    func imagePicker(delegate: ImagePickerDelegate, didSelectAssetItemAt index: Int)
    
    /// Called when action item is about to be displayed
    func imagePicker(delegate: ImagePickerDelegate, willDisplayActionCell cell: UICollectionViewCell, at index: Int)
    
    /// Called when camera item is about to be displayed
    func imagePicker(delegate: ImagePickerDelegate, willDisplayCameraCell cell: CameraCollectionViewCell)
    
    /// Called when camera item ended displaying
    func imagePicker(delegate: ImagePickerDelegate, didEndDisplayingCameraCell cell: CameraCollectionViewCell)
    
    func imagePicker(delegate: ImagePickerDelegate, willDisplayAssetCell cell: ImagePickerAssetCell, at index: Int)
    //func imagePicker(delegate: ImagePickerDelegate, didEndDisplayingAssetCell cell: ImagePickerAssetCell)
}

//TODO:
//- [ok] remove all !
//- remove explicit knowledge of what sectionas are at awhat indexes, this should be hardcoded only 
//  at one place and that is LayoutModel, delegate shold not have this duplicit logic
final class ImagePickerDelegate : NSObject, UICollectionViewDelegateFlowLayout {
    
    var layout: ImagePickerLayout?
    weak var delegate: ImagePickerDelegateDelegate?
    
    private let selectionPolicy = ImagePickerSelectionPolicy()
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return layout?.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath) ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return layout?.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: section) ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            delegate?.imagePicker(delegate: self, didSelectAssetItemAt: indexPath.row)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return selectionPolicy.shouldSelectItem(atSection: indexPath.section)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return selectionPolicy.shouldHighlightItem(atSection: indexPath.section)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            delegate?.imagePicker(delegate: self, didSelectActionItemAt: indexPath.row)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0: delegate?.imagePicker(delegate: self, willDisplayActionCell: cell, at: indexPath.row)
        case 1: delegate?.imagePicker(delegate: self, willDisplayCameraCell: cell as! CameraCollectionViewCell)
        case 2: delegate?.imagePicker(delegate: self, willDisplayAssetCell: cell as! ImagePickerAssetCell, at: indexPath.row)
        default: fatalError("index path not supported")
        }
    }
 
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1: delegate?.imagePicker(delegate: self, didEndDisplayingCameraCell: cell as! CameraCollectionViewCell)
        case 0,2: break
        default: fatalError("index path not supported")
        }
    }
    
}
