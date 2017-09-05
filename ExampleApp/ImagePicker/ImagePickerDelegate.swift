//
//  ImagePickerDelegate.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

final class ImagePickerDelegate : NSObject, UICollectionViewDelegateFlowLayout {
    
    var layout: ImagePickerLayout?
        
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return layout?.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath) ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return layout?.collectionView(collectionView, layout: collectionViewLayout, insetForSectionAt: section) ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let rows = (collectionView.indexPathsForSelectedItems ?? []).map { $0.row }
        print("selected \(rows)")
    }
    
}
