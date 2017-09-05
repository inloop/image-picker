//
//  ImagePickerDataSource.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

///
/// A model that contains info that is used by layout code and collection view data source
/// when figuring out layout structure.
///
/// Always contains 3 sections:
/// 1. for actions (supports up to 2 action items)
/// 2. for camera (1 camera item)
/// 3. for image assets (any number of image asset items)
/// Each section can be empty.
///
struct LayoutModel {
    
    private var sections: [Int] = [0, 0, 0]
    
    init(configuration: LayoutConfiguration, assets: Int) {
        var actionItems: Int = configuration.showsFirstActionItem ? 1 : 0
        actionItems += configuration.showsSecondActionItem ? 1 : 0
        sections[0] = actionItems
        sections[1] = configuration.showsCameraActionItem ? 1 : 0
        sections[2] = assets
    }
    
    var numberOfSections: Int {
        return sections.count
    }
    
    func numberOfItems(in section: Int) -> Int {
        return sections[section]
    }
    
    static var empty: LayoutModel {
        return LayoutModel(configuration: LayoutConfiguration.defaultConfiguration, assets: 0)
    }
}

///
/// Datasource for a collection view that is used by Image Picker VC.
///
final class ImagePickerDataSource : NSObject, UICollectionViewDataSource {
    
    var layoutModel = LayoutModel.empty
    
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath)
        
        cell.backgroundColor = UIColor.blue
        
        //temp solution for selected state
        let selected = UIView()
        selected.backgroundColor = UIColor.green
        cell.selectedBackgroundView = selected
        return cell
    }
}
