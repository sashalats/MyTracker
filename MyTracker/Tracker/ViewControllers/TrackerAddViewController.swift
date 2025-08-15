import UIKit

class TrackerAddViewController: UIViewController {
    
    var onCreate: ((TrackerCategory) -> Void)?
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Новая привычка"
        label.font = UIFont(name: "SFPro-Medium", size: 16)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Введите название трекера"
        textField.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1) // #F7F8F9
        textField.layer.cornerRadius = 16
        textField.font = UIFont(name: "SFPro-Regular", size: 17)
        textField.setLeftPaddingPoints(16)
        textField.heightAnchor.constraint(equalToConstant: 75).isActive = true
        return textField
    }()
    
    private let selectionContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var categoryRow = NewHabitRow(title: "Категория") { [weak self] in
        print("Список категорий")
    }
    private lazy var scheduleRow = NewHabitRow(title: "Расписание") { [weak self] in
        guard let self = self else { return }
        ScheduleViewController.present(from: self)
    }
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Отменить", for: .normal)
        button.titleLabel?.font = UIFont(name: "SFPro-Medium", size: 16)
        button.titleLabel?.lineHeight(22)
        button.setTitleColor(.systemRed, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemRed.cgColor
        return button
    }()
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Создать", for: .normal)
        button.titleLabel?.font = UIFont(name: "SFPro-Medium", size: 16)
        button.titleLabel?.lineHeight(22)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 0.65, green: 0.66, blue: 0.69, alpha: 1) // #A6A7AB
        button.layer.cornerRadius = 16
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        titleLabel.lineHeight(22)
        cancelButton.titleLabel?.lineHeight(22)
        createButton.titleLabel?.lineHeight(22)
        cancelButton.addTarget(self, action: #selector(closeSheet), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
    }
    
    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            nameField,
            selectionContainer
        ])
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let separator = UIView()
        separator.backgroundColor = UIColor(red: 0.75, green: 0.76, blue: 0.77, alpha: 1)
        separator.translatesAutoresizingMaskIntoConstraints = false
        let selectionStack = UIStackView(arrangedSubviews: [categoryRow, separator, scheduleRow])
        selectionStack.axis = .vertical
        selectionStack.spacing = 0
        selectionStack.translatesAutoresizingMaskIntoConstraints = false
        
        selectionContainer.addSubview(selectionStack)
        NSLayoutConstraint.activate([
            selectionStack.topAnchor.constraint(equalTo: selectionContainer.topAnchor),
            selectionStack.leadingAnchor.constraint(equalTo: selectionContainer.leadingAnchor, constant: 16),
            selectionStack.trailingAnchor.constraint(equalTo: selectionContainer.trailingAnchor, constant: -16),
            selectionStack.bottomAnchor.constraint(equalTo: selectionContainer.bottomAnchor),
            
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        
        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, createButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stack)
        view.addSubview(buttonStack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 13),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    @objc private func closeSheet() {
        dismiss(animated: true, completion: nil)
    }
    
    
    private func createTracker() {
        guard let name = nameField.text, !name.isEmpty else { return }
        
        let newTracker = Tracker(
            id: UUID(),
            name: name,
            color: UIColor.systemBlue,
            emoji: "❤️",
            schedule: DayOfWeek.allCases,
            isPinned: false
        )
        
        let category = TrackerCategory(
            title: "Домашний уют",
            trackers: [newTracker]
        )
        
        onCreate?(category)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func createButtonTapped() {
        createTracker()
    }
    
    static func present(from parent: UIViewController, onCreate: @escaping (TrackerCategory) -> Void) {
        let modalVC = TrackerAddViewController()
        modalVC.modalPresentationStyle = .pageSheet
        modalVC.onCreate = onCreate
        parent.present(modalVC, animated: true, completion: nil)
    }
}
