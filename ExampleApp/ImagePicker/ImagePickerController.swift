//
//  ImagePickerController.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit
import Photos
//import AVFoundation

///
/// Group of methods informing what image picker is currently doing
///
public protocol ImagePickerControllerDelegate : class {
    
    ///
    /// Called when user taps on an action item, index is either 0 or 1 depending which was tapped
    ///
    func imagePicker(controller: ImagePickerController, didSelectActionItemAt index: Int)
    
    ///
    /// Called when user select an asset
    ///
    func imagePicker(controller: ImagePickerController, didFinishPicking asset: PHAsset)
    
    //perhaps we can use method above and remove this one, client does not care if user took a picture or
    //picked it from a library, to do that we perhaps have to save taken image to photo library
    func imagePicker(controller: ImagePickerController, didTake image: UIImage)
    
    ///
    /// Called right before an action item collection view cell is displayed. Use this method
    /// to configure your cell.
    ///
    func imagePicker(controller: ImagePickerController, willDisplayActionItem cell: UICollectionViewCell, at index: Int)
    
    ///
    /// Called right before an asset item collection view cell is displayed. Use this method
    /// to configure your cell based on asset media type, subtype, etc.
    ///
    func imagePicker(controller: ImagePickerController, willDisplayAssetItem cell: ImagePickerAssetCell, asset: PHAsset)
}

//this will make sure all delegate methods are optional
extension ImagePickerControllerDelegate {
    public func imagePicker(controller: ImagePickerController, didSelectActionItemAt index: Int) {}
    public func imagePicker(controller: ImagePickerController, didFinishPicking asset: PHAsset) {}
    public func imagePicker(controller: ImagePickerController, didTake image: UIImage) {}
    public func imagePicker(controller: ImagePickerController, willDisplayActionItem cell: UICollectionViewCell, at index: Int) {}
    public func imagePicker(controller: ImagePickerController, willDisplayAssetItem cell: ImagePickerAssetCell, asset: PHAsset) {}
}


///
/// Image picker may ask for additional resources, implement this protocol to fully support
/// all features.
///
public protocol ImagePickerControllerDataSource : class {
    ///
    /// Asks for a view that is placed as overlay view with permissions info
    /// when user did not grant or has restricted access to photo library.
    ///
    func imagePicker(controller: ImagePickerController,  viewForAuthorizationStatus status: PHAuthorizationStatus) -> UIView
}

open class ImagePickerController : UIViewController {
   
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        captureSession.suspend()
        log("deinit: \(String(describing: self))")
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
    public weak var delegate: ImagePickerControllerDelegate?
    
    ///
    /// Provide additional data when requested by Image Picker
    ///
    public weak var dataSource: ImagePickerControllerDataSource?
    
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
    
    fileprivate let captureSession = CaptureSession()
    
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
            
        case .restricted, .denied:
            if let view = overlayView ?? dataSource?.imagePicker(controller: self, viewForAuthorizationStatus: status), view.superview != collectionView {
                collectionView.backgroundView = view
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
        collectionViewDataSource.cellRegistrator = cellRegistrator
        collectionViewDelegate.delegate = self
        collectionViewDelegate.layout = ImagePickerLayout(configuration: layoutConfiguration)

        //rgister for photo library updates - this is needed when changing permissions to photo library
        PHPhotoLibrary.shared().register(self)
        
        //determine auth satus and based on that reload UI
        reloadData(basedOnAuthorizationStatus: PHPhotoLibrary.authorizationStatus())
        
        //configure capture session
        captureSession.delegate = self
        captureSession.videoRecordingDelegate = self
        captureSession.photoCapturingDelegate = self
        captureSession.prepare()
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
        
        //update safe area insets only once
        if #available(iOS 11.0, *) {
            if collectionView.contentInset != view.safeAreaInsets {
                collectionView.contentInset = view.safeAreaInsets
            }
        }
    }
    
    //this will make sure that collection view layout is reloaded when interface rotates/changes
    //TODO: we need to reload thumbnail sizes and purge all image asset caches
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        //update video orientation at this time status bar orientation has new value so lets convert it to video orientation
        captureSession.previewLayer?.connection?.videoOrientation = UIApplication.shared.statusBarOrientation.captureVideoOrientation
        
        //TODO: add support for upadating safe area and content inset when rotating, this is
        //problem because at this point of execution safe are does not have new values
        //update safe area insets only once
//        if #available(iOS 11.0, *) {
//            self.collectionView.contentInset = self.view.safeAreaInsets
//        }
        
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }) { (context) in
            
        }
        super.viewWillTransition(to: size, with: coordinator)
    }
    
}

extension ImagePickerController: PHPhotoLibraryChangeObserver {
    
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        
        guard let fetchResult = collectionViewDataSource.assetsModel.fetchResult else {
            return
        }
        
        DispatchQueue.main.sync {
        
            guard let changes = changeInstance.changeDetails(for: fetchResult) else {
                //reload collection view
                self.collectionView.reloadData()
                return
            }
            
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
                        self.collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: assetItemsSection) }))
                    }
                    if let inserted = changes.insertedIndexes, inserted.isEmpty == false {
                        self.collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: assetItemsSection) }))
                    }
                    if let changed = changes.changedIndexes, changed.isEmpty == false {
                        self.collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: assetItemsSection) }))
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

extension ImagePickerController : ImagePickerDelegateDelegate {
    
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
        
        if cell.delegate == nil {
            cell.delegate = self
            cell.previewView.session = captureSession.session
            captureSession.previewLayer = cell.previewView.previewLayer
        }
        
        captureSession.resume()
    }
    
    func imagePicker(delegate: ImagePickerDelegate, didEndDisplayingCameraCell cell: CameraCollectionViewCell) {
        captureSession.suspend()
    }
    
}

extension ImagePickerController : CaptureSessionDelegate {
    
    func captureSessionDidResume(_ session: CaptureSession) {
        log("did resume")
    }
    
    func captureSessionDidSuspend(_ session: CaptureSession) {
        log("did suspend")
    }
    
    func captureSession(_ session: CaptureSession, didFail error: AVError) {
        log("did fail")
    }
    
    func captureSessionDidFailConfiguringSession(_ session: CaptureSession) {
        log("did fail configuring")
    }
    
    func captureSession(_ session: CaptureSession, authorizationStatusFailed status: AVAuthorizationStatus) {
        log("did fail authorization")
    }
    
    func captureSession(_ session: CaptureSession, wasInterrupted reason: AVCaptureSessionInterruptionReason) {
        log("interrupted")
    }
    
    func captureSessionInterruptionDidEnd(_ session: CaptureSession) {
        log("interruption ended")
    }
    
}

extension ImagePickerController : CaptureSessionPhotoCapturingDelegate {
    
    func captureSession(_ session: CaptureSession, didCapturePhotoData: Data, with settings: AVCapturePhotoSettings) {
        log("did capture photo \(settings.uniqueID)")
        self.delegate?.imagePicker(controller: self, didTake: UIImage(data: didCapturePhotoData)!)
    }
    
    func captureSession(_ session: CaptureSession, willCapturePhotoWith settings: AVCapturePhotoSettings) {
        log("will capture photo \(settings.uniqueID)")
    }
    
    func captureSession(_ session: CaptureSession, didFailCapturingPhotoWith error: Error) {
        log("did fail capturing: \(error)")
    }
}

extension ImagePickerController : CaptureSessionVideoRecordingDelegate {
    
    func captureSessionDidBecomeReadyForVideoRecording(_ session: CaptureSession) {
        log("ready for video recording")
    }
    
    func captureSessionDidStartVideoRecording(_ session: CaptureSession) {
        log("did start video recording")
    }
    
    func captureSessionDidCancelVideoRecording(_ session: CaptureSession) {
        log("did cancel video recording")
    }
    
    func captureSessionDid(_ session: CaptureSession, didFinishVideoRecording videoURL: URL) {
        log("did finish video recording")
    }
    
    func captureSessionDid(_ session: CaptureSession, didFailVideoRecording error: Error) {
        log("did fail video recording")
    }
    
}

extension ImagePickerController: CameraCollectionViewCellDelegate {
    
    func takePicture() {
        //TODO: cameraController.takePicture()
        captureSession.capturePhoto()
    }
    
    func flipCamera() {
        //TODO: cameraController.cameraDevice = (cameraController.cameraDevice == .rear) ? .front : .rear
    }
    
}
