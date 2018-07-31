// Copyright © 2018 INLOOPX. All rights reserved.

import Photos

@available(iOS 11.0, *)
extension ViewController {
    func setupDragDestination() {
        let interaction = UIDropInteraction(delegate: self)
        dropAssetsView.addInteraction(interaction)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let items = session.localDragSession?.items else { return }
        for item in items {
            if let asset = item.localObject as? PHAsset {
                print("Dropped asset: \(asset.localIdentifier)")
            }
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        guard let items = session.localDragSession?.items else { return false }
        for item in items {
            if item.localObject is PHAsset {
                return true
            }
        }
        return false
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
}


