//
//  ImagePickerControllerDelegate.swift
//  ImagePicker
//
//  Created by Anna Shirokova on 13/06/2018.
//  Copyright © 2018 Inloop. All rights reserved.
//

import Foundation
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
    /// Called when user select an asset.
    ///
    func imagePicker(controller: ImagePickerController, didSelect asset: PHAsset)

    ///
    /// Called when user unselect previously selected asset.
    ///
    func imagePicker(controller: ImagePickerController, didDeselect asset: PHAsset)

    ///
    /// Called when user takes new photo.
    ///
    func imagePicker(controller: ImagePickerController, didTake image: UIImage)

    ///
    /// Called when user takes new photo.
    ///
    //TODO:
    //func imagePicker(controller: ImagePickerController, didCaptureVideo url: UIImage)
    //func imagePicker(controller: ImagePickerController, didTake livePhoto: UIImage, videoUrl: UIImage)

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
    public func imagePicker(controller: ImagePickerController, didSelect asset: PHAsset) {}
    public func imagePicker(controller: ImagePickerController, didUnselect asset: PHAsset) {}
    public func imagePicker(controller: ImagePickerController, didTake image: UIImage) {}
    public func imagePicker(controller: ImagePickerController, willDisplayActionItem cell: UICollectionViewCell, at index: Int) {}
    public func imagePicker(controller: ImagePickerController, willDisplayAssetItem cell: ImagePickerAssetCell, asset: PHAsset) {}
}
