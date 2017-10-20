//
//  ViewController.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import UIKit
import ImagePicker
import Photos

let cellsData: [[CellData]] = [
    [
        CellData("As input view", #selector(ViewController.togglePresentationMode(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.presentsModally ? .none : .checkmark }),
        CellData("Modally", #selector(ViewController.togglePresentationMode(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.presentsModally ? .checkmark : .none })
    ],
    [
        CellData("Disabled", #selector(ViewController.setNumberOfActionItems(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.numberOfActionItems == 0 ? .checkmark : .none }),
        CellData("One item", #selector(ViewController.setNumberOfActionItems(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.numberOfActionItems == 1 ? .checkmark : .none }),
        CellData("Two items (default)", #selector(ViewController.setNumberOfActionItems(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.numberOfActionItems == 2 ? .checkmark : .none }),
    ],
    [
        CellData("Enabled (default)", #selector(ViewController.configCameraItem(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.cameraConfig == .enabled ? .checkmark : .none }),
        CellData("Disabled", #selector(ViewController.configCameraItem(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.cameraConfig == .disabled ? .checkmark : .none })
    ],
    [
        CellData("Camera Roll (default)", #selector(ViewController.configAssetsSource(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.assetsSource == .recentlyAdded ? .checkmark : .none }),
        CellData("Only videos", #selector(ViewController.configAssetsSource(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.assetsSource == .onlyVideos ? .checkmark : .none }),
        CellData("Only selfies", #selector(ViewController.configAssetsSource(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.assetsSource == .onlySelfies ? .checkmark : .none })
    ],
    [
        CellData("One", #selector(ViewController.configAssetItemsInRow(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.assetItemsInRow == 1 ? .checkmark : .none }),
        CellData("Two (default)", #selector(ViewController.configAssetItemsInRow(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.assetItemsInRow == 2 ? .checkmark : .none }),
        CellData("Three", #selector(ViewController.configAssetItemsInRow(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.assetItemsInRow == 3 ? .checkmark : .none })
    ],
    [
        CellData("Only Photos (default)", #selector(ViewController.configCaptureMode(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.captureMode == .photo ? .checkmark : .none }),
        CellData("Photos and Live Photos", #selector(ViewController.configCaptureMode(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.captureMode == .photoAndLivePhoto ? .checkmark : .none }),
        CellData("Photos and Videos", #selector(ViewController.configCaptureMode(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.captureMode == .photoAndVideo ? .checkmark : .none })
    ],
    [
        CellData("Don't save (default)", #selector(ViewController.configSavesCapturedAssets(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.savesCapturedAssets ? .none : .checkmark }),
        CellData("Save", #selector(ViewController.configSavesCapturedAssets(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.savesCapturedAssets ? .checkmark : .none }),
        ]
]

let sectionsData: [(String?, String?)] = [
    ("Presentation", nil),
    ("Action Items", nil),
    ("Camera Item", nil),
    ("Assets Source", nil),
    ("Asset Items in a row", nil),
    ("Capture mode", nil),
    ("Save Assets", "Assets will be saved to Photo Library")
]

///
/// This is an example view controller that shows how Image Picker can be used
///
class ViewController: UITableViewController {
    
    var currentInputView: UIView?
    var presentButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame.size = CGSize(width: 0, height: 44)
        button.backgroundColor = UIColor(red: 208/255, green: 2/255, blue: 27/255, alpha: 1)
        button.setTitle("Present", for: .normal)
        button.setTitle("Dismiss", for: .selected)
        button.addTarget(self, action: #selector(presentButtonTapped(sender:)), for: .touchUpInside)
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
    
    //defaul configuration values
    var presentsModally: Bool = false
    var numberOfActionItems: Int = 2
    var cameraConfig: CameraItemConfig = .enabled
    var assetsSource: AssetsSource = .recentlyAdded
    var assetItemsInRow: Int = 2
    var captureMode: CaptureSettings.CameraMode = .photoAndLivePhoto
    var savesCapturedAssets: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Configure global appearance. If you wish to specify appearance per
        //instance simple set appearance() on the instance itself. It will
        //have a precedense over global appearance
        //ImagePickerController.appearance().backgroundColor = UIColor.black
        
        navigationItem.title = "Image Picker"
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellId")
        tableView.keyboardDismissMode = .none
    }

    @objc func togglePresentationMode(indexPath: IndexPath) {
        presentsModally = indexPath.row == 1
    }
    
    @objc func setNumberOfActionItems(indexPath: IndexPath) {
        numberOfActionItems = indexPath.row
    }
    
    @objc func configCameraItem(indexPath: IndexPath) {
        cameraConfig = CameraItemConfig(rawValue: indexPath.row)!
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
    
    @objc func configSavesCapturedAssets(indexPath: IndexPath) {
        savesCapturedAssets = indexPath.row == 1
    }
    
    @objc func presentButtonTapped(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            
            // create new instance
            let imagePicker = ImagePickerController()
            
            // set data source and delegate
            imagePicker.delegate = self
            imagePicker.dataSource = self
            
            // set action items
            switch numberOfActionItems {
            case 1:
                imagePicker.layoutConfiguration.showsFirstActionItem = true
                imagePicker.layoutConfiguration.showsSecondActionItem = false
                //if you wish to register your own action cell register it here,
                //it can by any UICollectionViewCell
                //imagePicker.cellRegistrator.register(nib: UINib(nibName: "IconWithTextCell", bundle: nil), forActionItemAt: 0)
            case 2:
                imagePicker.layoutConfiguration.showsFirstActionItem = true
                imagePicker.layoutConfiguration.showsSecondActionItem = true
                //if you wish to register your own action cell register it here,
                //it can by any UICollectionViewCell
                //imagePicker.cellRegistrator.registerNibForActionItems(UINib(nibName: "IconWithTextCell", bundle: nil))
            default:
                imagePicker.layoutConfiguration.showsFirstActionItem = false
                imagePicker.layoutConfiguration.showsSecondActionItem = false
            }
            
            // set camera item enabled/disabled
            switch cameraConfig {
            case .enabled:
                imagePicker.layoutConfiguration.showsCameraItem = true
            case .disabled:
                imagePicker.layoutConfiguration.showsCameraItem = false
            }
            
            // config assets source
            switch assetsSource {
            case .recentlyAdded:
                //for recently added we use default fetch result and default asset cell
                break
            case .onlyVideos:
                //registering custom video cell to demonstrate how to use custom cells
                //please note that custom asset cells must conform to  ImagePickerAssetCell protocol
                imagePicker.cellRegistrator.register(nib: UINib(nibName: "CustomVideoCell", bundle: nil), forAssetItemOf: .video)
                imagePicker.assetsFetchResultBlock = {
                    guard let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: nil).firstObject else {
                        return nil //you can return nil if you did not find desired fetch result, default fetch result will be used.
                    }
                    return PHAsset.fetchAssets(in: collection, options: nil)
                }
            case .onlySelfies:
                //registering custom image cell to demonstrate how to use custom cells
                //please note that custom asset cells must conform to  ImagePickerAssetCell protocol
                imagePicker.cellRegistrator.registerNibForAssetItems(UINib(nibName: "CustomImageCell", bundle: nil))
                imagePicker.assetsFetchResultBlock = {
                    guard let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: nil).firstObject else {
                        return nil
                    }
                    return PHAsset.fetchAssets(in: collection, options: nil)
                }
            }
            
            // number of items in a row (supported values > 0)
            imagePicker.layoutConfiguration.numberOfAssetItemsInRow = assetItemsInRow
            
            // capture mode
            switch captureMode {
            case .photo:
                imagePicker.captureSettings.cameraMode = .photo
                //if you wish to use your own cell for capturing photos register it here:
                //please note that custom cell must sublcass `CameraCollectionViewCell`.
                //imagePicker.cellRegistrator.registerNibForCameraItem(UINib(nibName: "CustomNibName", bundle: nil))
            case .photoAndLivePhoto:
                imagePicker.captureSettings.cameraMode = .photoAndLivePhoto
                //if you wish to use your own cell for photo and live photo register it here:
                //please note that custom cell must sublcass `CameraCollectionViewCell`.
                //imagePicker.cellRegistrator.registerNibForCameraItem(UINib(nibName: "CustomNibName", bundle: nil))
            case .photoAndVideo:
                imagePicker.captureSettings.cameraMode = .photoAndVideo
                //if you wish to use your own cell for photo and video register it here:
                //please note that custom cell must sublcass `CameraCollectionViewCell`.
                //imagePicker.cellRegistrator.registerNibForCameraItem(UINib(nibName: "CustomNibName", bundle: nil))
            }
            
            // save capture assets to photo library?
            imagePicker.captureSettings.savesCapturedAssetToPhotoLibrary = savesCapturedAssets
            
            // presentation
            // before we present VC we can ask for authorization to photo library,
            // if we dont do it now, Image Picker will ask for it automatically
            // after it's presented.
            PHPhotoLibrary.requestAuthorization({ [unowned self] (_) in
                DispatchQueue.main.async {
                    // we can present VC regardless of status because we support
                    // non granted states in Image Picker. Please check `ImagePickerControllerDataSource`
                    // for more info.
                    if self.presentsModally {
                        imagePicker.layoutConfiguration.scrollDirection = .vertical
                        self.presentPickerModally(imagePicker)
                    }
                    else {
                        imagePicker.layoutConfiguration.scrollDirection = .horizontal
                        self.presentPickerAsInputView(imagePicker)
                    }
                }
            })
        }
        else {
            updateNavigationItem(with: 0)
            currentInputView = nil
            reloadInputViews()
        }
    }
    
    func presentPickerAsInputView(_ vc: ImagePickerController) {
        //if you want to present view as input view, you have to set flexible height
        //to adopt natural keyboard height or just set an layout constraint height
        //for specific height.
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
        }
        else {
            let title = "Items (\(selectedCount))"
            navigationController?.visibleViewController?.navigationItem.setRightBarButton(UIBarButtonItem(title: title, style: .plain, target: nil, action: nil), animated: true)
        }
    }

}

extension ViewController : ImagePickerControllerDelegate {
    
    public func imagePicker(controller: ImagePickerController, didSelectActionItemAt index: Int) {
        print("did select action \(index)")
        
        //before we present system image picker, we must update present button
        //because first responder will be dismissed
        presentButton.isSelected = false
        
        if index == 0 && UIImagePickerController.isSourceTypeAvailable(.camera) {
            let vc = UIImagePickerController()
            vc.sourceType = .camera
            vc.allowsEditing = true
            if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
                vc.mediaTypes = mediaTypes
            }
            navigationController?.visibleViewController?.present(vc, animated: true, completion: nil)
        }
        else if index == 1 && UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let vc = UIImagePickerController()
            vc.sourceType = .photoLibrary
            navigationController?.visibleViewController?.present(vc, animated: true, completion: nil)
        }
    }
    
    public func imagePicker(controller: ImagePickerController, didSelect asset: PHAsset) {
        print("selected assets: \(controller.selectedAssets.count)")
        updateNavigationItem(with: controller.selectedAssets.count)
    }
    
    public func imagePicker(controller: ImagePickerController, didDeselect asset: PHAsset) {
        print("selected assets: \(controller.selectedAssets.count)")
        updateNavigationItem(with: controller.selectedAssets.count)
    }
    
    public func imagePicker(controller: ImagePickerController, didTake image: UIImage) {
        print("did take image \(image.size)")
    }
    
    func imagePicker(controller: ImagePickerController, willDisplayActionItem cell: UICollectionViewCell, at index: Int) {
        switch cell {
        case let iconWithTextCell as IconWithTextCell:
            iconWithTextCell.titleLabel.textColor = UIColor.black
            switch index {
            case 0:
                iconWithTextCell.titleLabel.text = "Camera"
                iconWithTextCell.imageView.image = #imageLiteral(resourceName: "button-camera")
            case 1:
                iconWithTextCell.titleLabel.text = "Photos"
                iconWithTextCell.imageView.image = #imageLiteral(resourceName: "button-photo-library")
            default: break
            }
        default:
            break
        }
    }
    
    func imagePicker(controller: ImagePickerController, willDisplayAssetItem cell: ImagePickerAssetCell, asset: PHAsset) {
        switch cell {
        
        case let videoCell as CustomVideoCell:
            videoCell.label.text = ViewController.durationFormatter.string(from: asset.duration)
        
        case let imageCell as CustomImageCell:
            if asset.mediaSubtypes.contains(.photoLive) {
                imageCell.subtypeImageView.image = #imageLiteral(resourceName: "icon-live")
            }
            else if asset.mediaSubtypes.contains(.photoPanorama) {
                imageCell.subtypeImageView.image = #imageLiteral(resourceName: "icon-pano")
            }
            else if #available(iOS 10.2, *), asset.mediaSubtypes.contains(.photoDepthEffect) {
                imageCell.subtypeImageView.image = #imageLiteral(resourceName: "icon-depth")
            }
        default:
            break
        }
    }
    
}

extension ViewController: ImagePickerControllerDataSource {
    
    func imagePicker(controller: ImagePickerController, viewForAuthorizationStatus status: PHAuthorizationStatus) -> UIView {
        let infoLabel = UILabel(frame: .zero)
        infoLabel.backgroundColor = UIColor.green
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        switch status {
        case .restricted:
            infoLabel.text = "Access is restricted\n\nPlease open Settings app and update privacy settings."
        case .denied:
            infoLabel.text = "Access is denied by user\n\nPlease open Settings app and update privacy settings."
        default:
            break
        }
        return infoLabel
    }
    
}
