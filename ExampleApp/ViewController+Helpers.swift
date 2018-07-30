// Copyright © 2018 INLOOPX. All rights reserved.

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
        return ViewController.cellsData.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ViewController.cellsData[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)
        cell.textLabel?.text = ViewController.cellsData[indexPath.section][indexPath.row].title
        if let configBlock = ViewController.cellsData[indexPath.section][indexPath.row].configBlock {
            configBlock(cell, self)
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selector = ViewController.cellsData[indexPath.section][indexPath.row].selector
        let argumentType = ViewController.cellsData[indexPath.section][indexPath.row].selectorArgument
        
        switch argumentType {
        case .indexPath:
            perform(selector, with: indexPath)
        default:
            perform(selector)
        }
        
        uncheckCellsInSection(except: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ViewController.sectionsData[section].0
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return ViewController.sectionsData[section].1
    }
}

// MARK: Helper Code
extension ViewController {
    static let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    func uncheckCellsInSection(except indexPath: IndexPath){
        for path in tableView.indexPathsForVisibleRows ?? [] where path.section == indexPath.section {
            let cell = tableView.cellForRow(at: path)!
            cell.accessoryType = path == indexPath ? .checkmark : .none
        }
    }
}
