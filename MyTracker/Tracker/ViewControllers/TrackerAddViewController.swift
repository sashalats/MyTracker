import UIKit

final class TrackerAddViewController: UIViewController {
    
    private let emojiAndColorPicker = EmojiAndColorPickerView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    var onCreate: ((TrackerCategory) -> Void)?
    
    private var selectedCategoryTitle: String? = "Важное"
    private var selectedDays: [DayOfWeek] = []
    var onScheduleSelected: (([DayOfWeek]) -> Void)?
    
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
    private lazy var scheduleRow: NewHabitRow = {
        let row = NewHabitRow(title: "Расписание")
        row.setOnTap { [weak self, weak row] in
            guard let self = self, let row = row else { return }
            ScheduleViewController.present(
                from: self,
                preselected: Set(self.selectedDays)
            ) { [weak self, weak row] days in
                guard let self = self, let row = row else { return }
                self.selectedDays = days
                row.updateSubtitle(self.formatDays(days))
                self.updateCreateButtonState()
                print("[AddVC] received days from ScheduleVC:", days)
            }
        }
        return row
    }()
    
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
        // Default subtitles
        categoryRow.updateSubtitle("Важное")
        if !selectedDays.isEmpty { scheduleRow.updateSubtitle(formatDays(selectedDays)) }
        
        titleLabel.lineHeight(22)
        cancelButton.titleLabel?.lineHeight(22)
        createButton.titleLabel?.lineHeight(22)
        
        // Listeners
        nameField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        emojiAndColorPicker.onChange = { [weak self] in
            self?.updateCreateButtonState()
        }
        
        cancelButton.addTarget(self, action: #selector(closeSheet), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        
        // Initial state
        updateCreateButtonState()
    }
    
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
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
        
        [stack, emojiAndColorPicker, buttonStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            emojiAndColorPicker.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 32),
            emojiAndColorPicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            emojiAndColorPicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            emojiAndColorPicker.bottomAnchor.constraint(lessThanOrEqualTo: buttonStack.topAnchor, constant: -16),
            
            buttonStack.topAnchor.constraint(equalTo: emojiAndColorPicker.bottomAnchor, constant: 16),
            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func closeSheet() {
        dismiss(animated: true, completion: nil)
    }
    
    private func createTracker() {
        guard let name = nameField.text, !name.isEmpty else { return }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        let categoryStore = TrackerCategoryStore(context: context)
        let trackerStore = TrackerStore(context: context)
        
        let id = UUID()
        let emoji = emojiAndColorPicker.selectedEmoji ?? "❤️"
        let color = emojiAndColorPicker.selectedColor ?? .blueApp
        let colorHex = color.toHexString()
        let schedule = selectedDays
        print("[AddVC] schedule to save:", schedule)
        let categoryTitle = (selectedCategoryTitle ?? "Важное")
        
        let categoryEntity = categoryStore.createCategoryIfNeeded(title: categoryTitle)
        trackerStore.addTracker(
            id: id,
            name: name,
            emoji: emoji,
            colorHex: colorHex,
            schedule: schedule,
            category: categoryEntity
        )
        
        let trackerModel = Tracker(
            id: id,
            name: name,
            color: color,
            emoji: emoji,
            schedule: schedule,
            isPinned: false
        )
        let categoryModel = TrackerCategory(title: categoryTitle, trackers: [trackerModel])
        onCreate?(categoryModel)
        
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func createButtonTapped() {
        createTracker()
    }
    
    @objc private func textFieldChanged() {
        updateCreateButtonState()
    }
    
    private func updateCreateButtonState() {
        let hasName = !(nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasCategory = !(selectedCategoryTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasSchedule = !selectedDays.isEmpty
        let hasEmoji = emojiAndColorPicker.selectedEmoji != nil
        let hasColor = emojiAndColorPicker.selectedColor != nil
        
        let enabled = hasName && hasCategory && hasSchedule && hasEmoji && hasColor
        createButton.isEnabled = enabled
        createButton.backgroundColor = enabled ? .black : UIColor(red: 0.65, green: 0.66, blue: 0.69, alpha: 1)
    }
    
    private func formatDays(_ days: [DayOfWeek]) -> String {
        if days.isEmpty { return "" }
        if days.count == DayOfWeek.allCases.count { return "Каждый день" }
        let map: [DayOfWeek: String] = [
            .monday: "Понедельник", .tuesday: "Вторник", .wednesday: "Среда",
            .thursday: "Четверг", .friday: "Пятница", .saturday: "Суббота", .sunday: "Воскресенье"
        ]
        // Если дней много, показываем коротко
        if days.count >= 2 {
            let short: [DayOfWeek: String] = [
                .monday: "Пн", .tuesday: "Вт", .wednesday: "Ср",
                .thursday: "Чт", .friday: "Пт", .saturday: "Сб", .sunday: "Вс"
            ]
            return days.sorted { $0.rawValue < $1.rawValue }.compactMap { short[$0] }.joined(separator: ", ")
        }
        // Один день — полное имя
        if let only = days.first, let full = map[only] { return full }
        return ""
    }
    
    static func present(from parent: UIViewController, onCreate: @escaping (TrackerCategory) -> Void) {
        let modalVC = TrackerAddViewController()
        modalVC.modalPresentationStyle = .pageSheet
        modalVC.onCreate = onCreate
        parent.present(modalVC, animated: true, completion: nil)
    }
}
