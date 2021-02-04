// Copyright © 2018 INLOOPX. All rights reserved.

import UIKit

/// A label whose transparent text is carved into solid color.
/// - please note that text is always aligned to center

@IBDesignable
final class CarvedLabel: UIView {
    @IBInspectable var text: String? {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet { setNeedsDisplay() }
    }
    
    @IBInspectable var verticalInset: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var horizontalInset: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    
    var font: UIFont? {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
    
    override var backgroundColor: UIColor? {
        get { return .clear }
        set { super.backgroundColor = .clear }
    }
    
    private typealias TextAttributes = [NSAttributedString.Key: Any]
    private var textAttributes: TextAttributes {
        let activeFont = font ?? UIFont.systemFont(ofSize: 12, weight: .regular)
        return [NSAttributedString.Key.font: activeFont]
    }
    
    private var attributedString: NSAttributedString {
        return NSAttributedString(string: text ?? "", attributes: textAttributes)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _ = backgroundColor
        isOpaque = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _ = backgroundColor
        isOpaque = false
    }
    
    override func draw(_ rect: CGRect) {
        let color = tintColor!
        color.setFill()
        
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        path.fill()
        
        drawText(rect)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let stringSize = attributedString.size()
        return CGSize(width: stringSize.width + horizontalInset * 2, height: stringSize.height + verticalInset * 2)
    }

    override var intrinsicContentSize: CGSize {
        return sizeThatFits(.zero)
    }
    
    private func drawText(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let textCount = text?.count, textCount > 0 else { return }
        
        let stringSize = attributedString.size()
        let xOrigin: CGFloat = max(horizontalInset, (rect.width - stringSize.width) / 2)
        let yOrigin: CGFloat = max(verticalInset, (rect.height - stringSize.height) / 2)
        
        context.saveGState()
        context.setBlendMode(.destinationOut)
        attributedString.draw(at: CGPoint(x: xOrigin, y: yOrigin))
        context.restoreGState()
    }
}
