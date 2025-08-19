// MARK: - Ячейка для дня недели

import UIKit

final class NewDayRow: UIView {
    // MARK: Public API
    /// Колбэк, вызывается при переключении свитча
    var onToggle: ((Bool) -> Void)?

    /// Текущее состояние
    var isOn: Bool {
        get { switcher.isOn }
        set { switcher.setOn(newValue, animated: false) }
    }

    /// Установить состояние программно
    func setSwitchOn(_ on: Bool, animated: Bool = false) {
        switcher.setOn(on, animated: animated)
    }

    // MARK: UI
    private let titleLabel = UILabel()
    private let switcher = UISwitch()

    // MARK: Init
    init(title: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 75).isActive = true

        // Title
        titleLabel.text = title
        titleLabel.font = UIFont(name: "SFPro-Regular", size: 17)
        titleLabel.lineHeight(22)

        // Switch
        switcher.onTintColor = .blue
        switcher.setContentHuggingPriority(.required, for: .horizontal)
        switcher.setContentCompressionResistancePriority(.required, for: .horizontal)
        switcher.addTarget(self, action: #selector(switchChanged), for: .valueChanged)

        // Stack
        let hStack = UIStackView(arrangedSubviews: [titleLabel, switcher])
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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) не реализовано")
    }

    // MARK: Actions
    @objc private func switchChanged() {
        onToggle?(switcher.isOn)
    }
}
