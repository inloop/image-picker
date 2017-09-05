//
//  ImagePickerViewController.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation
import UIKit

/*
 
 TODO: step 1
 - show collection of items in horizontal flow
 - implement selected state in vc and in cells
 - create interface for registering custom cells of desired type
 */

open class ImagePickerViewController : UIViewController {
   
    deinit {
        print("deinit: \(self.classForCoder)")
    }
    
    private var collectionViewDataSource = ImagePickerDataSource()
    private var collectionViewDelegate = ImagePickerDelegate()
    
    private lazy var collectionView: UICollectionView = {
        
        let configuration = LayoutConfiguration()
        let model = LayoutModel(configuration: configuration, assets: 50)
        let layout = ImagePickerLayout(configuration: configuration)
        
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.scrollDirection = .horizontal
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
        
        return view
    }()
    
    open override func loadView() {
        self.view = collectionView
    }
    
}
