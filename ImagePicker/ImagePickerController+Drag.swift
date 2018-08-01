// Copyright © 2018 INLOOPX. All rights reserved.

import UIKit

@available(iOS 11.0, *)
extension ImagePickerController: UICollectionViewDragDelegate {
    public func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard indexPath.section == LayoutConfiguration.default.sectionIndexForAssets else { return [] }
        
        let asset = collectionViewDataSource.assetsCacheItem.fetchResult.object(at: indexPath.item)
        let itemProvider = NSItemProvider(object: asset.localIdentifier as NSString)
        
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = asset
        
        return [dragItem]
    }
    
    public func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        guard indexPath.section == LayoutConfiguration.default.sectionIndexForAssets else { return [] }
        
        let asset = collectionViewDataSource.assetsCacheItem.fetchResult.object(at: indexPath.item)
        let itemProvider = NSItemProvider(object: asset.localIdentifier as NSString)
        
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = asset
        
        return [dragItem]
    }
    
    public func collectionView(_ collectionView: UICollectionView, dragSessionIsRestrictedToDraggingApplication session: UIDragSession) -> Bool {
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        delegate?.imagePicker(controller: self, dragSessionWillBegin: session)
    }
    
    public func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        delegate?.imagePicker(controller: self, dragSessionDidEnd: session)
    }
}
