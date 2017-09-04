//
//  ViewController.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import UIKit
import ImagePicker

class ViewController: UITableViewController {

    private var allowsFirstResponser = false
    private var currentInputView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cellId")
        tableView.keyboardDismissMode = .onDrag
        
        //for quick debugging
        //presentPickerModally(animated: false)
    }

    func presentPickerModally(animated: Bool) {
        print("presenting modally")
        let vc = ImagePickerViewController()
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Dismiss", style: .done, target: self, action: #selector(dismissPresentedImagePicker(sender:)))
        let nc = UINavigationController(rootViewController: vc)
        present(nc, animated: animated, completion: nil)
    }
    
    dynamic func dismissPresentedImagePicker(sender: UIBarButtonItem) {
        navigationController?.visibleViewController?.dismiss(animated: true, completion: nil)
    }
    
    func presentPickerAsInputView() {
        print("presenting as input view")
        
        let vc = ImagePickerViewController()
        vc.view.autoresizingMask = .flexibleHeight
        currentInputView = vc.view
        
        allowsFirstResponser = true
        
        becomeFirstResponder()
    }
    
    override var canBecomeFirstResponder: Bool {
        return allowsFirstResponser
    }
    
    override var inputView: UIView? {
        return currentInputView
    }
    
}

extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)
        switch indexPath.row {
        case 0: cell.textLabel?.text = "Presented view controller"
        case 1: cell.textLabel?.text = "As input view"
        default: fatalError("not implemented")
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0: presentPickerModally(animated: true)
        case 1: presentPickerAsInputView()
        default: fatalError("not implemented")
        }
    }
    
}

