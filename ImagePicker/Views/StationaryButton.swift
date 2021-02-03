// Copyright © 2018 INLOOPX. All rights reserved.

import UIKit

/// A button that keeps selected state when selected.

class StationaryButton: UIButton {
    var unselectedTintColor: UIColor?
    var selectedTintColor: UIColor?
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        updateTint()
    }
    
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
        guard isSelected != selected else { return }
        super.isSelected = selected
        selectionDidChange(animated: animated)
    }
    
    /// Override this method to track when button's state is selected or deselected.
    /// You dont need to call super, default implementation does nothing.
    open func selectionDidChange(animated: Bool) {
        updateTint()
    }
    
    private func updateTint() {
        tintColor = isSelected ? selectedTintColor : unselectedTintColor
    }
}
