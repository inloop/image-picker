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
            self.performUpdates()
            }, completion: { finished in
                self.completeOperation()
        })
    }

    private func performUpdates() {
        // For indexes to make sense, updates must be in this order:
        // delete, insert, reload, move
        if let removed = changes.removedIndexes?.getIndexPaths(for: sectionIndex) {
            collectionView.deleteItems(at: removed)
        }
        if let inserted = changes.insertedIndexes?.getIndexPaths(for: sectionIndex) {
            collectionView.insertItems(at: inserted)
        }
        if let changed = changes.changedIndexes?.getIndexPaths(for: sectionIndex) {
            collectionView.reloadItems(at: changed)
        }
        changes.enumerateMoves { fromIndex, toIndex in
            self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: self.sectionIndex), to: IndexPath(item: toIndex, section: self.sectionIndex))
        }
    }
}

private extension IndexSet {
    func getIndexPaths(for sectionIndex: Int) -> [IndexPath]? {
        let result = map { IndexPath(item: $0, section: sectionIndex) }
        guard !result.isEmpty else { return nil }
        return result
    }
}
