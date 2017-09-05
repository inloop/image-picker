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
    
    ///
    /// Defines how many image assets will be in a row
    ///
    var numberOfAssetItemsInRow: Int = 2
    
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
    
}

extension LayoutConfiguration {
    
    var hasAnyAction: Bool {
        return showsFirstActionItem || showsSecondActionItem
    }
    
    static var defaultConfiguration = LayoutConfiguration()
}

final class ImagePickerDelegate : NSObject, UICollectionViewDelegateFlowLayout {
    
    var layoutConfiguration = LayoutConfiguration()
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            fatalError("currently only UICollectionViewFlowLayout is supported")
        }
        
        /// Returns size for item considering number of rows, if preferredWidth is nil, square size is returned
        func sizeForItemInRow(numberOfItemsInRow: Int, preferredWidth: CGFloat?) -> CGSize {
            
            switch layout.scrollDirection {
            case .horizontal:
                var itemHeight = collectionView.frame.height
                itemHeight -= (collectionView.contentInset.top + collectionView.contentInset.bottom)
                itemHeight -= (CGFloat(numberOfItemsInRow) - 1) * layoutConfiguration.interitemSpacing
                itemHeight /= CGFloat(numberOfItemsInRow)
                return CGSize(width: preferredWidth ?? itemHeight, height: itemHeight)
                
            case .vertical:
                fatalError("unsupported scroll direction")
            }

        }
        
        let layoutModel = LayoutModel(configuration: layoutConfiguration, assets: 0)
        
        switch indexPath.section {
        case 0:
            //this will make sure that action item is either square if there are 2 items,
            //or a recatangle if there is only 1 item
            let width = sizeForItemInRow(numberOfItemsInRow: 2, preferredWidth: nil).width
            return sizeForItemInRow(numberOfItemsInRow: layoutModel.numberOfItems(in: 0), preferredWidth: width)
        
        case 1:
            let ratio: CGFloat = 0.734
            let width: CGFloat = collectionView.frame.height * ratio
            return sizeForItemInRow(numberOfItemsInRow: layoutModel.numberOfItems(in: 1), preferredWidth: width)
        
        case 2:
            return sizeForItemInRow(numberOfItemsInRow: layoutConfiguration.numberOfAssetItemsInRow, preferredWidth: nil)
        
        default:
            fatalError("unexpected sections count")
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        let layoutModel = LayoutModel(configuration: layoutConfiguration, assets: 0)
        
        switch section {
        case 0 where layoutModel.numberOfItems(in: section) > 0:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: layoutConfiguration.actionSectionSpacing)
        case 1 where layoutModel.numberOfItems(in: section) > 0:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: layoutConfiguration.cameraSectionSpacing)
        default:
            return .zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let rows = (collectionView.indexPathsForSelectedItems ?? []).map { $0.row }
        print("selected \(rows)")
    }
    
}
