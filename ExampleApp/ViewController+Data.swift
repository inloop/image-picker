// Copyright © 2018 INLOOPX. All rights reserved.

import UIKit

extension ViewController {
    typealias CellConfigurationBlock = ((UITableViewCell, ViewController) -> Void)?
    
    enum SelectorArgument {
        case indexPath
        case none
    }
    
    struct CellData {
        var title: String
        var selector: Selector
        var selectorArgument: SelectorArgument
        var configBlock: CellConfigurationBlock
        
        init(_ title: String, _ selector: Selector, _ selectorArgument: SelectorArgument, _ configBlock: CellConfigurationBlock) {
            self.title = title
            self.selector = selector
            self.selectorArgument = selectorArgument
            self.configBlock = configBlock
        }
    }
    
    static let cellsData: [[CellData]] = [
        [
            CellData("As input view", #selector(ViewController.togglePresentationMode(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.presentsModally ? .none : .checkmark }),
            CellData("Modally", #selector(ViewController.togglePresentationMode(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.presentsModally ? .checkmark : .none })
        ],
        [
            CellData("Disabled", #selector(ViewController.setNumberOfActionItems(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.numberOfActionItems == 0 ? .checkmark : .none }),
            CellData("One item", #selector(ViewController.setNumberOfActionItems(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.numberOfActionItems == 1 ? .checkmark : .none }),
            CellData("Two items (default)", #selector(ViewController.setNumberOfActionItems(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.numberOfActionItems == 2 ? .checkmark : .none }),
            ],
        [
            CellData("Enabled (default)", #selector(ViewController.configCameraItem(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.cameraConfig == .enabled ? .checkmark : .none }),
            CellData("Disabled", #selector(ViewController.configCameraItem(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.cameraConfig == .disabled ? .checkmark : .none })
        ],
        [
            CellData("Camera Roll (default)", #selector(ViewController.configAssetsSource(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.assetsSource == .recentlyAdded ? .checkmark : .none }),
            CellData("Only videos", #selector(ViewController.configAssetsSource(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.assetsSource == .onlyVideos ? .checkmark : .none }),
            CellData("Only selfies", #selector(ViewController.configAssetsSource(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.assetsSource == .onlySelfies ? .checkmark : .none })
        ],
        [
            CellData("One", #selector(ViewController.configAssetItemsInRow(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.assetItemsInRow == 1 ? .checkmark : .none }),
            CellData("Two (default)", #selector(ViewController.configAssetItemsInRow(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.assetItemsInRow == 2 ? .checkmark : .none }),
            CellData("Three", #selector(ViewController.configAssetItemsInRow(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.assetItemsInRow == 3 ? .checkmark : .none })
        ],
        [
            CellData("Only Photos (default)", #selector(ViewController.configCaptureMode(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.captureMode == .photo ? .checkmark : .none }),
            CellData("Photos and Live Photos", #selector(ViewController.configCaptureMode(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.captureMode == .photoAndLivePhoto ? .checkmark : .none }),
            CellData("Photos and Videos", #selector(ViewController.configCaptureMode(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.captureMode == .photoAndVideo ? .checkmark : .none })
        ],
        [
            CellData("Disabled (default)", #selector(ViewController.configDragAndDrop(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.dragAndDropConfig ? .none : .checkmark }),
            CellData("Enabled", #selector(ViewController.configDragAndDrop(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.dragAndDropConfig ? .checkmark : .none })
        ],
        [
            CellData("Don't save (default)", #selector(ViewController.configSavesCapturedAssets(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.savesCapturedAssets ? .none : .checkmark }),
            CellData("Save", #selector(ViewController.configSavesCapturedAssets(indexPath:)), .indexPath,
                     { cell, controller in cell.accessoryType = controller.savesCapturedAssets ? .checkmark : .none })
        ]
    ]
    
    static let sectionsData: [(String?, String?)] = [
        ("Presentation", nil),
        ("Action Items", nil),
        ("Camera Item", nil),
        ("Assets Source", nil),
        ("Asset Items in a row", nil),
        ("Capture mode", nil),
        ("Drag and drop", nil),
        ("Save Assets", "Assets will be saved to Photo Library. This applies to photos only. Live photos and videos are always saved.")
    ]
}

