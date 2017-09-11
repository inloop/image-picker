//
//  ImagePickerDataSource.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import Photos

//TODO: move somewhere else
public protocol ImagePickerAssetCell : class {
    
    /// This image view will be used when setting an asset's image
    var imageView: UIImageView! { get set }
    
    /// This is a helper identifier that is used when properly displaying cells asynchronously
    var representedAssetIdentifier: String? { get set }
}

///
/// Model that is used when accessing an caching PHAsset objects
///
final class ImagePickerAssetModel {

    var fetchResult: PHFetchResult<PHAsset>! {
        set { userDefinedFetchResult = newValue }
        get { return userDefinedFetchResult ?? defaultFetchResult }
    }
    
    var assetCollection: PHAssetCollection?
    
    let imageManager = PHCachingImageManager()
    var thumbnailSize: CGSize?
    
    /// Tryies to access smart album recently added and uses just fetchAssets as fallback
    private lazy var defaultFetchResult: PHFetchResult<PHAsset> = {
       
        let assetsOptions = PHFetchOptions()
        assetsOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        assetsOptions.fetchLimit = 1000
        
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumRecentlyAdded, options: nil)
        if let recentlyAdded = collections.firstObject {
            return PHAsset.fetchAssets(in: recentlyAdded, options: assetsOptions)
        }
        else {
            return PHAsset.fetchAssets(with: assetsOptions)
        }
    }()
    
    private var userDefinedFetchResult: PHFetchResult<PHAsset>?
    
    //will be use for caching
    //var previousPreheatRect = CGRect.zero
    
    //TODO: add special thumbnail pre-caching as user scrolls
}

///
/// Datasource for a collection view that is used by Image Picker VC.
///
final class ImagePickerDataSource : NSObject, UICollectionViewDataSource {
    
    //TODO: perhaps we dont want default empty layout model, it could cause bugs if not set up properly in VC
    var layoutModel = LayoutModel.empty
    
    var cellRegistrator: CellRegistrator?
    
    var assetsModel: ImagePickerAssetModel?
    
    override init() {
        super.init()
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
        case 0:
            guard let id = cellsRegistrator.cellIdentifier(forActionItemAt: indexPath.row) else {
                fatalError("there is an action item at index \(indexPath.row) but no cell is registered.")
            }
            return collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
        
        case 1:
            let id = cellsRegistrator.cellIdentifierForCameraItem
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as? CameraCollectionViewCell else {
                fatalError("there is a camera item but no cell class `CameraCollectionViewCell` is registered.")
            }
            return cell
            
        case 2:
            //TODO: we are assuming images only for now
            let type = AssetType.image
            guard let id = cellsRegistrator.cellIdentifier(forAsset: type) else {
                fatalError("there is an asset item at index \(indexPath.row) but no cell is registered")
            }
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as? ImagePickerAssetCell else {
                fatalError("asset item cell must conform to \(ImagePickerAssetCell.self) protocol")
            }
            
            //kittens graveyard :(
            let asset = assetsModel!.fetchResult!.object(at: indexPath.item)
            let thumbnailSize = assetsModel!.thumbnailSize!
            
            // Request an image for the asset from the PHCachingImageManager.
            cell.representedAssetIdentifier = asset.localIdentifier
            assetsModel!.imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
                // The cell may have been recycled by the time this handler gets called;
                // set the cell's thumbnail image only if it's still showing the same asset.
                if cell.representedAssetIdentifier == asset.localIdentifier && image != nil {
                    cell.imageView.image = image
                }
            })
            
            return cell as! UICollectionViewCell
        
        default: fatalError("only 3 sections are supporte")
        }
    }
    

}
