// MARK: - Ячейка для дня недели

import UIKit

class NewDayRow: UIView {
    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        let label = UILabel()
        label.text = title
        label.font = UIFont(name: "SFPro-Regular", size: 17)
        label.lineHeight(22)
        
        let switcher = UISwitch()
        switcher.onTintColor = .blue
        switcher.setContentHuggingPriority(.required, for: .horizontal)
        switcher.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let hStack = UIStackView(arrangedSubviews: [label, switcher])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .equalSpacing
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(hStack)
        
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            hStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не реализовано")
    }
}
