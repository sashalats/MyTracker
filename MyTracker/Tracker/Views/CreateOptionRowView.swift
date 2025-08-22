import UIKit

// MARK: - Кастомный блок с заголовком, подзаголовком и стрелкой
final class CreateOptionRowView: UIView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(named: "chevronForField"))
    
    private var centerYConstraint: NSLayoutConstraint!
    private var topTitleConstraint: NSLayoutConstraint!
    private var bottomSubtitleConstraint: NSLayoutConstraint!
    
    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = .clear
        
        titleLabel.text = title
        titleLabel.font = UIFont(name: "SFPro-Regular", size: 17)
        titleLabel.textColor = .blackDayNew
        
        subtitleLabel.font = UIFont(name: "SFPro-Regular", size: 17)
        subtitleLabel.textColor = .grayText
        
        [titleLabel, subtitleLabel, chevron].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        // Chevron
        NSLayoutConstraint.activate([
            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Заголовок
        topTitleConstraint = titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 15)
        centerYConstraint = titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        
        // Подзаголовок
        bottomSubtitleConstraint = subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        ])
        
        updateLayout(animated: false)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }
    
    // MARK: - Public
    func updateSubtitle(_ text: String?) {
        subtitleLabel.text = text
        updateLayout(animated: true)
    }
    
    // MARK: - Private
    private func updateLayout(animated: Bool) {
        [topTitleConstraint, centerYConstraint, bottomSubtitleConstraint].forEach { $0.isActive = false }
        
        if let text = subtitleLabel.text, !text.isEmpty {
            topTitleConstraint.isActive = true
            bottomSubtitleConstraint.isActive = true
        } else {
            centerYConstraint.isActive = true
        }
        
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }
}


