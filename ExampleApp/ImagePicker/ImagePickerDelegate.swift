//
//  ImagePickerDelegate.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

struct LayoutConfiguration {
    
    var showsFirstActionItem = true
    var showsSecondActionItem = true
    var showsCameraActionItem = true
    let showsAssetItems = true
    
    var hasAnyAction: Bool {
        return showsFirstActionItem || showsSecondActionItem
    }
    
    var interitemSpacing: CGFloat = 1
    
    static var defaultConfiguration = LayoutConfiguration(
        showsFirstActionItem: true,
        showsSecondActionItem: true,
        showsCameraActionItem: true,
        interitemSpacing: 2
    )
}

final class ImagePickerDelegate : NSObject, UICollectionViewDelegateFlowLayout {
    
    var layoutConfiguration = LayoutConfiguration()
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        func sizeForItemInRow(numberOfItemsInRow: Int, preferredWidth: CGFloat?) -> CGSize {
            
            //horizontal layout
            let scrollsHorizontally = collectionView.frame.width >= collectionView.frame.height
            if scrollsHorizontally {

                var itemHeight = collectionView.frame.height
                itemHeight -= (collectionView.contentInset.top + collectionView.contentInset.bottom)
                itemHeight -= (CGFloat(numberOfItemsInRow) - 1) * layoutConfiguration.interitemSpacing
                itemHeight /= CGFloat(numberOfItemsInRow)
                itemHeight = floor(itemHeight)
                
                return CGSize(width: preferredWidth ?? itemHeight, height: itemHeight)
            }
            
            return .zero
        }
        
        //we dont care about assets count here
        let layoutModel = LayoutModel(configuration: layoutConfiguration, assets: 0)
        
        switch indexPath.section {
        case 0: return sizeForItemInRow(numberOfItemsInRow: layoutModel.numberOfItems(in: 0), preferredWidth: nil)
        case 1: return sizeForItemInRow(numberOfItemsInRow: layoutModel.numberOfItems(in: 1), preferredWidth: 200)
        case 2: return sizeForItemInRow(numberOfItemsInRow: 3, preferredWidth: nil)
        default: fatalError("unexpected sections count")
        }
        
        
//        func indexPathIsActionItem(indexPath: IndexPath) -> Bool {
//            
//        }
//        func sizeForItem(at indexPath: IndexPath) -> CGSize {
//            
//        }
        
        //based on collection view frame we decide if we use vertical of horizontal layout,
        //for now we use only horizontal
        
//        switch indexPath.row {
//        case 1:
//            let itemsInFirstRow =
//            return sizeForItemInRow(numberOfItemsInRow: <#T##Int#>, preferredWidth: <#T##CGFloat#>)
//        case 2:
//        case 3:
//        default:
//        }
//        
//        switch (showsFirstActionItem, showsSecondActionItem, showsCameraActionItem) {
//        case (true, true, true):
//            
//        default:
//            fatalError("other layouts not implemented")
//        }
        
        let width = collectionView.frame.width - 8
        //lets assume we have all sections
        switch indexPath.row {
        case 0...1: return CGSize(width: width/2 - 4, height: width/2)
        case 2: return CGSize(width: width, height: width)
        case 3: return CGSize(width: 100, height: 100)
        default: return CGSize(width: 100, height: 100)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let rows = (collectionView.indexPathsForSelectedItems ?? []).map { $0.row }
        print("selected \(rows)")
    }
    
}
