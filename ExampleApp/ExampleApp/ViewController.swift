//
//  ViewController.swift
//  ExampleApp
//
//  Created by Peter Stajger on 04/09/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import UIKit
import ImagePicker



///
/// This is an example view controller that shows how Image Picker can be used
///
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

    func presentPickerModally() {
        print("presenting modally")
        
        var configuration = LayoutConfiguration.default
        configuration.scrollDirection = .vertical
        configuration.showsCameraActionItem = false
        configuration.numberOfAssetItemsInRow = 3
        
        let registrator = CellRegistrator()
        let actionNib = UINib(nibName: "IconWithTextCell", bundle: nil)
        registrator.register(nib: actionNib, forActionItemAt: 0)
        registrator.register(nib: actionNib, forActionItemAt: 1)
        let assetNib = UINib(nibName: "ImageCell", bundle: nil)
        registrator.register(nib: assetNib, forAssetItemOf: .image)
        
        let vc = ImagePickerViewController()
        vc.layoutConfiguration = configuration
        vc.cellRegistrator = registrator
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Dismiss", style: .done, target: self, action: #selector(dismissPresentedImagePicker(sender:)))
        let nc = UINavigationController(rootViewController: vc)
        present(nc, animated: true, completion: nil)
    }
    
    func presentPickerAsInputView() {
        print("presenting as input view")
        
        let registrator = CellRegistrator()
        let actionNib = UINib(nibName: "IconWithTextCell", bundle: nil)
        let assetNib = UINib(nibName: "ImageCell", bundle: nil)
        //registrator.register(nib: assetNib, forActionItemAt: 0)
        //registrator.register(nib: assetNib, forActionItemAt: 1)
        //registrator.register(cellClass: GreenCell.self, forActionItemAt: 1)
        
        registrator.registerNibForActionItems(actionNib)
        registrator.register(nib: assetNib, forAssetItemOf: .image)
        
        let vc = ImagePickerViewController()
        vc.cellRegistrator = registrator
        vc.delegate = self
        
        //if you want to present view as input view, you have to set flexible height
        //to adopt natural keyboard height or just set an layout constraint height 
        //for specific height.
        vc.view.autoresizingMask = .flexibleHeight
        currentInputView = vc.view
        
        allowsFirstResponser = true
        
        becomeFirstResponder()
    }
    
    dynamic func dismissPresentedImagePicker(sender: UIBarButtonItem) {
        navigationController?.visibleViewController?.dismiss(animated: true, completion: nil)
    }
    
    override var canBecomeFirstResponder: Bool {
        return allowsFirstResponser
    }
    
    override var inputView: UIView? {
        return currentInputView
    }
    
}

extension ViewController : ImagePickerViewControllerDelegate {
    
    public func imagePicker(controller: ImagePickerViewController, didSelectActionItemAt index: Int) {
        print("did select action \(index)")
    }
    
    public func imagePicker(controller: ImagePickerViewController, didSelect asset: Asset) {
        print("did select asset \(asset)")
    }
    
    public func imagePicker(controller: ImagePickerViewController, didTake image: UIImage) {
        print("did take image \(image.size)")
    }
    
}

let data = [
    [
        ("Presented modally", #selector(ViewController.presentPickerModally)),],
    [
        ("As input view", #selector(ViewController.presentPickerAsInputView))]
]
let selectors = [#selector(ViewController.presentPickerAsInputView)]

extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath)
        cell.textLabel?.text = data[indexPath.section][indexPath.row].0
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        perform(data[indexPath.section][indexPath.row].1)
    }
    
}

