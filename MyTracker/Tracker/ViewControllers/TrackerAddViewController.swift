import UIKit

class TrackerAddViewController: UIViewController {
    
    private let emojiAndColorPicker = EmojiAndColorPickerView()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    var onCreate: ((TrackerCategory) -> Void)?
    
    private var selectedCategoryTitle: String? = nil
    private var selectedDays: [DayOfWeek] = []
    var onScheduleSelected: (([DayOfWeek]) -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.newHabitButton
        label.font = UIFont(name: "SFPro-Medium", size: 16)
        label.textColor = .blackDayNew
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameField: UITextField = {
        let textField = UITextField()
        textField.placeholder = L10n.trackerNamePlaceholder
        textField.backgroundColor = .fieldBackground.withAlphaComponent(0.3)
        textField.textColor = .blackDayNew
        textField.layer.cornerRadius = 16
        textField.font = UIFont(name: "SFPro-Regular", size: 17)
        textField.setLeftPaddingPoints(16)
        textField.heightAnchor.constraint(equalToConstant: 75).isActive = true
        return textField
    }()
    
    private let selectionContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .fieldBackground.withAlphaComponent(0.3)
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var categoryRow: NewHabitRow = {
        let row = NewHabitRow(title: L10n.categoryLabel)
        row.setOnTap { [weak self] in
            self?.presentCategoryPicker()
        }
        return row
    }()
    private lazy var scheduleRow: NewHabitRow = {
        let row = NewHabitRow(title: L10n.schedule)
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
        button.setTitle(L10n.cancelButton, for: .normal)
        button.titleLabel?.font = UIFont(name: "SFPro-Medium", size: 16)
        button.titleLabel?.lineHeight(22)
        button.setTitleColor(.redYPcolor, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.redYPcolor.cgColor
        return button
    }()
    
    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(L10n.categoryCreateButton, for: .normal)
        button.titleLabel?.font = UIFont(name: "SFPro-Medium", size: 16)
        button.titleLabel?.lineHeight(22)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .grayText
        button.layer.cornerRadius = 16
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteDayNew
        setupLayout()

        if !selectedDays.isEmpty { scheduleRow.updateSubtitle(formatDays(selectedDays)) }
        
        titleLabel.lineHeight(22)
        cancelButton.titleLabel?.lineHeight(22)
        createButton.titleLabel?.lineHeight(22)
        
        nameField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        emojiAndColorPicker.onChange = { [weak self] in
            self?.updateCreateButtonState()
        }
        
        cancelButton.addTarget(self, action: #selector(closeSheet), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
        
        nameField.returnKeyType = .done
        nameField.delegate = self
        
        enableHideKeyboardOnTap()
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
        separator.backgroundColor = .grayText
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
    
    // MARK: - Category picker
    private func presentCategoryPicker() {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        let store = TrackerCategoryStore(context: app.persistentContainer.viewContext)
        let viewModel = TrackerCategoryViewModel(categoryStore: store)
        let categoryVC = CategorySelectionViewController(viewModel: viewModel)

        categoryVC.onCategorySelected = { [weak self] category in
            guard let self = self else { return }
            let title = category.title?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let t = title, !t.isEmpty {
                self.selectedCategoryTitle = t
                self.categoryRow.updateSubtitle(t)
            } else {
                self.selectedCategoryTitle = nil
                self.categoryRow.updateSubtitle("")
            }
            self.updateCreateButtonState()
        }

        let nav = UINavigationController(rootViewController: categoryVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    @objc private func closeSheet() {
        dismiss(animated: true, completion: nil)
    }
    
    private func createTracker() {
        guard
            let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !name.isEmpty
        else { return }

        guard
            let categoryTitle = selectedCategoryTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
            !categoryTitle.isEmpty
        else { return }

        guard
            let emoji = emojiAndColorPicker.selectedEmoji,
            let uiColor = emojiAndColorPicker.selectedColor,
            !selectedDays.isEmpty
        else { return }

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        let categoryStore = TrackerCategoryStore(context: context)
        let trackerStore  = TrackerStore(context: context)

        let categoryEntity = categoryStore.createCategoryIfNeeded(title: categoryTitle)

        let id = UUID()
        let colorHex = uiColor.toHexString()
        let schedule = selectedDays

        print("[AddVC] will save tracker:",
              "id=\(id.uuidString)",
              "name=\(name)",
              "category='\(categoryTitle)'",
              "emoji=\(emoji)",
              "colorHex=\(colorHex)",
              "schedule=\(schedule.map { $0.rawValue })")

        trackerStore.addTracker(
            id: id,
            name: name,
            emoji: emoji,
            colorHex: colorHex,
            schedule: schedule,
            category: categoryEntity
        )

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
        let hasCategory = (selectedCategoryTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        let hasSchedule = !selectedDays.isEmpty
        let hasEmoji = emojiAndColorPicker.selectedEmoji != nil
        let hasColor = emojiAndColorPicker.selectedColor != nil
        
        let enabled = hasName && hasCategory && hasSchedule && hasEmoji && hasColor
        createButton.isEnabled = enabled
        createButton.backgroundColor = enabled ? .blackDayNew : .grayText
    }
    
    private func formatDays(_ days: [DayOfWeek]) -> String {
        if days.isEmpty { return "" }
        if days.count == DayOfWeek.allCases.count { return L10n.everyDay }

        let full: [DayOfWeek: String] = [
            .monday: L10n.mondayFull,
            .tuesday: L10n.tuesdayFull,
            .wednesday: L10n.wednesdayFull,
            .thursday: L10n.thursdayFull,
            .friday: L10n.fridayFull,
            .saturday: L10n.saturdayFull,
            .sunday: L10n.sundayFull
        ]
        let short: [DayOfWeek: String] = [
            .monday: L10n.mondayShort,
            .tuesday: L10n.tuesdayShort,
            .wednesday: L10n.wednesdayShort,
            .thursday: L10n.thursdayShort,
            .friday: L10n.fridayShort,
            .saturday: L10n.saturdayShort,
            .sunday: L10n.sundayShort
        ]

        if days.count >= 2 {
            return days.sorted { $0.rawValue < $1.rawValue }
                .compactMap { short[$0] }
                .joined(separator: ", ")
        }
        if let only = days.first, let name = full[only] { return name }
        return ""
    }
    
    static func present(from parent: UIViewController, onCreate: @escaping (TrackerCategory) -> Void) {
        let modalVC = TrackerAddViewController()
        modalVC.modalPresentationStyle = .pageSheet
        modalVC.onCreate = onCreate
        parent.present(modalVC, animated: true, completion: nil)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension TrackerAddViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
