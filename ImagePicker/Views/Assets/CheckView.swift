//  Copyright © 2018 INLOOPX. All rights reserved.

import UIKit

final class CheckView: UIImageView {
    var foregroundImage: UIImage? {
        get { return foregroundView.image }
        set { foregroundView.image = newValue }
    }
    
    private let foregroundView = UIImageView(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        foregroundView.frame = bounds
    }
    
    private func initializeViews() {
        addSubview(foregroundView)
        contentMode = .center
        foregroundView.contentMode = .center
    }
}
