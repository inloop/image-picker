//
//  UICollectionView+CellRegistrator.swift
//  ImagePicker
//
//  Created by Anna Shirokova on 14/06/2018.
//  Copyright © 2018 Inloop. All rights reserved.
//

import Foundation


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
}

// MARK: - Helper private methods
private extension UICollectionView {
    func registerActionItems(registrator: CellRegistrator) {
        if registrator.hasUserRegisteredActionCell {
            register(nibsData: registrator.actionItemNibsData?.map { $1 })
            register(classData: registrator.actionItemClassesData?.map { $1 })
        } else {
            registerDefaultActionCell(registrator: registrator)
        }
    }

    func registerDefaultActionCell(registrator: CellRegistrator) {
        registrator.registerCellClassForActionItems(ActionCell.self)
        guard let identifier = registrator.cellIdentifier(forActionItemAt: Int.max) else {
            fatalError("Image Picker: unable to register default action item cell")
        }
        let nib = UINib(nibName: "ActionCell", bundle: Bundle(for: ActionCell.self))
        register(nib, forCellWithReuseIdentifier: identifier)
    }

    func registerAssetItems(registrator: CellRegistrator) {
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

    func registerCameraItem(registrator: CellRegistrator, cameraMode: CaptureSettings.CameraMode) {
        switch (registrator.cameraItemNib, registrator.cameraItemClass) {
        case (nil, nil):
            registerDefaultCell(for: cameraMode, registrator: registrator)
        case (let nib, nil):
            register(nib, forCellWithReuseIdentifier: registrator.cellIdentifierForCameraItem)
        case (_, let cellClass):
            register(cellClass, forCellWithReuseIdentifier: registrator.cellIdentifierForCameraItem)
        }
    }

    func registerDefaultCell(for cameraMode: CaptureSettings.CameraMode, registrator: CellRegistrator) {
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
    func register(nibsData: [(UINib, String)]?) {
        guard let nibsData = nibsData else { return }
        for (nib, cellIdentifier) in nibsData {
            register(nib, forCellWithReuseIdentifier: cellIdentifier)
        }
    }

    ///
    /// Helper func that takes nib,cellid pair and registers them on a collection view
    ///
    func register(classData: [(UICollectionViewCell.Type, String)]?) {
        guard let classData = classData else { return }
        for (cellType, cellIdentifier) in classData {
            register(cellType, forCellWithReuseIdentifier: cellIdentifier)
        }
    }
}
