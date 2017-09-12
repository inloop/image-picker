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

///
/// Group of methods informing what image picker is currently doing
///
public protocol ImagePickerViewControllerDelegate : class {
    
    ///
    /// Called when user taps on an action item, index is either 0 or 1 depending which was tapped
    ///
    func imagePicker(controller: ImagePickerViewController, didSelectActionItemAt index: Int)
    
    ///
    /// Called when user select an asset
    ///
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


///
/// Image picker may ask for additional resources, implement this protocol to fully support
/// all features.
///
public protocol ImagePickerViewControllerDataSource : class {
    ///
    /// Asks for a view that is placed as overlay view with permissions info
    /// when user did not grant or has restricted access to photo library.
    ///
    func imagePicker(controller: ImagePickerViewController,  viewForAuthorizationStatus status: PHAuthorizationStatus) -> UIView
}

open class ImagePickerViewController : UIViewController {
   
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
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
    public var cellRegistrator: CellRegistrator?
    
    ///
    /// Get informed about user interaction and changes
    ///
    public weak var delegate: ImagePickerViewControllerDelegate?
    
    ///
    /// Provide additional data when requested by Image Picker
    ///
    public weak var dataSource: ImagePickerViewControllerDataSource?
    
    ///
    /// Access all currently selected images
    ///
    public var selectedAssets: [PHAsset] {
        get {
            let selectedIndexPaths = collectionView.indexPathsForSelectedItems ?? []
            let selectedAssets = selectedIndexPaths.flatMap { indexPath in
                return collectionViewDataSource.assetsModel.fetchResult.object(at: indexPath.row)
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
    
    fileprivate var collectionViewDataSource = ImagePickerDataSource(assetsModel: ImagePickerAssetModel())
    fileprivate var collectionViewDelegate = ImagePickerDelegate()
    
    fileprivate lazy var collectionView: UICollectionView = {
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.backgroundColor = UIColor.red
        view.contentInset = UIEdgeInsets.zero
        view.dataSource = self.collectionViewDataSource
        view.delegate = self.collectionViewDelegate
        view.allowsMultipleSelection = true

        return view
    }()
    
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
    
    private func updateItemSize() {
        
        guard let layout = self.collectionViewDelegate.layout else {
            return
        }
        
        let itemsInRow = layoutConfiguration.numberOfAssetItemsInRow
        let scrollDirection = layoutConfiguration.scrollDirection
        let cellSize = layout.sizeForItem(numberOfItemsInRow: itemsInRow, preferredWidthOrHeight: nil, collectionView: collectionView, scrollDirection: scrollDirection)
        let scale = UIScreen.main.scale
        let thumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)
        self.collectionViewDataSource.assetsModel.thumbnailSize = thumbnailSize
    }
    
    private var overlayView: UIView?
    
    private func reloadData(basedOnAuthorizationStatus status: PHAuthorizationStatus) {
        switch status {
        case .authorized:
            
            collectionViewDataSource.assetsModel.fetchResult = assetsFetchResultBlock?()
            collectionViewDataSource.layoutModel = LayoutModel(configuration: layoutConfiguration, assets: collectionViewDataSource.assetsModel.fetchResult.count)
            
            overlayView?.removeFromSuperview()
            overlayView = nil
            
        case .restricted, .denied:
            
            print("access to photo library is denied or restricted")
            if let view = overlayView ?? dataSource?.imagePicker(controller: self, viewForAuthorizationStatus: status), view.superview != collectionView {
                self.view.addSubview(view)
                view.translatesAutoresizingMaskIntoConstraints = false
                let views = ["overlayView": view, "topGuide": topLayoutGuide, "bottomGuide": bottomLayoutGuide] as [String : Any]
                self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[overlayView]-0-|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: views))
                self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[topGuide][overlayView][bottomGuide]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: views))
                overlayView = view
            }
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                DispatchQueue.main.async {
                    self.reloadData(basedOnAuthorizationStatus: status)
                }
            })
        }
    }
    
    // MARK: View Lifecycle
    
    open override func loadView() {
        self.view = collectionView
//        self.view.addSubview(collectionView)
//        collectionView.translatesAutoresizingMaskIntoConstraints = false
//        let views = ["overlayView": collectionView, "topGuide": topLayoutGuide, "bottomGuide": bottomLayoutGuide] as [String : Any]
//        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[overlayView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: views))
//        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[overlayView]|", options: NSLayoutFormatOptions.init(rawValue: 0), metrics: nil, views: views))
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        //configure flow layout
        let collectionViewLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        collectionViewLayout.scrollDirection = layoutConfiguration.scrollDirection
        collectionViewLayout.minimumInteritemSpacing = layoutConfiguration.interitemSpacing
        collectionViewLayout.minimumLineSpacing = layoutConfiguration.interitemSpacing
        
        //make sure collection view is bouncing nicely
        switch layoutConfiguration.scrollDirection {
        case .horizontal: collectionView.alwaysBounceHorizontal = true
        case .vertical: collectionView.alwaysBounceVertical = true
        }

        //apply cell registrator to collection view
        guard let cellRegistrator = self.cellRegistrator else { fatalError("at the time of viewDidLoad a cell registrator must be set") }
        collectionView.apply(registrator: cellRegistrator)
        
        //connect all remaining objects as needed
        self.collectionViewDataSource.cellRegistrator = self.cellRegistrator
        self.collectionViewDelegate.delegate = self
        self.collectionViewDelegate.layout = ImagePickerLayout(configuration: layoutConfiguration)

        //rgister for photo library updates - this is needed when changing permissions to photo library
        PHPhotoLibrary.shared().register(self)
        
        //determine auth satus and based on that reload UI
        reloadData(basedOnAuthorizationStatus: PHPhotoLibrary.authorizationStatus())
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

extension ImagePickerViewController: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let fetchResult = collectionViewDataSource.assetsModel.fetchResult else {
            return
        }
        
        guard let changes = changeInstance.changeDetails(for: fetchResult) else {
            return
        }
        
        DispatchQueue.main.sync {
            
            //update old fetch result with these updates
            collectionViewDataSource.assetsModel.fetchResult = changes.fetchResultAfterChanges

            //update layout model because it changed
            collectionViewDataSource.layoutModel = LayoutModel(configuration: layoutConfiguration, assets: collectionViewDataSource.assetsModel.fetchResult.count)
            
            if changes.hasIncrementalChanges {
                
                //TODO: this must be access from layout model, not hardcoded
                let assetItemsSection: Int = 2
                
                // If we have incremental diffs, animate them in the collection view
                self.collectionView.performBatchUpdates({
                    
                    // For indexes to make sense, updates must be in this order:
                    // delete, insert, reload, move
                    if let removed = changes.removedIndexes, removed.isEmpty == false {
                        collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: assetItemsSection) }))
                    }
                    if let inserted = changes.insertedIndexes, inserted.isEmpty == false {
                        collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: assetItemsSection) }))
                    }
                    if let changed = changes.changedIndexes, changed.isEmpty == false {
                        collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: assetItemsSection) }))
                    }
                    changes.enumerateMoves { fromIndex, toIndex in
                        self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: assetItemsSection), to: IndexPath(item: toIndex, section: assetItemsSection))
                    }
                })
            }
            else {
                // Reload the collection view if incremental diffs are not available.
                collectionView.reloadData()
            }
            //resetCachedAssets()
        }
    }
}

extension ImagePickerViewController : ImagePickerDelegateDelegate {
    
    func imagePicker(delegate: ImagePickerDelegate, didSelectActionItemAt index: Int) {
        self.delegate?.imagePicker(controller: self, didSelectActionItemAt: index)
    }
        
    func imagePicker(delegate: ImagePickerDelegate, didSelectAssetItemAt index: Int) {
        guard let asset = collectionViewDataSource.assetsModel.fetchResult?.object(at: index) else {
            return
        }
        self.delegate?.imagePicker(controller: self, didFinishPicking: asset)
    }
    
    func imagePicker(delegate: ImagePickerDelegate, willDisplayActionCell cell: UICollectionViewCell, at index: Int) {
        self.delegate?.imagePicker(controller: self, willDisplayActionItem: cell, at: index)
    }
    
    func imagePicker(delegate: ImagePickerDelegate, willDisplayAssetCell cell: ImagePickerAssetCell, at index: Int) {
        guard let asset = collectionViewDataSource.assetsModel.fetchResult?.object(at: index) else {
            return
        }
        self.delegate?.imagePicker(controller: self, willDisplayAssetItem: cell, asset: asset)
    }
    
    func imagePicker(delegate: ImagePickerDelegate, willDisplayCameraCell cell: CameraCollectionViewCell) {
        //TODO: accessing camera controller this way is too expensive - it can take up to 3 seconds
        cell.cameraView = cameraController.view!
        cell.delegate = self
        
        //TODO: should start capture session
    }
    
    func imagePicker(delegate: ImagePickerDelegate, didEndDisplayingCameraCell cell: CameraCollectionViewCell) {
        //TODO: should shop capture session
    }
    
}

extension ImagePickerViewController: CameraCollectionViewCellDelegate {
    
    func takePicture() {
        cameraController.takePicture()
    }
    
    func flipCamera() {
        cameraController.cameraDevice = (cameraController.cameraDevice == .rear) ? .front : .rear
    }
    
}

extension ImagePickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            delegate?.imagePicker(controller: self, didTake: image)
        }
    }
    
}
