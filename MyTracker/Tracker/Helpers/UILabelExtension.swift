import UIKit

extension UILabel {
    func lineHeight(_ height: CGFloat) {
        guard let text = self.text else { return }
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = height
        style.maximumLineHeight = height
        style.alignment = self.textAlignment
        
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, attributedString.length))
        self.attributedText = attributedString
    }
}
