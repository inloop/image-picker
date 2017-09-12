//
//  ImagePickerViewController.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit
import Photos

public protocol ImagePickerViewControllerDelegate : class {
    
    ///
    /// Called when user taps on an action item, index is either 0 or 1 depending which was tapped
    ///
    func imagePicker(controller: ImagePickerViewController, didSelectActionItemAt index: Int)
    
    func imagePicker(controller: ImagePickerViewController, didFinishPicking asset: PHAsset)
    
    //perhaps we can use method above and remove this one, client does not care if user took a picture or
    //picked it from a library, to do that we perhaps have to save taken image to photo library
    func imagePicker(controller: ImagePickerViewController, didTake image: UIImage)
    
    ///
    /// Called right before an action item collection view cell is displayed. Use this method
    /// to configure your cell.
    ///
    func imagePicker(controller: ImagePickerViewController, willDisplayActionItem cell: UICollectionViewCell, at index: Int)
    
    ///
    /// Called right before an asset item collection view cell is displayed. Use this method
    /// to configure your cell based on asset media type, subtype, etc.
    ///
    func imagePicker(controller: ImagePickerViewController, willDisplayAssetItem cell: ImagePickerAssetCell, asset: PHAsset)
}

//this will make sure all delegate methods are optional
extension ImagePickerViewControllerDelegate {
    public func imagePicker(controller: ImagePickerViewController, didSelectActionItemAt index: Int) {}
    public func imagePicker(controller: ImagePickerViewController, didFinishPicking asset: PHAsset) {}
    public func imagePicker(controller: ImagePickerViewController, didTake image: UIImage) {}
    public func imagePicker(controller: ImagePickerViewController, willDisplayActionItem cell: UICollectionViewCell, at index: Int) {}
    public func imagePicker(controller: ImagePickerViewController, willDisplayAssetItem cell: ImagePickerAssetCell, asset: PHAsset) {}
}

open class ImagePickerViewController : UIViewController {
   
    deinit {
        print("deinit: \(self.classForCoder)")
    }
    
    // MARK: Public API
    
    ///
    /// Use this object to configure layout of action, camera and asset items.
    ///
    public var layoutConfiguration = LayoutConfiguration.default
    
    ///
    /// Use this to register a cell classes or nibs for each item types
    ///
    public var cellRegistrator = CellRegistrator()
    
    ///
    /// Get informed about user interaction and changes
    ///
    public weak var delegate: ImagePickerViewControllerDelegate?
    
    ///
    /// Access all currently selected images
    ///
    public var selectedAssets: [PHAsset] {
        get {
            let selectedIndexPaths = collectionView.indexPathsForSelectedItems ?? []
            let selectedAssets = selectedIndexPaths.flatMap { indexPath in
                return collectionViewDataSource.assetsModel?.fetchResult?.object(at: indexPath.row)
            }
            return selectedAssets
        }
    }
    
    ///
    /// Fetch result of assets that will be used for picking.
    ///
    /// If you leave this nil or return nil from the block, assets from recently
    /// added smart album will be used.
    ///
    public var assetsFetchResultBlock: (() -> PHFetchResult<PHAsset>?)?
    
    // MARK: Private Methods
    
    fileprivate var collectionViewDataSource = ImagePickerDataSource()
    fileprivate var collectionViewDelegate = ImagePickerDelegate()
    
    fileprivate lazy var collectionView: UICollectionView = {
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.backgroundColor = UIColor.red
        view.contentInset = UIEdgeInsets.zero
        view.dataSource = self.collectionViewDataSource
        view.delegate = self.collectionViewDelegate
        view.allowsMultipleSelection = true
        
        //register all nibs
        view.apply(registrator: self.cellRegistrator)
        
        return view
    }()
    
    private func updateItemSize() {
        
        guard let layout = self.collectionViewDelegate.layout else {
            return
        }
        
        let itemsInRow = layoutConfiguration.numberOfAssetItemsInRow
        let scrollDirection = layoutConfiguration.scrollDirection
        let cellSize = layout.sizeForItem(numberOfItemsInRow: itemsInRow, preferredWidthOrHeight: nil, collectionView: collectionView, scrollDirection: scrollDirection)
        let scale = UIScreen.main.scale
        let thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        self.collectionViewDataSource.assetsModel?.thumbnailSize = thumbnailSize
    }
    
    //TODO: this is used temporary, we will need to use proper AVCaptureSession
    fileprivate lazy var cameraController: UIImagePickerController = {
        let controller = UIImagePickerController()
        controller.delegate =  self
        controller.sourceType = .camera
        controller.showsCameraControls = false
        controller.allowsEditing = false
        controller.cameraFlashMode = .off        
        return controller
    }()
    
    // MARK: View Lifecycle
    
    open override func loadView() {
        self.view = collectionView
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let collectionViewLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        collectionViewLayout.scrollDirection = layoutConfiguration.scrollDirection
        collectionViewLayout.minimumInteritemSpacing = layoutConfiguration.interitemSpacing
        collectionViewLayout.minimumLineSpacing = layoutConfiguration.interitemSpacing
        
        switch layoutConfiguration.scrollDirection {
        case .horizontal: collectionView.alwaysBounceHorizontal = true
        case .vertical: collectionView.alwaysBounceVertical = true
        }
        
        PHPhotoLibrary.requestAuthorization { [unowned self] (status) in
            DispatchQueue.main.async {
                
                let configuration = self.layoutConfiguration
                let assetsModel = ImagePickerAssetModel()
                
                assetsModel.fetchResult = self.assetsFetchResultBlock?()
                print("fetched: \(assetsModel.fetchResult.count) photos")
                
                let layoutModel = LayoutModel(configuration: configuration, assets: assetsModel.fetchResult.count)
                
                self.collectionViewDataSource.layoutModel = layoutModel
                self.collectionViewDataSource.assetsModel = assetsModel
                self.collectionViewDataSource.cellRegistrator = self.cellRegistrator
                
                self.collectionViewDelegate.layout = ImagePickerLayout(configuration: configuration)
                self.collectionViewDelegate.delegate = self
                
                self.collectionView.reloadData()
            }
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateItemSize()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        //TODO: this is called each time content offset is changed via scrolling,
        //I am not sure if it's proper behavior, need to find out
        updateItemSize()
    }
    
    //this will make sure that collection view layout is reloaded when interface rotates/changes
    //TODO: we need to reload thumbnail sizes and purge all image asset caches
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }) { (context) in }
        super.viewWillTransition(to: size, with: coordinator)
    }
    
}

extension ImagePickerViewController : ImagePickerDelegateDelegate {
    
    func imagePicker(delegate: ImagePickerDelegate, didSelectActionItemAt index: Int) {
        self.delegate?.imagePicker(controller: self, didSelectActionItemAt: index)
    }
        
    func imagePicker(delegate: ImagePickerDelegate, didSelectAssetItemAt index: Int) {
        guard let asset = collectionViewDataSource.assetsModel?.fetchResult?.object(at: index) else {
            return
        }
        self.delegate?.imagePicker(controller: self, didFinishPicking: asset)
    }
    
    func imagePicker(delegate: ImagePickerDelegate, willDisplayActionCell cell: UICollectionViewCell, at index: Int) {
        self.delegate?.imagePicker(controller: self, willDisplayActionItem: cell, at: index)
    }
    
    func imagePicker(delegate: ImagePickerDelegate, willDisplayAssetCell cell: ImagePickerAssetCell, at index: Int) {
        guard let asset = collectionViewDataSource.assetsModel?.fetchResult?.object(at: index) else {
            return
        }
        self.delegate?.imagePicker(controller: self, willDisplayAssetItem: cell, asset: asset)
    }
    
    func imagePicker(delegate: ImagePickerDelegate, willDisplayCameraCell cell: CameraCollectionViewCell) {
        cell.cameraView = cameraController.view!
        cell.cameraController = cameraController
        //TODO: should start capture session
    }
    
    func imagePicker(delegate: ImagePickerDelegate, didEndDisplayingCameraCell cell: CameraCollectionViewCell) {
        //TODO: should shop capture session
    }
    
}

extension ImagePickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            delegate?.imagePicker(controller: self, didTake: image)
        }
    }
    
}
