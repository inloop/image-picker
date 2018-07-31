// Copyright © 2018 INLOOPX. All rights reserved.

import ImagePicker
import Photos

/// This is an example view controller that shows how Image Picker can be used
class ViewController: UITableViewController, UIDropInteractionDelegate {
    @IBOutlet var dropAssetsView: UIView!
    
    lazy var presentButton: UIButton = {
        let button = UIButton(type: .custom)
        var bottomAdjustment: CGFloat = 0
        if #available(iOS 11.0, *) {
           bottomAdjustment = self.tableView.adjustedContentInset.bottom
        }
        button.frame.size = CGSize(width: 0, height: 44 + bottomAdjustment)
        button.contentEdgeInsets.bottom = bottomAdjustment/2
        button.backgroundColor = UIColor(red: 208/255, green: 2/255, blue: 27/255, alpha: 1)
        button.setTitle("Present", for: .normal)
        button.setTitle("Dismiss", for: .selected)
        button.addTarget(self, action: #selector(presentButtonTapped), for: .touchUpInside)
        return button
    }()
    
    enum CameraItemConfig: Int {
        case enabled
        case disabled
    }
    
    enum AssetsSource: Int {
        case recentlyAdded
        case onlyVideos
        case onlySelfies
    }
    
    var currentInputView: UIView?
    
    // Defaul configuration values
    var presentsModally = false
    var numberOfActionItems = 2
    var cameraConfig: CameraItemConfig = .enabled
    var assetsSource: AssetsSource = .recentlyAdded
    var assetItemsInRow = 2
    var captureMode: CaptureSettings.CameraMode = .photoAndLivePhoto
    var savesCapturedAssets = false
    var dragAndDropConfig = false
    var imagePickerController: ImagePickerController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure global appearance. If you wish to specify appearance per
        // instance simple set appearance() on the instance itself. It will
        // have a precedense over global appearance
        // ImagePickerController.appearance().backgroundColor = UIColor.black
        
        navigationItem.title = "Image Picker"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellId")
        tableView.keyboardDismissMode = .none
        
        if #available(iOS 11.0, *) {
            setupDragDestination()
        }
    }
    
    @objc func togglePresentationMode(indexPath: IndexPath) {
        presentsModally = indexPath.row == 1
    }
    
    @objc func setNumberOfActionItems(indexPath: IndexPath) {
        numberOfActionItems = indexPath.row
    }
    
    @objc func configCameraItem(indexPath: IndexPath) {
        cameraConfig = CameraItemConfig(rawValue: indexPath.row)!
        imagePickerController?.collectionView.reloadData()
    }
    
    @objc func configAssetsSource(indexPath: IndexPath) {
        assetsSource = AssetsSource(rawValue: indexPath.row)!
    }
    
    @objc func configAssetItemsInRow(indexPath: IndexPath) {
        assetItemsInRow = indexPath.row + 1
    }
    
    @objc func configCaptureMode(indexPath: IndexPath) {
        switch indexPath.row {
        case 0: captureMode = .photo
        case 1: captureMode = .photoAndLivePhoto
        case 2: captureMode = .photoAndVideo
        default: break
        }
    }
    
    @objc func configDragAndDrop(indexPath: IndexPath) {
        dragAndDropConfig = indexPath.row == 1
    }
    
    @objc func configSavesCapturedAssets(indexPath: IndexPath) {
        savesCapturedAssets = indexPath.row == 1
    }

    
    @objc func presentButtonTapped() {
        presentButton.isSelected = !presentButton.isSelected
        
        if presentButton.isSelected {
            let imagePicker = ImagePickerController()
            imagePickerController = imagePicker
            
            imagePicker.delegate = self
            imagePicker.dataSource = self
            
            switch numberOfActionItems {
            case 1:
                imagePicker.layoutConfiguration.showsFirstActionItem = true
                imagePicker.layoutConfiguration.showsSecondActionItem = false
                
                // If you wish to register your own action cell register it here,
                // it can by any UICollectionViewCell
                // imagePicker.cellRegistrator.register(nib: UINib(nibName: "IconWithTextCell", bundle: nil), forActionItemAt: 0)
                
            case 2:
                imagePicker.layoutConfiguration.showsFirstActionItem = true
                imagePicker.layoutConfiguration.showsSecondActionItem = true
                
                // If you wish to register your own action cell register it here,
                // it can by any UICollectionViewCell
                // imagePicker.cellRegistrator.registerNibForActionItems(UINib(nibName: "IconWithTextCell", bundle: nil))
                
            default:
                imagePicker.layoutConfiguration.showsFirstActionItem = false
                imagePicker.layoutConfiguration.showsSecondActionItem = false
            }
            
            // Set camera item enabled/disabled
            switch cameraConfig {
            case .enabled:
                imagePicker.layoutConfiguration.showsCameraItem = true
            case .disabled:
                imagePicker.layoutConfiguration.showsCameraItem = false
            }
            
            // Config assets source
            switch assetsSource {
            case .recentlyAdded:
                // For recently added we use default fetch result and default asset cell
                break
            case .onlyVideos:
                
                // Registering custom video cell to demonstrate how to use custom cells
                // please note that custom asset cells must conform to  ImagePickerAssetCell protocol
                
                imagePicker.cellRegistrator.register(nib: UINib(nibName: "CustomVideoCell", bundle: nil), forAssetItemOf: .video)
                imagePicker.assetsFetchResultBlock = {
                    guard let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: nil).firstObject else {
                        return nil //you can return nil if you did not find desired fetch result, default fetch result will be used.
                    }
                    return PHAsset.fetchAssets(in: collection, options: nil)
                }
            case .onlySelfies:
                
                // Registering custom image cell to demonstrate how to use custom cells
                // please note that custom asset cells must conform to  ImagePickerAssetCell protocol
                
                imagePicker.cellRegistrator.registerNibForAssetItems(UINib(nibName: "CustomImageCell", bundle: nil))
                imagePicker.assetsFetchResultBlock = {
                    guard let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: nil).firstObject else {
                        return nil
                    }
                    return PHAsset.fetchAssets(in: collection, options: nil)
                }
            }
            
            // Number of items in a row (supported values > 0)
            imagePicker.layoutConfiguration.numberOfAssetItemsInRow = assetItemsInRow
            
            // Enable assets drag & drop
            imagePicker.layoutConfiguration.enableAssetDragAndDrop = dragAndDropConfig
            
            // capture mode
            switch captureMode {
            case .photo:
                imagePicker.captureSettings.cameraMode = .photo
                
                // If you wish to use your own cell for capturing photos register it here:
                // please note that custom cell must sublcass `CameraCollectionViewCell`.
                // imagePicker.cellRegistrator.registerNibForCameraItem(UINib(nibName: "CustomNibName", bundle: nil))
                
            case .photoAndLivePhoto:
                imagePicker.captureSettings.cameraMode = .photoAndLivePhoto
                
                // Ff you wish to use your own cell for photo and live photo register it here:
                // please note that custom cell must sublcass `CameraCollectionViewCell`.
                // imagePicker.cellRegistrator.registerNibForCameraItem(UINib(nibName: "CustomNibName", bundle: nil))
                
            case .photoAndVideo:
                imagePicker.captureSettings.cameraMode = .photoAndVideo
                
                // If you wish to use your own cell for photo and video register it here:
                // please note that custom cell must sublcass `CameraCollectionViewCell`.
                // imagePicker.cellRegistrator.registerNibForCameraItem(UINib(nibName: "CustomNibName", bundle: nil))
                
            }
            
            // Save capture assets to photo library?
            imagePicker.captureSettings.savesCapturedPhotosToPhotoLibrary = savesCapturedAssets
            presentPicker(imagePicker)
        } else {
            updateNavigationItem(with: 0)
            currentInputView = nil
            reloadInputViews()
        }
    }

    private func presentPicker(_ imagePicker: ImagePickerController) {
        imagePicker.layoutConfiguration.scrollDirection = presentsModally ? .vertical : .horizontal
        if presentsModally {
            presentPickerModally(imagePicker)
        } else {
            presentPickerAsInputView(imagePicker)
        }
    }
    
    func presentPickerAsInputView(_ vc: ImagePickerController) {
        
        // If you want to present view as input view, you have to set flexible height
        // to adopt natural keyboard height or just set an layout constraint height
        // for specific height.
        vc.view.autoresizingMask = .flexibleHeight
        currentInputView = vc.view
        
        reloadInputViews()
    }
    
    func presentPickerModally(_ vc: ImagePickerController) {
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Dismiss", style: .done, target: self, action: #selector(dismissPresentedImagePicker(sender:)))
        let nc = UINavigationController(rootViewController: vc)
        present(nc, animated: true, completion: nil)
    }
    
    @objc func dismissPresentedImagePicker(sender: UIBarButtonItem) {
        updateNavigationItem(with: 0)
        presentButton.isSelected = false
        navigationController?.visibleViewController?.dismiss(animated: true, completion: nil)
    }
    
    func updateNavigationItem(with selectedCount: Int) {
        if selectedCount == 0 {
            navigationController?.visibleViewController?.navigationItem.setRightBarButton(nil, animated: true)
        } else {
            let title = "Items (\(selectedCount))"
            navigationController?.visibleViewController?.navigationItem.setRightBarButton(UIBarButtonItem(title: title, style: .plain, target: nil, action: nil), animated: true)
        }
    }
}
