//
//  ImagePickerAssetModel.swift
//  ImagePicker
//
//  Created by Peter Stajger on 12/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import Photos

///
/// Model that is used when accessing an caching PHAsset objects
///
final class ImagePickerAssetModel {
    
    deinit {
        log("deinit: \(String(describing: self))")
    }
    
    var fetchResult: PHFetchResult<PHAsset>! {
        set { userDefinedFetchResult = newValue }
        get { return userDefinedFetchResult ?? defaultFetchResult }
    }
    
    lazy var imageManager = PHCachingImageManager()
    var thumbnailSize: CGSize?
    
    /// Tryies to access smart album .smartAlbumUserLibrary that should be `Camera Roll` and uses just fetchAssets as fallback
    private lazy var defaultFetchResult: PHFetchResult<PHAsset> = {
        
        let assetsOptions = PHFetchOptions()
        assetsOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        assetsOptions.fetchLimit = 1000
        
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil)
        if let cameraRoll = collections.firstObject {
            return PHAsset.fetchAssets(in: cameraRoll, options: assetsOptions)
        }
        else {
            return PHAsset.fetchAssets(with: assetsOptions)
        }
    }()
    
    private var userDefinedFetchResult: PHFetchResult<PHAsset>?
    
    //will be use for caching
    var previousPreheatRect = CGRect.zero
    
    func updateCachedAssets(collectionView: UICollectionView) {
        
        // Paradoxly, using this precaching the scrolling of images is more laggy than if there is no precaching
        
        guard let thumbnailSize = thumbnailSize else {
            return log("asset model: update cache assets - thumbnail size is nil")
        }
        
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return log("asset model: update cache assets - collection view layout is not flow layout")
        }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        
        var preheatRect: CGRect
        
        switch layout.scrollDirection {
        case .vertical:
            
            preheatRect = visibleRect.insetBy(dx: 0, dy: -0.75 * visibleRect.height)
            
            // Update only if the visible area is significantly different from the last preheated area.
            let delta = abs(preheatRect.midY - previousPreheatRect.midY)
            guard delta > collectionView.bounds.height / 3 else {
                return
            }
            
        case .horizontal:
            
            preheatRect = visibleRect.insetBy(dx: -0.75 * visibleRect.width, dy: 0)
            
            // Update only if the visible area is significantly different from the last preheated area.
            let delta = abs(preheatRect.midX - previousPreheatRect.midX)
            guard delta > collectionView.bounds.width / 3 else {
                return
            }
        }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(previousPreheatRect, preheatRect, layout.scrollDirection)
        let addedAssets = addedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        let removedAssets = removedRects
            .flatMap { rect in collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in fetchResult.object(at: indexPath.item) }
        
        // Update the assets the PHCachingImageManager is caching.
        imageManager.startCachingImages(for: addedAssets, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        log("asset model: caching, size \(thumbnailSize), preheat rect \(preheatRect), items \(addedAssets.count)")
        
        imageManager.stopCachingImages(for: removedAssets, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil)
        log("asset model: uncaching, preheat rect \(preheatRect), items \(removedAssets.count)")
        
        // Store the preheat rect to compare against in the future.
        previousPreheatRect = preheatRect
    }
}
