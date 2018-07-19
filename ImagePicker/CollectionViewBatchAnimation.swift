// Copyright © 2018 INLOOPX. All rights reserved.

import Foundation
import Photos

/// Wraps collectionView's `performBatchUpdates` block into AsynchronousOperation.

final class CollectionViewBatchAnimation<ObjectType>: AsynchronousOperation where ObjectType: PHObject {
    private let collectionView: UICollectionView
    private let sectionIndex: Int
    private let changes: PHFetchResultChangeDetails<ObjectType>
    
    init(collectionView: UICollectionView, sectionIndex: Int, changes: PHFetchResultChangeDetails<ObjectType>) {
        self.collectionView = collectionView
        self.sectionIndex = sectionIndex
        self.changes = changes
    }
    
    override func execute() {
        collectionView.performBatchUpdates({ [weak self] in
             self?.performUpdates()
        }) { [weak self] (finished) in
            self?.completeOperation()
        }
    }

    private func performUpdates() {
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
            let at = IndexPath(item: fromIndex, section: self.sectionIndex)
            let to = IndexPath(item: toIndex, section: self.sectionIndex)
            self.collectionView.moveItem(at: at, to: to)
        }
    }
}

private extension IndexSet {
    func getIndexPaths(for sectionIndex: Int) -> [IndexPath]? {
        let result = map { IndexPath(item: $0, section: sectionIndex) }
        return result.isEmpty ? nil : result
    }
}
