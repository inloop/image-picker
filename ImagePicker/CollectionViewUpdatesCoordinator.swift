// Copyright © 2018 INLOOPX. All rights reserved.

import Photos

/// Makes sure that all updates are performed in a serial queue, especially batch animations. This
/// will make sure that reloadData() will never be called durring batch updates animations, which
/// will prevent collection view from crashing on internal incosistency.

final class CollectionViewUpdatesCoordinator {
    private let collectionView: UICollectionView
    private var serialMainQueue = OperationQueue()
    
    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        serialMainQueue.maxConcurrentOperationCount = 1
        serialMainQueue.underlyingQueue = DispatchQueue.main
    }
    
    deinit {
        log("deinit: \(String(describing: self))")
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
        } else {
            serialMainQueue.addOperation { [weak self] in
                self?.collectionView.reloadData()
            }
        }
    }
}
