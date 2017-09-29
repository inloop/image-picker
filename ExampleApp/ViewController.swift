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

///
/// This is an example view controller that shows how Image Picker can be used
///
class ViewController: UITableViewController {
    
    enum CameraItemConfig: Int {
        case `default`
        case custom
        case none
    }
    
    enum AssetsSource: Int {
        case recentlyAdded
        case onlyVideos
        case onlySelfies
    }
    
    var presentsModally: Bool = false
    var numberOfActionItems: Int = 2
    var cameraConfig: CameraItemConfig = .default
    var assetsSource: AssetsSource = .recentlyAdded
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //configure global appearance. If you wish to specify appearance per
        //instance simple set appearance() on the instance itself. It will
        //have a precedense over global appearance
        ImagePickerController.appearance().backgroundColor = UIColor.black
        
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
    
//    @objc func presentPickerModallyy() {
//        print("presenting modally")
//
//        let vc = ImagePickerController()
//
//        let actionNib = UINib(nibName: "IconWithTextCell", bundle: nil)
//        vc.cellRegistrator.register(nib: actionNib, forActionItemAt: 0)
//        vc.cellRegistrator.register(nib: actionNib, forActionItemAt: 1)
//
//        let imageNib = UINib(nibName: "ImageCell", bundle: nil)
//        vc.cellRegistrator.registerNibForAssetItems(imageNib)
//
//        let videoNib = UINib(nibName: "VideoCell", bundle: nil)
//        vc.cellRegistrator.register(nib: videoNib, forAssetItemOf: .video)
//
//        vc.layoutConfiguration.scrollDirection = .vertical
//        vc.layoutConfiguration.showsCameraItem = false
//        vc.layoutConfiguration.numberOfAssetItemsInRow = 3
//
//        presentPickerModally(vc)
//    }
    
//    @objc func presentPickerModallyCustomFetch() {
//        print("presenting modally")
//
//        let vc = ImagePickerController()
//        vc.layoutConfiguration.scrollDirection = .vertical
//        vc.layoutConfiguration.showsCameraItem = false
//        vc.layoutConfiguration.showsFirstActionItem = false
//        vc.layoutConfiguration.showsSecondActionItem = false
//        vc.cellRegistrator.registerNibForAssetItems(UINib(nibName: "ImageCell", bundle: nil))
//        vc.assetsFetchResultBlock = {
//            guard let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: nil).firstObject else {
//                //you can return nil if you did not find desired fetch result, default fetch result will be used.
//                return nil
//            }
//            return PHAsset.fetchAssets(in: collection, options: nil)
//        }
//
//        presentPickerModally(vc)
//    }
    
//    @objc func presentPickerAsInputViewPhotosAs1Col() {
//        print("presenting as input view")
//
//        let vc = ImagePickerController()
//        vc.cellRegistrator.registerNibForActionItems(UINib(nibName: "IconWithTextCell", bundle: nil))
//        vc.cellRegistrator.registerNibForAssetItems(UINib(nibName: "ImageCell", bundle: nil))
//        vc.layoutConfiguration.numberOfAssetItemsInRow = 1
//
//        presentPickerAsInputView(vc)
//    }
    
//    @objc func presentPickerAsInputVieww() {
//        print("presenting as input view")
//        let vc = ImagePickerController()
//        presentPickerAsInputView(vc)
//    }
    
//    @objc func presentPickerAsInputViewPhotosConfiguration() {
//
//        let vc = ImagePickerController()
//        vc.cellRegistrator.registerNibForActionItems(UINib(nibName: "IconWithTextCell", bundle: nil))
//        vc.cellRegistrator.registerNibForCameraItem(UINib(nibName: "CameraCell", bundle: nil))
//        vc.cellRegistrator.registerNibForAssetItems(UINib(nibName: "ImageCell", bundle: nil))
//        vc.captureSettings.cameraMode = .photo
//
//        presentPickerAsInputView(vc)
//    }
    
//    @objc func presentPickerAsInputViewLivePhotosConfiguration() {
//
//        let vc = ImagePickerController()
//        vc.cellRegistrator.registerNibForActionItems(UINib(nibName: "IconWithTextCell", bundle: nil))
//        vc.cellRegistrator.registerNibForCameraItem(UINib(nibName: "LivePhotoCameraCell", bundle: nil))
//        vc.cellRegistrator.register(nib: UINib(nibName: "VideoCell", bundle: nil), forAssetItemOf: .video)
//        vc.cellRegistrator.registerNibForAssetItems(UINib(nibName: "ImageCell", bundle: nil))
//        vc.captureSettings.cameraMode = .photoAndLivePhoto
//        vc.captureSettings.savesCapturedAssetToPhotoLibrary = true
//
//        presentPickerAsInputView(vc)
//    }
    
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
                imagePicker.cellRegistrator.register(nib: UINib(nibName: "IconWithTextCell", bundle: nil), forActionItemAt: 0)
            case 2:
                imagePicker.layoutConfiguration.showsFirstActionItem = true
                imagePicker.layoutConfiguration.showsSecondActionItem = true
                imagePicker.cellRegistrator.registerNibForActionItems(UINib(nibName: "IconWithTextCell", bundle: nil))
            default:
                break
            }
            
            // set camera item
            switch cameraConfig {
            case .none:
                imagePicker.layoutConfiguration.showsCameraItem = false
            case .custom:
                imagePicker.cellRegistrator.registerNibForCameraItem(UINib(nibName: "LivePhotoCameraCell", bundle: nil))
            case .default:
                break
            }
            
            // config assets item
            switch assetsSource {
            case .recentlyAdded:
                break
            case .onlyVideos:
                imagePicker.cellRegistrator.register(nib: UINib(nibName: "VideoCell", bundle: nil), forAssetItemOf: .video)
                imagePicker.assetsFetchResultBlock = {
                    guard let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: nil).firstObject else {
                        return nil //you can return nil if you did not find desired fetch result, default fetch result will be used.
                    }
                    return PHAsset.fetchAssets(in: collection, options: nil)
                }
            case .onlySelfies:
                imagePicker.cellRegistrator.registerNibForAssetItems(UINib(nibName: "ImageCell", bundle: nil))
                imagePicker.assetsFetchResultBlock = {
                    guard let collection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: nil).firstObject else {
                        return nil
                    }
                    return PHAsset.fetchAssets(in: collection, options: nil)
                }
            }
            
            // presentation
            if presentsModally {
                imagePicker.layoutConfiguration.scrollDirection = .vertical
                presentPickerModally(imagePicker)
            }
            else {
                imagePicker.layoutConfiguration.scrollDirection = .horizontal
                presentPickerAsInputView(imagePicker)
            }
        }
        else {
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
        presentButton.isSelected = false
        navigationController?.visibleViewController?.dismiss(animated: true, completion: nil)
    }
    
}

extension ViewController {
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result == true {
            currentInputView = nil
        }
        return result
    }
    
    override var inputView: UIView? {
        return currentInputView
    }
    
    override var inputAccessoryView: UIView? {
        return presentButton
    }
    
}

extension ViewController {
    
    func uncheckCellsInSection(except indexPath: IndexPath){
        for path in tableView.indexPathsForVisibleRows ?? [] where path.section == indexPath.section {
            let cell = tableView.cellForRow(at: path)!
            cell.accessoryType = path == indexPath ? .checkmark : .none
        }
    }
    
}

extension ViewController : ImagePickerControllerDelegate {
    
    public func imagePicker(controller: ImagePickerController, didSelectActionItemAt index: Int) {
        print("did select action \(index)")
    }
    
    public func imagePicker(controller: ImagePickerController, didFinishPicking asset: PHAsset) {
        print("selected assets: \(controller.selectedAssets.count)")
    }
    
    public func imagePicker(controller: ImagePickerController, didTake image: UIImage) {
        print("did take image \(image.size)")
    }
    
    func imagePicker(controller: ImagePickerController, willDisplayActionItem cell: UICollectionViewCell, at index: Int) {
        switch cell {
        case let iconWithTextCell as IconWithTextCell:
            switch index {
            case 0:
                iconWithTextCell.titleLabel.text = "Camera"
                iconWithTextCell.imageView.image = #imageLiteral(resourceName: "ic-camera")
            case 1:
                iconWithTextCell.titleLabel.text = "Photo Library"
                iconWithTextCell.imageView.image = #imageLiteral(resourceName: "ic-photo")
            default: break
            }
        default:
            break
        }
    }
    
    func imagePicker(controller: ImagePickerController, willDisplayAssetItem cell: ImagePickerAssetCell, asset: PHAsset) {
        switch cell {
        
        case let videoCell as VideoCell:
            videoCell.label.text = ViewController.durationFormatter.string(from: asset.duration)
        
        case let imageCell as ImageCell:
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
    
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
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

enum SelectorArgument {
    case indexPath
    case none
}

struct CellData {
    var title: String
    var selector: Selector
    var selectorArgument: SelectorArgument
    var configBlock: CellConfigurationBlock
    
    init(_ title: String, _ selector: Selector, _ selectorArgument: SelectorArgument, _ configBlock: CellConfigurationBlock) {
        self.title = title
        self.selector = selector
        self.selectorArgument = selectorArgument
        self.configBlock = configBlock
    }
}

typealias CellConfigurationBlock = ((UITableViewCell, ViewController) -> Void)?

let cellsData: [[CellData]] = [
    [
        CellData("As input view", #selector(ViewController.togglePresentationMode(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.presentsModally ? .none : .checkmark }),
        CellData("Modally", #selector(ViewController.togglePresentationMode(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.presentsModally ? .checkmark : .none })
    ],
    [
        CellData("Two items", #selector(ViewController.setNumberOfActionItems(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.numberOfActionItems == 2 ? .checkmark : .none }),
        CellData("One item", #selector(ViewController.setNumberOfActionItems(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.numberOfActionItems == 1 ? .checkmark : .none }),
        CellData("Disabled (default)", #selector(ViewController.setNumberOfActionItems(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.numberOfActionItems == 0 ? .checkmark : .none }),
    ],
    [
        CellData("Default", #selector(ViewController.configCameraItem(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.cameraConfig == .default ? .checkmark : .none }),
        CellData("Custom", #selector(ViewController.configCameraItem(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.cameraConfig == .custom ? .checkmark : .none }),
        CellData("Disabled", #selector(ViewController.configCameraItem(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.cameraConfig == .none ? .checkmark : .none })
    ],
    [
        CellData("Recently added (default)", #selector(ViewController.configAssetsSource(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.assetsSource == .recentlyAdded ? .checkmark : .none }),
        CellData("Only videos", #selector(ViewController.configAssetsSource(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.assetsSource == .onlyVideos ? .checkmark : .none }),
        CellData("Only selfies", #selector(ViewController.configAssetsSource(indexPath:)), .indexPath, { cell, controller in cell.accessoryType = controller.assetsSource == .onlySelfies ? .checkmark : .none })
    ]
]

let sectionTitles: [String?] = [
    "Presentation",
    "Action Items",
    "Camera Item",
    "Assets Source"
]

extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return cellsData.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellsData[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)
        cell.textLabel?.text = cellsData[indexPath.section][indexPath.row].title
        if let configBlock = cellsData[indexPath.section][indexPath.row].configBlock {
            configBlock(cell, self)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // deselect
        tableView.deselectRow(at: indexPath, animated: true)
        
        // perform selector
        let selector = cellsData[indexPath.section][indexPath.row].selector
        let argumentType = cellsData[indexPath.section][indexPath.row].selectorArgument
        switch argumentType {
        case .indexPath: perform(selector, with: indexPath)
        default: perform(selector)
        }
        
        // update checks in section
        uncheckCellsInSection(except: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
}

