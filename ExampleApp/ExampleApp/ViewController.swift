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

    private var allowsFirstResponser = false
    private var currentInputView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellId")
        tableView.keyboardDismissMode = .onDrag
    }

    @objc func presentPickerModally() {
        print("presenting modally")
        
        let registrator = CellRegistrator()
        let actionNib = UINib(nibName: "IconWithTextCell", bundle: nil)
        registrator.register(nib: actionNib, forActionItemAt: 0)
        registrator.register(nib: actionNib, forActionItemAt: 1)
        
        let imageNib = UINib(nibName: "ImageCell", bundle: nil)
        registrator.registerNibForAssetItems(imageNib)
        
        let videoNib = UINib(nibName: "VideoCell", bundle: nil)
        registrator.register(nib: videoNib, forAssetItemOf: .video)
//        registrator.registerCellClassForAssetItems(ImageCell.self)
        
        let vc = ImagePickerController()
        vc.layoutConfiguration.scrollDirection = .vertical
        vc.layoutConfiguration.showsCameraActionItem = false
        vc.layoutConfiguration.numberOfAssetItemsInRow = 3
        vc.cellRegistrator = registrator
        
        presentPickerModally(vc)
    }
    
    @objc func presentPickerModallyCustomFetch() {
        print("presenting modally")
        
        let registrator = CellRegistrator()
        
        let imageNib = UINib(nibName: "ImageCell", bundle: nil)
        registrator.registerNibForAssetItems(imageNib)
        
        let vc = ImagePickerController()
        vc.layoutConfiguration.scrollDirection = .vertical
        vc.layoutConfiguration.showsCameraActionItem = false
        vc.layoutConfiguration.showsFirstActionItem = false
        vc.layoutConfiguration.showsSecondActionItem = false
        vc.cellRegistrator = registrator
        vc.assetsFetchResultBlock = {
            guard let momentsCollection = PHAssetCollection.fetchMoments(with: nil).firstObject else {
                //you can return nil if you did not find desired fetch result,
                //default fetch result will be used.
                return nil
            }
            return PHAsset.fetchAssets(in: momentsCollection, options: nil)
        }
        
        presentPickerModally(vc)
    }
    
    @objc func presentPickerAsInputViewPhotosAs1Col() {
        print("presenting as input view")
        
        let registrator = CellRegistrator()
        
        let actionNib = UINib(nibName: "IconWithTextCell", bundle: nil)
        registrator.registerNibForActionItems(actionNib)
        
        let assetNib = UINib(nibName: "ImageCell", bundle: nil)
        registrator.registerNibForAssetItems(assetNib)
        
        let vc = ImagePickerController()
        vc.cellRegistrator = registrator
        vc.layoutConfiguration.numberOfAssetItemsInRow = 1
        
        presentPickerAsInputView(vc)
    }
    
    @objc func presentPickerAsInputView() {
        print("presenting as input view")
        
        let registrator = CellRegistrator()
        let actionNib = UINib(nibName: "IconWithTextCell", bundle: nil)
        let assetNib = UINib(nibName: "ImageCell", bundle: nil)
        //registrator.register(nib: assetNib, forActionItemAt: 0)
        //registrator.register(nib: assetNib, forActionItemAt: 1)
        //registrator.register(cellClass: GreenCell.self, forActionItemAt: 1)
        
        registrator.registerNibForActionItems(actionNib)
        registrator.registerNibForAssetItems(assetNib)
        
        let vc = ImagePickerController()
        vc.cellRegistrator = registrator
        vc.layoutConfiguration.showsSecondActionItem = true
        
        presentPickerAsInputView(vc)
    }
    
    @objc func presentPickerAsInputViewCustomCameraCell() {
        
        let registrator = CellRegistrator()
        let actionNib = UINib(nibName: "IconWithTextCell", bundle: nil)
        let assetNib = UINib(nibName: "ImageCell", bundle: nil)
        let cameraNib = UINib(nibName: "CameraCell", bundle: nil)
        registrator.registerNibForActionItems(actionNib)
        registrator.registerNibForCameraItem(cameraNib)
        registrator.registerNibForAssetItems(assetNib)
        
        let vc = ImagePickerController()
        vc.cellRegistrator = registrator
        vc.captureSettings.cameraMode = .photo
        vc.captureSettings.savesCapturedAssetToPhotoLibrary = true
        
        presentPickerAsInputView(vc)
    }
    
    private func presentPickerAsInputView(_ vc: ImagePickerController) {
        
        vc.delegate = self
        vc.dataSource = self
        
        //if you want to present view as input view, you have to set flexible height
        //to adopt natural keyboard height or just set an layout constraint height
        //for specific height.
        vc.view.autoresizingMask = .flexibleHeight
        currentInputView = vc.view
        
        allowsFirstResponser = true
        becomeFirstResponder()
    }
    
    private func presentPickerModally(_ vc: ImagePickerController) {
        
        vc.delegate = self
        vc.dataSource = self
        
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Dismiss", style: .done, target: self, action: #selector(dismissPresentedImagePicker(sender:)))
        let nc = UINavigationController(rootViewController: vc)
        present(nc, animated: true, completion: nil)
    }
    
    @objc dynamic func dismissPresentedImagePicker(sender: UIBarButtonItem) {
        navigationController?.visibleViewController?.dismiss(animated: true, completion: nil)
    }
    
    override var canBecomeFirstResponder: Bool {
        return allowsFirstResponser
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

let data = [
    [
        ("Modally - no camera", #selector(ViewController.presentPickerModally)),
        ("Modally - only photos", #selector(ViewController.presentPickerModallyCustomFetch))],
    [
        ("Input view - default", #selector(ViewController.presentPickerAsInputView)),
        ("Input view - 1 photo cols", #selector(ViewController.presentPickerAsInputViewPhotosAs1Col)),
        ("Input view - custom camera cell", #selector(ViewController.presentPickerAsInputViewCustomCameraCell))]
]
let selectors = [#selector(ViewController.presentPickerAsInputView)]

extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)
        cell.textLabel?.text = data[indexPath.section][indexPath.row].0
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        perform(data[indexPath.section][indexPath.row].1)
    }
    
}

