//
//  ImagePickerController.swift
//  Image Picker
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
        captureSession?.suspend()
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
    public lazy var cellRegistrator = CellRegistrator()
    
    ///
    /// Use these settings to configure how the capturing should behave
    ///
    public var captureSettings = CaptureSettings.default
    
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
    
    ///
    /// Global appearance proxy object. Use this object to set appearance
    /// for all instances of Image Picker. If you wish to set an appearance
    /// on instances use corresponding instance method.
    ///
    public static func appearance() -> Appearance {
        return classAppearanceProxy
    }
    
    ///
    /// Instance appearance proxy object. Use this object to set appearance
    /// for this particular instance of Image Picker. This has precedence over
    /// global appearance.
    ///
    public func appearance() -> Appearance {
        if instanceAppearanceProxy == nil {
            instanceAppearanceProxy = Appearance()
        }
        return instanceAppearanceProxy!
    }
    
    // MARK: Private Methods
    
    fileprivate var collectionViewDataSource = ImagePickerDataSource(assetsModel: ImagePickerAssetModel())
    fileprivate var collectionViewDelegate = ImagePickerDelegate()
    
    fileprivate lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.dataSource = self.collectionViewDataSource
        view.delegate = self.collectionViewDelegate
        return view
    }()
    
    fileprivate var captureSession: CaptureSession?
    
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
    
    /// View is used when there is a need for an overlay view over whole image picker
    /// view hierarchy. For example when there is no permissions to photo library.
    private var overlayView: UIView?
    
    /// Reload collection view layout/data based on authorization status of photo library
    private func reloadData(basedOnAuthorizationStatus status: PHAuthorizationStatus) {
        switch status {
        case .authorized:
            collectionViewDataSource.assetsModel.fetchResult = assetsFetchResultBlock?()
            collectionViewDataSource.layoutModel = LayoutModel(configuration: layoutConfiguration, assets: collectionViewDataSource.assetsModel.fetchResult.count)
            
        case .restricted, .denied:
            if let view = overlayView ?? dataSource?.imagePicker(controller: self, viewForAuthorizationStatus: status), view.superview != collectionView {
                collectionView.backgroundView = view
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
    
    /// Reload camera cell based on authorization status of camera input device (video)
    fileprivate func reloadCameraCell(basedOnAuthorizationStatus status: AVAuthorizationStatus) {
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else {
            return
        }
        cameraCell.authorizationStatus = status
    }
    
    ///appearance object for global instances
    static let classAppearanceProxy = Appearance()
    
    ///appearance object for an instance
    var instanceAppearanceProxy: Appearance?
    
    // MARK: View Lifecycle
    
    open override func loadView() {
        self.view = collectionView
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        //apply appearance
        let appearance = instanceAppearanceProxy ?? ImagePickerController.classAppearanceProxy
        collectionView.backgroundColor = appearance.backgroundColor
        
        //configure flow layout
        let collectionViewLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        collectionViewLayout.scrollDirection = layoutConfiguration.scrollDirection
        collectionViewLayout.minimumInteritemSpacing = layoutConfiguration.interitemSpacing
        collectionViewLayout.minimumLineSpacing = layoutConfiguration.interitemSpacing
        
        //finish configuring collection view
        collectionView.contentInset = layoutConfiguration.contentInset
        collectionView.allowsMultipleSelection = true
        switch layoutConfiguration.scrollDirection {
        case .horizontal: collectionView.alwaysBounceHorizontal = true
        case .vertical: collectionView.alwaysBounceVertical = true
        }

        //gesture recognizer to detect taps on a camera cell (selection is disabled)
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognized(sender:)))
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)
        
        //apply cell registrator to collection view
        collectionView.apply(registrator: cellRegistrator)
        
        //connect all remaining objects as needed
        collectionViewDataSource.cellRegistrator = cellRegistrator
        collectionViewDelegate.delegate = self
        collectionViewDelegate.layout = ImagePickerLayout(configuration: layoutConfiguration)

        //register for photo library updates - this is needed when changing permissions to photo library
        //TODO: this is expensive (loading library for the first time)
        PHPhotoLibrary.shared().register(self)
        
        //determine auth satus and based on that reload UI
        reloadData(basedOnAuthorizationStatus: PHPhotoLibrary.authorizationStatus())
        
        //configure capture session
        if layoutConfiguration.showsCameraItem {
            let session = CaptureSession()
            captureSession = session
            session.presetConfiguration = captureSettings.cameraMode.captureSessionPresetConfiguration
            session.saveCapturedAssetsToPhotoLibrary = captureSettings.savesCapturedAssetToPhotoLibrary
            session.videoOrientation = UIApplication.shared.statusBarOrientation.captureVideoOrientation
            session.delegate = self
            session.videoRecordingDelegate = self
            session.photoCapturingDelegate = self
            session.prepare()
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
        
        //update safe area insets only once
        //TODO: implement support for iPhone X 
//        if #available(iOS 11.0, *) {
//            if collectionView.contentInset != view.safeAreaInsets {
//                collectionView.contentInset = view.safeAreaInsets
//            }
//        }
    }
    
    //this will make sure that collection view layout is reloaded when interface rotates/changes
    //TODO: we need to reload thumbnail sizes and purge all image asset caches
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        //update capture session with new interface orientation
        captureSession?.updateVideoOrientation(new: UIApplication.shared.statusBarOrientation.captureVideoOrientation)
        
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
    
    // MARK: Private Methods
    
    @objc private func tapGestureRecognized(sender: UIGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else {
            return
        }
        
        let point = sender.location(in: cameraCell)
        if cameraCell.touchIsCaptureEffective(point: point) {
            takePicture()
        }
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
                
                let assetItemsSection = layoutConfiguration.sectionIndexForAssets
                
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
        
        //setup cell if needed
        if cell.delegate == nil {
            cell.delegate = self
            cell.previewView.session = captureSession?.session
            captureSession?.previewLayer = cell.previewView.previewLayer
            
            //when using videos preset, we are using different technique for
            //blurring the cell content. If isVisualEffectViewUsedForBlurring is
            //true, then UIVisualEffectView is used for blurring. In other cases
            //we manually blur video data output frame (it's faster). Reason why
            //we have 2 different blurring techniques is that the faster solution
            //can not be used when we have .video preset configuration.
            if let config = captureSession?.presetConfiguration, config == .videos {
                cell.isVisualEffectViewUsedForBlurring = true
            }
            
        }
        
        //update live photos
        let inProgressLivePhotos = captureSession?.inProgressLivePhotoCapturesCount ?? 0
        cell.updateLivePhotoStatus(isProcessing: inProgressLivePhotos > 0, shouldAnimate: false)
        
        //update video recording status
        let isRecordingVideo = captureSession?.isRecordingVideo ?? false
        cell.updateRecordingVideoStatus(isRecording: isRecordingVideo, shouldAnimate: false)
        
        //update authorization status if it's changed
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if cell.authorizationStatus != status {
            cell.authorizationStatus = status
        }
        
        //resume session only if not recording video
        if isRecordingVideo == false {
            captureSession?.resume()
        }
    }
    
    func imagePicker(delegate: ImagePickerDelegate, didEndDisplayingCameraCell cell: CameraCollectionViewCell) {
        
        let isRecordingVideo = captureSession?.isRecordingVideo ?? false
        
        //susped session only if not recording video, otherwise the recording would be stopped.
        if isRecordingVideo == false {
            captureSession?.suspend()
        }
        
        // blur cell asap
        DispatchQueue.global(qos: .userInteractive).async {
            if let image = self.captureSession?.latestVideoBufferImage {
                let blurred = UIImageEffects.imageByApplyingLightEffect(to: image)
                DispatchQueue.main.async {
                    cell.blurIfNeeded(blurImage: blurred, animated: false, completion: nil)
                }
            }
            else {
                DispatchQueue.main.async {
                    cell.blurIfNeeded(blurImage: nil, animated: false, completion: nil)
                }
            }
        }
    }
    
    func imagePicker(delegate: ImagePickerDelegate, didScroll scrollView: UIScrollView) {
        //update only if the view is visible.
        //TODO: precaching is not enabled for now (it's laggy need to profile)
        //guard isViewLoaded && view.window != nil else { return }
        //collectionViewDataSource.assetsModel.updateCachedAssets(collectionView: collectionView)
    }
}

extension ImagePickerController : CaptureSessionDelegate {
    
    func captureSessionDidResume(_ session: CaptureSession) {
        log("did resume")
        unblurCellIfNeeded(animated: true)
    }
    
    func captureSessionDidSuspend(_ session: CaptureSession) {
        log("did suspend")
        blurCellIfNeeded(animated: true)
    }
    
    func captureSession(_ session: CaptureSession, didFail error: AVError) {
        log("did fail")
    }
    
    func captureSessionDidFailConfiguringSession(_ session: CaptureSession) {
        log("did fail configuring")
    }
    
    func captureSession(_ session: CaptureSession, authorizationStatusFailed status: AVAuthorizationStatus) {
        log("did fail authorization to camera")
        reloadCameraCell(basedOnAuthorizationStatus: status)
    }
    
    func captureSession(_ session: CaptureSession, authorizationStatusGranted status: AVAuthorizationStatus) {
        log("did grant authorization to camera")
        reloadCameraCell(basedOnAuthorizationStatus: status)
    }
    
    func captureSession(_ session: CaptureSession, wasInterrupted reason: AVCaptureSession.InterruptionReason) {
        log("interrupted")
    }
    
    func captureSessionInterruptionDidEnd(_ session: CaptureSession) {
        log("interruption ended")
    }
    
    private func blurCellIfNeeded(animated: Bool) {
        
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else { return }
        guard let captureSession = captureSession else { return }
        
        cameraCell.blurIfNeeded(blurImage: captureSession.latestVideoBufferImage, animated: animated, completion: nil)
    }
    
    private func unblurCellIfNeeded(animated: Bool) {
        
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else {
            return
        }
        
        cameraCell.unblurIfNeeded(unblurImage: nil, animated: animated, completion: nil)
    }
    
}

extension ImagePickerController : CaptureSessionPhotoCapturingDelegate {
    
    func captureSession(_ session: CaptureSession, didCapturePhotoData: Data, with settings: AVCapturePhotoSettings) {
        log("did capture photo \(settings.uniqueID)")
        delegate?.imagePicker(controller: self, didTake: UIImage(data: didCapturePhotoData)!)
    }
    
    func captureSession(_ session: CaptureSession, willCapturePhotoWith settings: AVCapturePhotoSettings) {
        log("will capture photo \(settings.uniqueID)")
    }
    
    func captureSession(_ session: CaptureSession, didFailCapturingPhotoWith error: Error) {
        log("did fail capturing: \(error)")
    }
    
    func captureSessionDidChangeNumberOfProcessingLivePhotos(_ session: CaptureSession) {
        
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else {
            return
        }
        
        let count = session.inProgressLivePhotoCapturesCount
        cameraCell.updateLivePhotoStatus(isProcessing: count > 0, shouldAnimate: true)
    }
}

extension ImagePickerController : CaptureSessionVideoRecordingDelegate {
    
    func captureSessionDidBecomeReadyForVideoRecording(_ session: CaptureSession) {
        log("ready for video recording")
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else { return }
        cameraCell.videoRecodingDidBecomeReady()
    }
    
    func captureSessionDidStartVideoRecording(_ session: CaptureSession) {
        log("did start video recording")
        updateCameraCellRecordingStatusIfNeeded(isRecording: true, animated: true)
    }
    
    func captureSessionDidCancelVideoRecording(_ session: CaptureSession) {
        log("did cancel video recording")
        updateCameraCellRecordingStatusIfNeeded(isRecording: false, animated: true)
    }
    
    func captureSessionDid(_ session: CaptureSession, didFinishVideoRecording videoURL: URL) {
        log("did finish video recording")
        updateCameraCellRecordingStatusIfNeeded(isRecording: false, animated: true)
    }
    
    func captureSessionDid(_ session: CaptureSession, didInterruptVideoRecording videoURL: URL, reason: Error) {
        log("did interrupt video recording, reason: \(reason)")
        updateCameraCellRecordingStatusIfNeeded(isRecording: false, animated: true)
    }
    
    func captureSessionDid(_ session: CaptureSession, didFailVideoRecording error: Error) {
        log("did fail video recording")
        updateCameraCellRecordingStatusIfNeeded(isRecording: false, animated: true)
    }
    
    private func updateCameraCellRecordingStatusIfNeeded(isRecording: Bool, animated: Bool) {
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else { return }
        cameraCell.updateRecordingVideoStatus(isRecording: isRecording, shouldAnimate: animated)
    }
    
}

extension ImagePickerController: CameraCollectionViewCellDelegate {
    
    func takePicture() {
        captureSession?.capturePhoto(livePhotoMode: .off)
    }
    
    func takeLivePhoto() {
        captureSession?.capturePhoto(livePhotoMode: .on)
    }
    
    func startVideoRecording() {
        captureSession?.startVideoRecording()
    }
    
    func stopVideoRecording() {
        captureSession?.stopVideoRecording(cancel: false)
    }
    
    func flipCamera(_ completion: (() -> Void)? = nil) {
        
        guard let captureSession = captureSession else { return  }
        
        guard let cameraCell = collectionView.cameraCell(layout: layoutConfiguration) else {
            return captureSession.changeCamera(completion: completion)
        }
        
        var image = captureSession.latestVideoBufferImage
        if image != nil {
            image = UIImageEffects.imageByApplyingLightEffect(to: image!)
        }
        
        // 1. blur cell
        cameraCell.blurIfNeeded(blurImage: image, animated: true) { _ in
            
            // 2. flip camera
            captureSession.changeCamera(completion: {
                
                // 3. flip animation
                UIView.transition(with: cameraCell.previewView, duration: 0.25, options: [.transitionFlipFromLeft, .allowAnimatedContent], animations: nil) { (finished) in
                    
                    //set new image from buffer
                    var image = captureSession.latestVideoBufferImage
                    if image != nil {
                        image = UIImageEffects.imageByApplyingLightEffect(to: image!)
                    }
                    
                    // 4. unblur
                    cameraCell.unblurIfNeeded(unblurImage: image, animated: true, completion: { _ in
                        completion?()
                    })
                }
            })
            
        }
    }
    
}
