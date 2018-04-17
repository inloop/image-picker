//
//  CollectionViewBatchAnimation.swift
//  ImagePicker
//
//  Created by Peter Stajger on 13/04/2018.
//  Copyright © 2018 Inloop. All rights reserved.
//

import UIKit
import Photos

///
/// Wraps collectionView's `performBatchUpdates` block into AsynchronousOperation.
///
final class CollectionViewBatchAnimation<ObjectType> : AsynchronousOperation where ObjectType : PHObject {
    private let collectionView: UICollectionView
    private let sectionIndex: Int
    private let changes: PHFetchResultChangeDetails<ObjectType>
    
    init(collectionView: UICollectionView, sectionIndex: Int, changes: PHFetchResultChangeDetails<ObjectType>) {
        self.collectionView = collectionView
        self.sectionIndex = sectionIndex
        self.changes = changes
    }
    
    override func execute() {
        // If we have incremental diffs, animate them in the collection view
        collectionView.performBatchUpdates({ [unowned self] in
            
            // For indexes to make sense, updates must be in this order:
            // delete, insert, reload, move
            if let removed = self.changes.removedIndexes, removed.isEmpty == false {
                self.collectionView.deleteItems(at: removed.map({ IndexPath(item: $0, section: self.sectionIndex) }))
            }
            if let inserted = changes.insertedIndexes, inserted.isEmpty == false {
                self.collectionView.insertItems(at: inserted.map({ IndexPath(item: $0, section: self.sectionIndex) }))
            }
            if let changed = changes.changedIndexes, changed.isEmpty == false {
                self.collectionView.reloadItems(at: changed.map({ IndexPath(item: $0, section: self.sectionIndex) }))
            }
            changes.enumerateMoves { fromIndex, toIndex in
                self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: self.sectionIndex), to: IndexPath(item: toIndex, section: self.sectionIndex))
            }
            }, completion: { finished in
                self.completeOperation()
        })
    }
}
