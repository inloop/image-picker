//
//  LayoutModel.swift
//  ExampleApp
//
//  Created by Peter Stajger on 05/09/2017.
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
        return LayoutModel(configuration: LayoutConfiguration.default, assets: 0)
    }
}
