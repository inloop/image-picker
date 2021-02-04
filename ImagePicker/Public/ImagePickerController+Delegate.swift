// Copyright © 2018 INLOOPX. All rights reserved.

import Photos
import UIKit

extension ImagePickerController: ImagePickerDelegateDelegate {
    func imagePicker(delegate pickerDelegate: ImagePickerDelegate, didSelectActionItemAt index: Int) {
        delegate?.imagePicker(controller: self, didSelectActionItemAt: index)
    }

    func imagePicker(delegate pickerDelegate: ImagePickerDelegate, didSelectAssetItemAt index: Int) {
        delegate?.imagePicker(controller: self, didSelect: asset(at: index))
    }

    func imagePicker(delegate pickerDelegate: ImagePickerDelegate, didDeselectAssetItemAt index: Int) {
        delegate?.imagePicker(controller: self, didDeselect: asset(at: index))
    }

    func imagePicker(delegate pickerDelegate: ImagePickerDelegate, willDisplayActionCell cell: UICollectionViewCell, at index: Int) {
        if let defaultCell = cell as? ActionCell {
            defaultCell.update(withIndex: index, layoutConfiguration: layoutConfiguration)
        }
        delegate?.imagePicker(controller: self, willDisplayActionItem: cell, at: index)
    }

    func imagePicker(delegate pickerDelegate: ImagePickerDelegate, willDisplayAssetCell cell: ImagePickerAssetCell, at index: Int) {
        let theAsset = asset(at: index)

        // If the cell is default cell provided by Image Picker, it's our responsibility
        // To update the cell with the asset.
        if let defaultCell = cell as? VideoAssetCell {
            defaultCell.update(with: theAsset)
        }
        delegate?.imagePicker(controller: self, willDisplayAssetItem: cell, asset: theAsset)
    }

    func imagePicker(delegate: ImagePickerDelegate, willDisplayCameraCell cell: CameraCollectionViewCell) {
        setupCellIfNeeded(cell)
        updateLivePhotos(for: cell)
        updateVideoRecordingStatus(for: cell)
        updateAuthStatusIfNeeded(for: cell)

        if !isRecordingVideo {
            captureSession?.resume()
        }
    }

    func imagePicker(delegate: ImagePickerDelegate, didEndDisplayingCameraCell cell: CameraCollectionViewCell) {
        // Suspend session only if not recording video, otherwise the recording would be stopped.
        guard !isRecordingVideo else { return }
        captureSession?.suspend()
        blurCell(cell)
    }

    func imagePicker(delegate: ImagePickerDelegate, didScroll scrollView: UIScrollView) {
        // Update only if the view is visible.
        //TODO: precaching is not enabled for now (it's laggy need to profile)
        collectionViewDataSource.assetsCacheItem.updateCachedAssets(collectionView: collectionView)
    }
}

// MARK: ImagePickerDelegate helpers
private extension ImagePickerController {
    var isRecordingVideo: Bool {
        return captureSession?.isRecordingVideo ?? false
    }

    func setupCellIfNeeded(_ cell: CameraCollectionViewCell) {
        guard  cell.delegate == nil else { return }
        cell.delegate = self
        cell.previewView.session = captureSession?.session
        captureSession?.previewLayer = cell.previewView.previewLayer

        // When using videos preset, we are using different technique for
        // blurring the cell content. If isVisualEffectViewUsedForBlurring is
        // true, then UIVisualEffectView is used for blurring. In other cases
        // we manually blur video data output frame (it's faster). Reason why
        // we have 2 different blurring techniques is that the faster solution
        // can not be used when we have .video preset configuration.
        if let config = captureSession?.presetConfiguration, config == .videos {
            cell.isVisualEffectViewUsedForBlurring = true
        }
    }

    func updateLivePhotos(for cell: CameraCollectionViewCell) {
        // If cell is default LivePhotoCameraCell, we must update it based on camera config
        if let liveCameraCell = cell as? LivePhotoCameraCell {
            liveCameraCell.updateWithCameraMode(captureSettings.cameraMode)
        }

        let inProgressLivePhotos = captureSession?.inProgressLivePhotoCapturesCount ?? 0
        cell.updateLivePhotoStatus(isProcessing: inProgressLivePhotos > 0, shouldAnimate: false)
    }

    func updateVideoRecordingStatus(for cell: CameraCollectionViewCell) {
        cell.updateRecordingVideoStatus(isRecording: isRecordingVideo, shouldAnimate: false)
    }

    func updateAuthStatusIfNeeded(for cell: CameraCollectionViewCell) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard cell.authorizationStatus != status else { return }
        cell.authorizationStatus = status
    }

    func blurCell(_ cell: CameraCollectionViewCell) {
        DispatchQueue.global(qos: .userInteractive).async {
            let blurred = self.captureSession?.blurredBufferImage
            DispatchQueue.main.async {
                cell.blurIfNeeded(blurImage: blurred, animated: false, completion: nil)
            }
        }
    }
}
