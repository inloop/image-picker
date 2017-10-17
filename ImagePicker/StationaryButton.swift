//
//  StationaryButton.swift
//  ImagePicker
//
//  Created by Peter Stajger on 17/10/2017.
//  Copyright © 2017 Inloop. All rights reserved.
//

import Foundation

///
/// A button that keeps selected state when selected.
///
class StationaryButton : UIButton {
    
    var unselectedTintColor: UIColor?
    var selectedTintColor: UIColor?
    
    open override var isSelected: Bool {
        get { return super.isSelected }
        set { setSelected(newValue, animated: false) }
    }
    
    open override var isHighlighted: Bool {
        didSet {
            if isHighlighted == false {
                setSelected(!isSelected, animated: true)
            }
        }
    }
    
    public func setSelected(_ selected: Bool, animated: Bool) {
        
        guard isSelected != selected else {
            return
        }
        
        super.isSelected = selected
        selectionDidChange(animated: animated)
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        updateTint()
    }
    
    ///
    /// Override this method to track when button's state is selected or deselected.
    /// You dont need to call super, default implementation does nothing.
    ///
    open func selectionDidChange(animated: Bool) {
        updateTint()
    }
    
    private func updateTint() {
        if isSelected {
            tintColor = selectedTintColor
        }
        else {
            tintColor = unselectedTintColor
        }
    }
}
