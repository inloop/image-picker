//
//  BaseTableViewController.swift
//  ExampleApp
//
//  Created by Peter Stajger on 03/10/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import UIKit

// MARK: UIResponsder Methods

extension ViewController {

    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result == true {
            currentInputView = nil
        }
        return result
    }
    
    override var inputView: UIView? {
        return currentInputView
    }
    
    override var inputAccessoryView: UIView? {
        return presentButton
    }
    
}

// MARK: UITableViewDataSource & UITableViewDelegate Methods

extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return cellsData.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellsData[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)
        cell.textLabel?.text = cellsData[indexPath.section][indexPath.row].title
        if let configBlock = cellsData[indexPath.section][indexPath.row].configBlock {
            configBlock(cell, self)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // deselect
        tableView.deselectRow(at: indexPath, animated: true)
        
        // perform selector
        let selector = cellsData[indexPath.section][indexPath.row].selector
        let argumentType = cellsData[indexPath.section][indexPath.row].selectorArgument
        switch argumentType {
        case .indexPath: perform(selector, with: indexPath)
        default: perform(selector)
        }
        
        // update checks in section
        uncheckCellsInSection(except: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionsData[section].0
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sectionsData[section].1
    }
    
}

// MARK: Helper Code

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

typealias CellConfigurationBlock = ((UITableViewCell, ViewController) -> Void)?

extension ViewController {
    
    func uncheckCellsInSection(except indexPath: IndexPath){
        for path in tableView.indexPathsForVisibleRows ?? [] where path.section == indexPath.section {
            let cell = tableView.cellForRow(at: path)!
            cell.accessoryType = path == indexPath ? .checkmark : .none
        }
    }
    
}
