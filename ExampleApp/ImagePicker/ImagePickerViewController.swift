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

//this is temp Type for photo assets
public typealias Asset = Int

//this is temp asset type
public enum AssetType: CustomStringConvertible {
    
    case image
    //case video
    
    public var description: String {
        switch self {
        case .image: return "image"
        //case .video: return "video"
        }
    }
}

public protocol ImagePickerViewControllerDelegate : class {
    
    ///
    /// Called when user taps on an action item, index is either 0 or 1 depending which was tapped
    ///
    func imagePicker(controller: ImagePickerViewController, didSelectActionItemAt index: Int)
    
    func imagePicker(controller: ImagePickerViewController, didFinishPicking asset: PHAsset)
    
    //perhaps we can use method above and remove this one, client does not care if user took a picture or
    //picked it from a library
    func imagePicker(controller: ImagePickerViewController, didTake image: UIImage)
    
    ///
    /// Called right before an action item collection view cell is displayed. Use this method
    /// to configure your cell.
    ///
    func imagePicker(controller: ImagePickerViewController, willDisplayActionItem cell: UICollectionViewCell, at index: Int)
    
}

//this will make sure all delegate methods are optional
extension ImagePickerViewControllerDelegate {
    public func imagePicker(controller: ImagePickerViewController, didSelectActionItemAt index: Int) {}
    public func imagePicker(controller: ImagePickerViewController, didSelect asset: Asset) {}
    public func imagePicker(controller: ImagePickerViewController, didTake image: UIImage) {}
    public func imagePicker(controller: ImagePickerViewController, willDisplayActionItem cell: UICollectionViewCell, at index: Int) {}
}

open class ImagePickerViewController : UIViewController {
   
    deinit {
        print("deinit: \(self.classForCoder)")
    }
    
    // MARK: Public API
    
    /// configure layout of all items
    public var layoutConfiguration = LayoutConfiguration.default
    
    /// use this to register a cell classes or nibs for each item types
    public var cellRegistrator = CellRegistrator()
    
    /// get informed about user interaction and changes
    public weak var delegate: ImagePickerViewControllerDelegate?
    
    /// holds all currently selected images
    public var selectedAssets: [PHAsset] {
        get {
            let selectedIndexPaths = collectionView.indexPathsForSelectedItems ?? []
            let selectedAssets = selectedIndexPaths.flatMap { indexPath in
                return collectionViewDataSource.assetsModel?.fetchResult?.object(at: indexPath.row)
            }
            return selectedAssets
        }
    }
    
    // MARK: Private Methods
    
    fileprivate var collectionViewDataSource = ImagePickerDataSource()
    fileprivate var collectionViewDelegate = ImagePickerDelegate()
    
    fileprivate lazy var collectionView: UICollectionView = {
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        view.backgroundColor = UIColor.red
        view.contentInset = UIEdgeInsets.zero
        view.dataSource = self.collectionViewDataSource
        view.delegate = self.collectionViewDelegate
        view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cellId")
        view.allowsMultipleSelection = true
        
        //register all nibs
        view.apply(registrator: self.cellRegistrator)
        
        return view
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
        self.collectionViewDataSource.assetsModel?.thumbnailSize = thumbnailSize
    }
    
    // MARK: View Lifecycle
    
    open override func loadView() {
        self.view = collectionView
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let configuration = self.layoutConfiguration
        let assetsModel = ImagePickerAssetModel()
        
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        assetsModel.fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
        print("fetched: \(assetsModel.fetchResult!.count) photos")
        
        let model = LayoutModel(configuration: configuration, assets: assetsModel.fetchResult!.count)
        
        let collectionViewLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        collectionViewLayout.scrollDirection = configuration.scrollDirection
        collectionViewLayout.minimumInteritemSpacing = configuration.interitemSpacing
        collectionViewLayout.minimumLineSpacing = configuration.interitemSpacing
        
        self.collectionViewDataSource.layoutModel = model
        self.collectionViewDataSource.cellRegistrator = self.cellRegistrator
        self.collectionViewDelegate.layout = ImagePickerLayout(configuration: configuration)
        self.collectionViewDelegate.delegate = self
        
        self.collectionViewDataSource.assetsModel = assetsModel
        self.collectionViewDataSource.layoutModel = model
        
        //TODO: implement this
        PHPhotoLibrary.requestAuthorization { (status) in
            DispatchQueue.main.async {
            }
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateItemSize()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
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

extension ImagePickerViewController : ImagePickerDelegateDelegate {
    
    func imagePicker(delegate: ImagePickerDelegate, didSelectActionItemAt index: Int) {
        self.delegate?.imagePicker(controller: self, didSelectActionItemAt: index)
    }
        
    func imagePicker(delegate: ImagePickerDelegate, didSelectAssetItemAt index: Int) {
        guard let asset = collectionViewDataSource.assetsModel?.fetchResult?.object(at: index) else {
            return
        }
        self.delegate?.imagePicker(controller: self, didFinishPicking: asset)
    }
    
    func imagePicker(delegate: ImagePickerDelegate, willDisplayActionCell cell: UICollectionViewCell, at index: Int) {
        self.delegate?.imagePicker(controller: self, willDisplayActionItem: cell, at: index)
    }
    
}
