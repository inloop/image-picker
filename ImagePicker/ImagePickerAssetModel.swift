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
