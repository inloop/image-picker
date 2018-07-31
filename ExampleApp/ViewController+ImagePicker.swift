// Copyright © 2018 INLOOPX. All rights reserved.

import ImagePicker
import Photos

extension ViewController: ImagePickerControllerDelegate {
    public func imagePicker(controller: ImagePickerController, didSelectActionItemAt index: Int) {
        print("did select action \(index)")
        
        // Before we present system image picker, we must update present button
        // because first responder will be dismissed
        presentButton.isSelected = false
        
        if index == 0 && UIImagePickerController.isSourceTypeAvailable(.camera) {
            let vc = UIImagePickerController()
            vc.sourceType = .camera
            vc.allowsEditing = true
            if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
                vc.mediaTypes = mediaTypes
            }
            navigationController?.visibleViewController?.present(vc, animated: true, completion: nil)
        } else if index == 1 && UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
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
    
    public func imagePicker(controller: ImagePickerController, didTake livePhoto: UIImage, videoUrl: URL) {
        print("did take livePhoto \(livePhoto.size) \(videoUrl.absoluteString)")
    }
    
    public func imagePicker(controller: ImagePickerController, didCaptureVideo url: URL) {
        print("did take video \(url.absoluteString)")
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
            if asset.mediaSubtypes.contains(.photoLive) { imageCell.subtypeImageView.image = #imageLiteral(resourceName: "icon-live") }
            else if asset.mediaSubtypes.contains(.photoPanorama) { imageCell.subtypeImageView.image = #imageLiteral(resourceName: "icon-pano") }
            else if #available(iOS 10.2, *), asset.mediaSubtypes.contains(.photoDepthEffect) { imageCell.subtypeImageView.image = #imageLiteral(resourceName: "icon-depth") }
        default:
            break
        }
    }
    
    @available(iOS 11.0, *)
    func imagePicker(controller: ImagePickerController, dragSessionWillBegin session: UIDragSession) {
        presentButtonTapped()
        dropAssetsView.autoresizingMask = .flexibleHeight
        if let window = UIApplication.shared.delegate?.window, let safeWindow = window {
            dropAssetsView.frame = safeWindow.frame
            safeWindow.addSubview(dropAssetsView)
            dropAssetsView.alpha = 0
            UIView.animate(withDuration: 0.4) {
                self.dropAssetsView.alpha = 1
            }
            
        }
    }
    
    @available(iOS 11.0, *)
    func imagePicker(controller: ImagePickerController, dragSessionDidEnd session: UIDragSession) {
        presentButtonTapped()
        UIView.animate(withDuration: 0.2, animations: {
            self.dropAssetsView.alpha = 0
        }) { completed in
            self.dropAssetsView.removeFromSuperview()
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
