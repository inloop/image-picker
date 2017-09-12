//
//  CellRegistrator.swift
//  ExampleApp
//
//  Created by Peter Stajger on 06/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit
import Photos

///
/// Use this class to register various cell nibs or classes for each item type.
///
/// Supported item types:
/// 1. action item - there can be multiple action items
/// 2. asset item - each asset can have multiple types (image, video, burst, etc..)
///
public final class CellRegistrator {
    
    deinit {
        print("deinit: \(String(describing: self))")
    }
    
    // MARK: Private Methods
    
    fileprivate let actionItemIdentifierPrefix = "eu.inloop.action-item.cell-id"
    fileprivate var actionItemNibsData: [Int: (UINib, String)]?
    fileprivate var actionItemClassesData: [Int: (UICollectionViewCell.Type, String)]?
    
    //camera item has only 1 cell so no need for identifiers
    fileprivate var cameraItemNib: UINib?
    fileprivate var cameraItemClass: UICollectionViewCell.Type?
    
    fileprivate let assetItemIdentifierPrefix = "eu.inloop.asset-item.cell-id"
    fileprivate var assetItemNibsData: [PHAssetMediaType: (UINib, String)]?
    fileprivate var assetItemClassesData: [PHAssetMediaType: (UICollectionViewCell.Type, String)]?
    
    //we use these if there is no asset media type specified
    fileprivate var assetItemNib: UINib?
    fileprivate var assetItemClass: UICollectionViewCell.Type?
    
    // MARK: Internal Methods
    
    let cellIdentifierForCameraItem = "eu.inloop.camera-item.cell-id"
    
    func cellIdentifier(forActionItemAt index: Int) -> String? {
        
        //first lets check if there is a registered cell at specified index
        if let index = actionItemNibsData?[index]?.1 ?? actionItemClassesData?[index]?.1 {
            return index
        }
        
        //if not found globaly registered return nil
        guard index < Int.max else {
            return nil
        }
        
        //lets see if there is a globally registered cell for all indexes
        return cellIdentifier(forActionItemAt: Int.max)
    }
    
    var cellIdentifierForAssetItems: String {
        return assetItemIdentifierPrefix
    }
    
    func cellIdentifier(forAsset type: PHAssetMediaType) -> String? {
        return assetItemNibsData?[type]?.1 ?? assetItemClassesData?[type]?.1
    }
    
    // MARK: Public Methods
    
    public init() {
        
    }
    
    public func registerCellClassForCameraItem(_ cellClass: CameraCollectionViewCell.Type) {
        cameraItemClass = cellClass
    }
    
    public func registerNibForCameraItem(_ nib: UINib) {
        cameraItemNib = nib
    }
    
    ///
    /// Registers a nib for all action items. Use this method if all action items
    /// have the same nib.
    ///
    public func registerNibForActionItems(_ nib: UINib) {
        register(nib: nib, forActionItemAt: Int.max)
    }
    
    ///
    /// Registers a cell class for all action items. Use this method if all action items
    /// have the same nib.
    ///
    public func registerCellClassForActionItems(_ cellClass: UICollectionViewCell.Type) {
        register(cellClass: cellClass, forActionItemAt: Int.max)
    }
    
    ///
    /// Registers a nib for an action item at particular index. Use this method if
    /// you wish to use different cells.
    ///
    public func register(nib: UINib, forActionItemAt index: Int) {
        if actionItemNibsData == nil {
            actionItemNibsData = [:]
        }
        let cellIdentifier = actionItemIdentifierPrefix + String(index)
        actionItemNibsData?[index] = (nib, cellIdentifier)
    }
    
    public func register(cellClass: UICollectionViewCell.Type, forActionItemAt index: Int) {
        if actionItemClassesData == nil {
            actionItemClassesData = [:]
        }
        let cellIdentifier = actionItemIdentifierPrefix + String(index)
        actionItemClassesData?[index] = (cellClass, cellIdentifier)
    }
    
    public func register(nib: UINib, forAssetItemOf type: PHAssetMediaType) {
        if assetItemNibsData == nil {
            assetItemNibsData = [:]
        }
        let cellIdentifier = assetItemIdentifierPrefix + String(describing: type.rawValue)
        assetItemNibsData?[type] = (nib, cellIdentifier)
    }
    
    ///
    /// Please note that cellClass must conform to `ImagePickerAssetCell` protocol.
    ///
    public func register(cellClass: UICollectionViewCell.Type, forAssetItemOf type: PHAssetMediaType) {
        if assetItemClassesData == nil {
            assetItemClassesData = [:]
        }
        let cellIdentifier = assetItemIdentifierPrefix + String(describing: type.rawValue)
        assetItemClassesData?[type] = (cellClass, cellIdentifier)
    }
    
    public func registerCellClassForAssetItems<T: UICollectionViewCell>(_ cellClass: T.Type) where T: ImagePickerAssetCell {
        assetItemClass = cellClass
    }
    
    public func registerNibForAssetItems(_ nib: UINib) {
        assetItemNib = nib
    }
}

extension UICollectionView {
    
    ///
    /// Used by datasource when registering all cells to the collection view
    ///
    func apply(registrator: CellRegistrator) {
    
        //register action items considering type
        register(nibsData: registrator.actionItemNibsData?.map { $1 })
        register(classData: registrator.actionItemClassesData?.map { $1 })
        
        //register camera item
        switch (registrator.cameraItemNib, registrator.cameraItemClass) {
        
        case (nil, nil):
            //if user does not set any class or nib we have to register default cell `CameraCollectionViewCell`
            register(CameraCollectionViewCell.self, forCellWithReuseIdentifier: registrator.cellIdentifierForCameraItem)
        
        case (let nib, nil):
            register(nib, forCellWithReuseIdentifier: registrator.cellIdentifierForCameraItem)
        
        case (_, let cellClass):
            register(cellClass, forCellWithReuseIdentifier: registrator.cellIdentifierForCameraItem)
        }
        
        //register asset items considering type
        register(nibsData: registrator.assetItemNibsData?.map { $1 })
        register(classData: registrator.assetItemClassesData?.map { $1 })
        
        //register asset items regardless of specified type
        switch (registrator.assetItemNib, registrator.assetItemClass) {
        
        case (nil, nil):
            fatalError("there is not registered cell class nor nib for asset items, please user appropriate register methods on `CellRegistrator`")
        
        case (let nib, nil):
            register(nib, forCellWithReuseIdentifier: registrator.cellIdentifierForAssetItems)
        
        case (_, let cellClass):
            register(cellClass, forCellWithReuseIdentifier: registrator.cellIdentifierForAssetItems)
        }
    }
    
    ///
    /// Helper func that takes nib,cellid pair and registers them on a collection view
    ///
    fileprivate func register(nibsData: [(UINib, String)]?) {
        guard let nibsData = nibsData else { return }
        for (nib, cellIdentifier) in nibsData {
            register(nib, forCellWithReuseIdentifier: cellIdentifier)
        }
    }
    
    ///
    /// Helper func that takes nib,cellid pair and registers them on a collection view
    ///
    fileprivate func register(classData: [(UICollectionViewCell.Type, String)]?) {
        guard let classData = classData else { return }
        for (cellType, cellIdentifier) in classData {
            register(cellType, forCellWithReuseIdentifier: cellIdentifier)
        }
    }
    
}
