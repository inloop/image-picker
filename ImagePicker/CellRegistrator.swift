//
//  CellRegistrator.swift
//  Image Picker
//
//  Created by Peter Stajger on 06/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit
import Photos

///
/// Convenient API to register custom cell classes or nibs for each item type.
///
/// Supported item types:
/// 1. action item - register a cell for all items or a different cell for each index.
/// 2. camera item - register a subclass of `CameraCollectionViewCell` to provide a
/// 3. asset item - each asset media type (image, video) can have it's own cell
/// custom camera cell implementation.
///
public final class CellRegistrator {
    deinit {
        log("deinit: \(String(describing: self))")
    }
    
    // MARK: - Private Methods
    private let actionItemIdentifierPrefix = "eu.inloop.action-item.cell-id"
    fileprivate var actionItemNibsData: [Int: (UINib, String)]?
    fileprivate var actionItemClassesData: [Int: (UICollectionViewCell.Type, String)]?
    
    //camera item has only 1 cell so no need for identifiers
    fileprivate var cameraItemNib: UINib?
    fileprivate var cameraItemClass: UICollectionViewCell.Type?
    
    private let assetItemIdentifierPrefix = "eu.inloop.asset-item.cell-id"
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
        guard index < Int.max else { return nil }
        
        //lets see if there is a globally registered cell for all indexes
        return cellIdentifier(forActionItemAt: Int.max)
    }
    
    var hasUserRegisteredActionCell: Bool {
        return (actionItemNibsData?.count ?? 0) > 0 || (actionItemClassesData?.count ?? 0) > 0
    }
    
    var cellIdentifierForAssetItems: String {
        return assetItemIdentifierPrefix
    }
    
    func cellIdentifier(forAsset type: PHAssetMediaType) -> String? {
        return assetItemNibsData?[type]?.1 ?? assetItemClassesData?[type]?.1
    }
    
    // MARK: Public Methods
    
    ///
    /// Register a cell nib for all action items. Use this method if all action items
    /// have the same cell class.
    ///
    public func registerNibForActionItems(_ nib: UINib) {
        register(nib: nib, forActionItemAt: Int.max)
    }
    
    ///
    /// Register a cell class for all action items. Use this method if all action items
    /// have the same cell class.
    ///
    public func registerCellClassForActionItems(_ cellClass: UICollectionViewCell.Type) {
        register(cellClass: cellClass, forActionItemAt: Int.max)
    }
    
    ///
    /// Register a cell nib for an action item at particular index. Use this method if
    /// you wish to use different cells at each index.
    ///
    public func register(nib: UINib, forActionItemAt index: Int) {
        if actionItemNibsData == nil {
            actionItemNibsData = [:]
        }
        let cellIdentifier = actionItemIdentifierPrefix + String(index)
        actionItemNibsData?[index] = (nib, cellIdentifier)
    }
    
    ///
    /// Register a cell class for an action item at particular index. Use this method if
    /// you wish to use different cells at each index.
    ///
    public func register(cellClass: UICollectionViewCell.Type, forActionItemAt index: Int) {
        if actionItemClassesData == nil {
            actionItemClassesData = [:]
        }
        let cellIdentifier = actionItemIdentifierPrefix + String(index)
        actionItemClassesData?[index] = (cellClass, cellIdentifier)
    }
    
    ///
    /// Register a cell class for camera item.
    ///
    public func registerCellClassForCameraItem(_ cellClass: CameraCollectionViewCell.Type) {
        cameraItemClass = cellClass
    }
    
    ///
    /// Register a cell nib for camera item.
    ///
    /// - note: A cell class must subclass `CameraCollectionViewCell` or an exception
    /// will be thrown.
    ///
    public func registerNibForCameraItem(_ nib: UINib) {
        cameraItemNib = nib
    }
    
    ///
    /// Register a cell nib for asset items of specific type (image or video).
    ///
    /// - note: Please note, that if you register cell for specific type and your collection view displays
    /// also other types that you did not register an exception will be thrown. Always register cells
    /// for all media types you support.
    ///
    public func register(nib: UINib, forAssetItemOf type: PHAssetMediaType) {
        if assetItemNibsData == nil {
            assetItemNibsData = [:]
        }
        let cellIdentifier = assetItemIdentifierPrefix + String(describing: type.rawValue)
        assetItemNibsData?[type] = (nib, cellIdentifier)
    }
    
    ///
    /// Register a cell class for asset items of specific type (image or video).
    ///
    /// - note: Please note, that if you register cell for specific type and your collection view displays
    /// also other types that you did not register an exception will be thrown. Always register cells
    /// for all media types you support.
    ///
    public func register<T: UICollectionViewCell>(cellClass: T.Type, forAssetItemOf type: PHAssetMediaType) where T: ImagePickerAssetCell {
        if assetItemClassesData == nil {
            assetItemClassesData = [:]
        }
        let cellIdentifier = assetItemIdentifierPrefix + String(describing: type.rawValue)
        assetItemClassesData?[type] = (cellClass, cellIdentifier)
    }
    
    ///
    /// Register a cell class for all asset items types (image and video).
    ///
    public func registerCellClassForAssetItems<T: UICollectionViewCell>(_ cellClass: T.Type) where T: ImagePickerAssetCell {
        assetItemClass = cellClass
    }
    
    ///
    /// Register a cell nib for all asset items types (image and video).
    ///
    /// Please note that cell's class must conform to `ImagePickerAssetCell` protocol, otherwise an exception will be thrown.
    ///
    public func registerNibForAssetItems(_ nib: UINib) {
        assetItemNib = nib
    }
}

extension UICollectionView {
    ///
    /// Used by datasource when registering all cells to the collection view. If user
    /// did not register custom cells, this method registers default cells
    ///
    func apply(registrator: CellRegistrator, cameraMode: CaptureSettings.CameraMode) {
        registerActionItems(registrator: registrator)
        registerCameraItem(registrator: registrator, cameraMode: cameraMode)
        registerAssetItems(registrator: registrator)
    }

    private func registerActionItems(registrator: CellRegistrator) {
        if registrator.hasUserRegisteredActionCell {
            register(nibsData: registrator.actionItemNibsData?.map { $1 })
            register(classData: registrator.actionItemClassesData?.map { $1 })
        } else {
            registerDefaultActionCell(registrator: registrator)
        }
    }

    private func registerDefaultActionCell(registrator: CellRegistrator) {
        registrator.registerCellClassForActionItems(ActionCell.self)
        guard let identifier = registrator.cellIdentifier(forActionItemAt: Int.max) else {
            fatalError("Image Picker: unable to register default action item cell")
        }
        let nib = UINib(nibName: "ActionCell", bundle: Bundle(for: ActionCell.self))
        register(nib, forCellWithReuseIdentifier: identifier)
    }

    private func registerAssetItems(registrator: CellRegistrator) {
        register(nibsData: registrator.assetItemNibsData?.map { $1 })
        register(classData: registrator.assetItemClassesData?.map { $1 })
        switch (registrator.assetItemNib, registrator.assetItemClass) {

        case (nil, nil):
            //if user did not register all required classes/nibs - register default cells
            register(VideoAssetCell.self, forCellWithReuseIdentifier: registrator.cellIdentifierForAssetItems)
        case (let nib, nil):
            register(nib, forCellWithReuseIdentifier: registrator.cellIdentifierForAssetItems)
        case (_, let cellClass):
            register(cellClass, forCellWithReuseIdentifier: registrator.cellIdentifierForAssetItems)
        }
    }

    private func registerCameraItem(registrator: CellRegistrator, cameraMode: CaptureSettings.CameraMode) {
        switch (registrator.cameraItemNib, registrator.cameraItemClass) {
        case (nil, nil):
            registerDefaultCell(for: cameraMode, registrator: registrator)
        case (let nib, nil):
            register(nib, forCellWithReuseIdentifier: registrator.cellIdentifierForCameraItem)
        case (_, let cellClass):
            register(cellClass, forCellWithReuseIdentifier: registrator.cellIdentifierForCameraItem)
        }
    }

    private func registerDefaultCell(for cameraMode: CaptureSettings.CameraMode, registrator: CellRegistrator) {
        switch cameraMode {
        case .photo, .photoAndLivePhoto:
            let nib = UINib(nibName: "LivePhotoCameraCell", bundle: Bundle(for: LivePhotoCameraCell.self))
            register(nib, forCellWithReuseIdentifier: registrator.cellIdentifierForCameraItem)
        case .photoAndVideo:
            let nib = UINib(nibName: "VideoCameraCell", bundle: Bundle(for: VideoCameraCell.self))
            register(nib, forCellWithReuseIdentifier: registrator.cellIdentifierForCameraItem)
        }
    }

    ///
    /// Helper func that takes nib,cellid pair and registers them on a collection view
    ///
    private func register(nibsData: [(UINib, String)]?) {
        guard let nibsData = nibsData else { return }
        for (nib, cellIdentifier) in nibsData {
            register(nib, forCellWithReuseIdentifier: cellIdentifier)
        }
    }
    
    ///
    /// Helper func that takes nib,cellid pair and registers them on a collection view
    ///
    private func register(classData: [(UICollectionViewCell.Type, String)]?) {
        guard let classData = classData else { return }
        for (cellType, cellIdentifier) in classData {
            register(cellType, forCellWithReuseIdentifier: cellIdentifier)
        }
    }
    
}
