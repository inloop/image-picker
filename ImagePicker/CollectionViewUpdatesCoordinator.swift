//
//  CollectionViewUpdatesCoordinator.swift
//  ImagePicker
//
//  Created by Peter Stajger on 13/04/2018.
//  Copyright © 2018 Inloop. All rights reserved.
//

import UIKit
import Photos

///
/// Makes sure that all updates are performed in a serial queue, especially batch animations. This
/// will make sure that reloadData() will never be called durring batch updates animations, which
/// will prevent collection view from crashing on internal incosistency.
///
final class CollectionViewUpdatesCoordinator {
    
    deinit {
        log("deinit: \(String(describing: self))")
    }
    
    private let collectionView: UICollectionView
    
    private var serialMainQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.underlyingQueue = DispatchQueue.main
        return queue
    }()
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
    
    /// Provides opportunuty to update collectionView's dataSource in underlaying queue.
    func performDataSourceUpdate(updates: @escaping ()->Void) {
        serialMainQueue.addOperation(updates)
    }
    
    /// Updates collection view.
    func performChanges<PHAsset>(_ changes: PHFetchResultChangeDetails<PHAsset>, inSection: Int) {
        
        if changes.hasIncrementalChanges {
            let operation = CollectionViewBatchAnimation(collectionView: collectionView, sectionIndex: inSection, changes: changes)
            serialMainQueue.addOperation(operation)
        }
        else {
            serialMainQueue.addOperation { [unowned self] in
                self.collectionView.reloadData()
            }
        }
    }
    
}
