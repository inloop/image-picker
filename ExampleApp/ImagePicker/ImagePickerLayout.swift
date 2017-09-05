//
//  ImagePickerLayout.swift
//  ExampleApp
//
//  Created by Peter Stajger on 05/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

///
/// A helper struct that is used by ImagePickerLayout when configuring and laying out
/// collection view items.
///
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

///
/// A helper class that contains all code and logic when doing layout of collection
/// view cells. This is used sollely by collection view's delegate. Typically 
/// this code should be part of regular subclass of UICollectionViewLayout, however,
/// since we are using UICollectionViewFlowLayout we have to do this workaround.
///
final class ImagePickerLayout {

    var configuration: LayoutConfiguration
    
    init(configuration: LayoutConfiguration) {
        self.configuration = configuration
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            fatalError("currently only UICollectionViewFlowLayout is supported")
        }
        
        /// Returns size for item considering number of rows and scroll direction, if preferredWidth is nil, square size is returned
        func sizeForItem(numberOfItemsInRow: Int, preferredWidth: CGFloat?) -> CGSize {
            
            switch layout.scrollDirection {
            case .horizontal:
                var itemHeight = collectionView.frame.height
                itemHeight -= (collectionView.contentInset.top + collectionView.contentInset.bottom)
                itemHeight -= (CGFloat(numberOfItemsInRow) - 1) * configuration.interitemSpacing
                itemHeight /= CGFloat(numberOfItemsInRow)
                return CGSize(width: preferredWidth ?? itemHeight, height: itemHeight)
                
            case .vertical:
                var itemWidth = collectionView.frame.width
                itemWidth -= (collectionView.contentInset.left + collectionView.contentInset.right)
                itemWidth -= (CGFloat(numberOfItemsInRow) - 1) * configuration.interitemSpacing
                itemWidth /= CGFloat(numberOfItemsInRow)
                return CGSize(width: itemWidth, height: preferredWidth ?? itemWidth)
            }
            
        }
        
        let layoutModel = LayoutModel(configuration: configuration, assets: 0)
        
        switch indexPath.section {
        case 0:
            //this will make sure that action item is either square if there are 2 items,
            //or a recatangle if there is only 1 item
            let width = sizeForItem(numberOfItemsInRow: 2, preferredWidth: nil).width
            return sizeForItem(numberOfItemsInRow: layoutModel.numberOfItems(in: 0), preferredWidth: width)
            
        case 1:
            //lets keep this ratio so camera item is a nice rectangle
            let ratio: CGFloat = 0.734
            let width: CGFloat = collectionView.frame.height * ratio
            return sizeForItem(numberOfItemsInRow: layoutModel.numberOfItems(in: 1), preferredWidth: width)
            
        case 2:
            return sizeForItem(numberOfItemsInRow: configuration.numberOfAssetItemsInRow, preferredWidth: nil)
            
        default:
            fatalError("unexpected sections count")
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            fatalError("currently only UICollectionViewFlowLayout is supported")
        }
        
        /// helper method that creates edge insets considering scroll direction
        func sectionInsets(_ inset: CGFloat) -> UIEdgeInsets {
            switch layout.scrollDirection {
            case .horizontal: return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: inset)
            case .vertical: return UIEdgeInsets(top: 0, left: 0, bottom: inset, right: 0)
            }
        }
        
        let layoutModel = LayoutModel(configuration: configuration, assets: 0)
        
        switch section {
        case 0 where layoutModel.numberOfItems(in: section) > 0:
            return sectionInsets(configuration.actionSectionSpacing)
        case 1 where layoutModel.numberOfItems(in: section) > 0:
            return sectionInsets(configuration.cameraSectionSpacing)
        default:
            return .zero
        }
    }
    
}
