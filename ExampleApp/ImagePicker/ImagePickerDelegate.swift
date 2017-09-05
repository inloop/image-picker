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
    
    ///
    /// Spacing between items within a section
    ///
    var interitemSpacing: CGFloat = 1
    
    ///
    /// Spacing between actions section and camera section
    ///
    var actionSectionSpacing: CGFloat = 1
    
    ///
    /// Spacing between camera section and assets section
    ///
    var cameraSectionSpacing: CGFloat = 10
    
    static var defaultConfiguration = LayoutConfiguration()
}

final class ImagePickerDelegate : NSObject, UICollectionViewDelegateFlowLayout {
    
    var layoutConfiguration = LayoutConfiguration()
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            fatalError("currently only UICollectionViewFlowLayout is supported")
        }
        
        func sizeForItemInRow(numberOfItemsInRow: Int, preferredWidth: CGFloat?) -> CGSize {
            
            switch layout.scrollDirection {
            case .horizontal:
                var itemHeight = collectionView.frame.height
                itemHeight -= (collectionView.contentInset.top + collectionView.contentInset.bottom)
                itemHeight -= (CGFloat(numberOfItemsInRow) - 1) * layoutConfiguration.interitemSpacing
                itemHeight /= CGFloat(numberOfItemsInRow)
                itemHeight = floor(itemHeight)
                return CGSize(width: preferredWidth ?? itemHeight, height: itemHeight)
                
            case .vertical:
                fatalError("unsupported scroll direction")
            }

        }
        
        //we dont care about assets count here
        let layoutModel = LayoutModel(configuration: layoutConfiguration, assets: 0)
        
        switch indexPath.section {
        case 0: return sizeForItemInRow(numberOfItemsInRow: layoutModel.numberOfItems(in: 0), preferredWidth: nil)
        case 1: return sizeForItemInRow(numberOfItemsInRow: layoutModel.numberOfItems(in: 1), preferredWidth: 200)
        case 2: return sizeForItemInRow(numberOfItemsInRow: 3, preferredWidth: nil)
        default: fatalError("unexpected sections count")
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let rows = (collectionView.indexPathsForSelectedItems ?? []).map { $0.row }
        print("selected \(rows)")
    }
    
}
