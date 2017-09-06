//
//  ImagePickerViewController.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit

//this is temp Type for photo assets
public typealias Asset = Int

//this is temp asset type
public enum AssetType: CustomStringConvertible {
    
    case video, image
    
    public var description: String {
        switch self {
        case .video: return "video"
        case .image: return "image"
        }
    }
}

public protocol ImagePickerViewControllerDelegate : class {
    
    ///
    /// Called when user taps on an action item, index is either 0 or 1 depending which was tapped
    ///
    func imagePicker(controller: ImagePickerViewController, didSelectActionItemAt index: Int)
    
    func imagePicker(controller: ImagePickerViewController, didSelect asset: Asset)
    
    func imagePicker(controller: ImagePickerViewController, didTake image: UIImage)
    
}

//this will make sure all delegate methods are optional
extension ImagePickerViewControllerDelegate {
    func imagePicker(controller: ImagePickerViewController, didSelectActionItemAt index: Int) {}
    func imagePicker(controller: ImagePickerViewController, didSelect asset: Asset) {}
    func imagePicker(controller: ImagePickerViewController, didTake image: UIImage) {}
}

///
/// Just holds all data needed when registering collection view cells
///
//private final class CellsRegistrator {
//    
//    var dictionaryOfNibs: []
//    
//}

open class ImagePickerViewController : UIViewController {
   
    deinit {
        print("deinit: \(self.classForCoder)")
    }
    
    // MARK: Public API
    
    public var layoutConfiguration = LayoutConfiguration.default
    
    public func register(nib: UINib, forActionItemAt index: Int) {
        if actionItemNibsData == nil {
            actionItemNibsData = [:]
        }
        let cellIdentifier = actionItemIdentifierPrefix + String(index)
        actionItemNibsData?[index] = (nib, cellIdentifier)
    }
    
    public func register(nib: UINib, forAssetItemOf type: AssetType) {
        if assetItemNibsData == nil {
            assetItemNibsData = [:]
        }
        let cellIdentifier = assetItemIdentifierPrefix + String(describing: type)
        assetItemNibsData?[type] = (nib, cellIdentifier)
    }
    
    public func register(class: UICollectionViewCell.Type, forActionItemAt index: Int) {
        if actionItemClassesData == nil {
            actionItemClassesData = [:]
        }
        let cellIdentifier = actionItemIdentifierPrefix + String(index)
        actionItemClassesData?[index] = (`class`, cellIdentifier)
    }
    
    public func register(class: UICollectionViewCell.Type, forAssetItemOf type: AssetType) {
        if assetItemClassesData == nil {
            assetItemClassesData = [:]
        }
        let cellIdentifier = assetItemIdentifierPrefix + String(describing: type)
        assetItemClassesData?[type] = (`class`, cellIdentifier)
    }
    
    // MARK: Private Methods
    
    private var actionItemIdentifierPrefix = "eu.inloop.action-item.cell-id"
    private var actionItemNibsData: [Int: (UINib, String)]?
    private var actionItemClassesData: [Int: (UICollectionViewCell.Type, String)]?
    
    private var assetItemIdentifierPrefix = "eu.inloop.asset-item.cell-id"
    private var assetItemNibsData: [AssetType: (UINib, String)]?
    private var assetItemClassesData: [AssetType: (UICollectionViewCell.Type, String)]?
    
    private var collectionViewDataSource = ImagePickerDataSource()
    private var collectionViewDelegate = ImagePickerDelegate()
    
    private lazy var collectionView: UICollectionView = {
        
        let configuration = self.layoutConfiguration
        let model = LayoutModel(configuration: configuration, assets: 50)
        let layout = ImagePickerLayout(configuration: configuration)
        
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = configuration.scrollDirection
        collectionViewLayout.minimumInteritemSpacing = configuration.interitemSpacing
        collectionViewLayout.minimumLineSpacing = configuration.interitemSpacing
        
        self.collectionViewDataSource.layoutModel = model
        self.collectionViewDelegate.layout = layout
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        view.backgroundColor = UIColor.red
        view.contentInset = UIEdgeInsets.zero
        view.dataSource = self.collectionViewDataSource
        view.delegate = self.collectionViewDelegate
        view.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cellId")
        view.allowsMultipleSelection = true
        
        //register all nibs
        view.register(nibsData: self.actionItemNibsData?.map { $1 })
        view.register(nibsData: self.assetItemNibsData?.map { $1 })
        
        return view
    }()
    
    // MARK: View Lifecycle
    
    open override func loadView() {
        self.view = collectionView
    }
    
    //this will make sure that collection view layout is reloaded when interface rotates/changes
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }) { (context) in }
        super.viewWillTransition(to: size, with: coordinator)
    }
    
}

extension UICollectionView {
    
    /// Helper func that takes nib,cellid pair and registers them on a collection view
    fileprivate func register(nibsData: [(UINib, String)]?) {
        guard let nibsData = nibsData else { return }
        for (nib, cellIdentifier) in nibsData {
            register(nib, forCellWithReuseIdentifier: cellIdentifier)
        }
    }
    
    /// Helper func that takes nib,cellid pair and registers them on a collection view
    fileprivate func register(classData: [(UICollectionViewCell.Type, String)]?) {
        guard let classData = classData else { return }
        for (cellType, cellIdentifier) in classData {
            register(cellType, forCellWithReuseIdentifier: cellIdentifier)
        }
    }
    
}
