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
}

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
        let rows = (collectionView.indexPathsForSelectedItems ?? []).map { $0.row }
        print("selected \(rows)")
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
        print("highlighted \(indexPath)")
        if indexPath.section == 0 {
            delegate?.imagePicker(delegate: self, didSelectActionItemAt: indexPath.row)
        }
        
    }
    
}
