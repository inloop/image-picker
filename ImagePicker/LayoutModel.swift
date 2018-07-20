// Copyright © 2018 INLOOPX. All rights reserved.

import Foundation

/// A model that contains info that is used by layout code and collection view data source
/// when figuring out layout structure.
///
/// Always contains 3 sections:
/// 1. for actions (supports up to 2 action items)
/// 2. for camera (1 camera item)
/// 3. for image assets (any number of image asset items)
/// Each section can be empty.

struct LayoutModel {
    var numberOfSections: Int { return sections.count }
    private var sections: [Int] = [0, 0, 0]
    
    init(configuration: LayoutConfiguration, assets: Int) {
        var actionItems: Int = configuration.showsFirstActionItem ? 1 : 0
        actionItems += configuration.showsSecondActionItem ? 1 : 0
        sections[configuration.sectionIndexForActions] = actionItems
        sections[configuration.sectionIndexForCamera] = configuration.showsCameraItem ? 1 : 0
        sections[configuration.sectionIndexForAssets] = assets
    }
 
    func numberOfItems(in section: Int) -> Int {
        return sections[section]
    }
    
    static var empty: LayoutModel {
        let emptyConfiguration = LayoutConfiguration(showsFirstActionItem: false, showsSecondActionItem: false,
                                                     showsCameraItem: false, scrollDirection: .horizontal,
                                                     numberOfAssetItemsInRow: 0, interitemSpacing: 0,
                                                     actionSectionSpacing: 0, cameraSectionSpacing: 0)
        return LayoutModel(configuration: emptyConfiguration, assets: 0)
    }
}
