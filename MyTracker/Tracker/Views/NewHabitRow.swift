// MARK: - Ячейка для категории и расписания

import UIKit
final class NewHabitRow: UIView {
    private var onTap: (() -> Void)?
    private let subtitleLabel = UILabel()
    
    init(title: String, onTap: (() -> Void)? = nil) {
        self.onTap = onTap
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 75).isActive = true
        
        let label = UILabel()
        label.text = title
        label.font = UIFont(name: "SFPro-Regular", size: 17)
        label.lineHeight(22)
        
        subtitleLabel.font = UIFont(name: "SFPro-Regular", size: 17)
        subtitleLabel.textColor = UIColor(hex: "#AEAFB4")
        subtitleLabel.lineHeight(22)
        subtitleLabel.isHidden = true
        subtitleLabel.numberOfLines = 1
        
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .lightGray
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        chevron.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let vStack = UIStackView(arrangedSubviews: [label, subtitleLabel])
        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.spacing = 2
        
        let hStack = UIStackView(arrangedSubviews: [vStack, chevron])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.distribution = .equalSpacing
        hStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            hStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }
    
    func setOnTap(_ action: @escaping () -> Void) {
        self.onTap = action
    }
    
    func updateSubtitle(_ text: String?) {
        let trimmed = (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        subtitleLabel.text = trimmed
        subtitleLabel.isHidden = trimmed.isEmpty
        subtitleLabel.lineHeight(18)
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    @objc private func handleTap() {
        onTap?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
