//
//  ImagePickerDataSource.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

///
/// Datasource for a collection view that is used by Image Picker VC.
///
final class ImagePickerDataSource : NSObject, UICollectionViewDataSource {
    
    var layoutModel = LayoutModel.empty
    var cellRegistrator: CellRegistrator?
    
    override init() {
        super.init()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return layoutModel.numberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return layoutModel.numberOfItems(in: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cellsRegistrator = cellRegistrator else {
            fatalError("cells registrator must be set at this moment")
        }
        
        switch indexPath.section {
        case 0:
            guard let id = cellsRegistrator.cellIdentifier(forActionItemAt: indexPath.row) else {
                fatalError("there is an action item at index \(indexPath.row) but no cell is registered")
            }
            return collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
        
        case 1:
            let id = cellsRegistrator.cellIdentifierForCameraItem
            let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
            cell.backgroundColor = UIColor.blue
            return cell
            
        case 2:
            //TODO: we are assuming images only for now
            let type = AssetType.image
            guard let id = cellsRegistrator.cellIdentifier(forAsset: type) else {
                fatalError("there is an asset item at index \(indexPath.row) but no cell is registered")
            }
            return collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath)
        
        default: fatalError("only 3 sections are supporte")
        }
        
    }
}
