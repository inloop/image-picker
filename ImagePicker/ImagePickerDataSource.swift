// Copyright © 2018 INLOOPX. All rights reserved.

import Photos
import UIKit

/// Datasource for a collection view that is used by Image Picker VC.

final class ImagePickerDataSource: NSObject, UICollectionViewDataSource {
    var layoutModel = LayoutModel.empty
    var cellRegistrator: CellRegistrator?
    var assetsCacheItem: ImagePickerAssetCacheItem
    
    init(assetsCacheItem: ImagePickerAssetCacheItem) {
        self.assetsCacheItem = assetsCacheItem
        super.init()
    }
    
    deinit {
        log("deinit: \(String(describing: self))")
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return layoutModel.numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return layoutModel.numberOfItems(in: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cellsRegistrator = cellRegistrator else {
            fatalError("cells registrator must be set at this moment")
        }
        
        switch indexPath.section {
        case LayoutConfiguration.default.sectionIndexForActions:
            guard let id = cellsRegistrator.cellIdentifier(forActionItemAt: indexPath.row) else {
                fatalError("there is an action item at index \(indexPath.row) but no cell is registered.")
            }
            return collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)

        case LayoutConfiguration.default.sectionIndexForCamera:
            let id = cellsRegistrator.cellIdentifierForCameraItem
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as? CameraCollectionViewCell else {
                fatalError("there is a camera item but no cell class `CameraCollectionViewCell` is registered.")
            }
            return cell
            
        case LayoutConfiguration.default.sectionIndexForAssets:
            return assetItems(for: indexPath, collectionView: collectionView, cellsRegistrator: cellsRegistrator)
            
        default: fatalError("only 3 sections are supported")
        }
    }
    
    private func assetItems(for indexPath: IndexPath, collectionView: UICollectionView, cellsRegistrator: CellRegistrator) -> UICollectionViewCell {
        let asset = assetsCacheItem.fetchResult.object(at: indexPath.item)
        let cellId = cellsRegistrator.cellIdentifier(forAsset: asset.mediaType) ?? cellsRegistrator.cellIdentifierForAssetItems
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? ImagePickerAssetCell else {
            fatalError("asset item cell must conform to \(ImagePickerAssetCell.self) protocol")
        }
        
        let thumbnailSize = assetsCacheItem.thumbnailSize ?? .zero
        
        // Request an image for the asset from the PHCachingImageManager.
        cell.representedAssetIdentifier = asset.localIdentifier
        let assetIdentifier = asset.localIdentifier
        
        assetsCacheItem.imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil) { [weak cell] image, _ in
            // The cell may have been recycled by the time this handler gets called;
            // set the cell's thumbnail image only if it's still showing the same asset.
            if let cell = cell, cell.representedAssetIdentifier == assetIdentifier && image != nil {
                cell.imageView.image = image
            }
        }
        
        return cell as! UICollectionViewCell
    }
}
