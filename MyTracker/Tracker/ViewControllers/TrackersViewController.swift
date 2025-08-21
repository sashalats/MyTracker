import UIKit
import AppMetricaCore

class TrackersViewController: UIViewController {
    
    private var myTracker: [TrackerCategory] = []
    private var visibleSections: [TrackerCategory] = []
    private var showAllTrackers = false
    private var currentFilter: EnumTrackerFilter = .today
    private var searchQuery: String = ""
    
    private let kTrackerFilterSelectedIndexKey = "TrackerFilter.SelectedIndex"

    // MARK: - Analytics
    private func report(event: String, item: String? = nil, params: [String: Any] = [:]) {
        var payload: [String: Any] = [
            "event": event,
            "screen": "Main"
        ]
        if let item = item { payload["item"] = item }
        params.forEach { payload[$0.key] = $0.value }

        AppMetrica.reportEvent(name: "ui_event", parameters: payload) { error in
            print("[AppMetrica] report error: \(error.localizedDescription)")
        }
        print("[Analytics] \(payload)")
    }
    
    private lazy var trackerStore: TrackerStore = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Could not cast UIApplication delegate to AppDelegate")
        }
        return TrackerStore(context: appDelegate.persistentContainer.viewContext)
    }()

    private lazy var recordStore: TrackerRecordStore = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Could not cast UIApplication delegate to AppDelegate")
        }
        return TrackerRecordStore(context: appDelegate.persistentContainer.viewContext)
    }()

    private lazy var categoryStore: TrackerCategoryStore = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Could not cast UIApplication delegate to AppDelegate")
        }
        return TrackerCategoryStore(context: appDelegate.persistentContainer.viewContext)
    }()
    
    private var currentDate: Date = Date()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 9
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = spacing
        layout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 38)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.reuseIdentifier)
        cv.register(TrackerHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: TrackerHeaderView.reuseIdentifier)
        cv.dataSource = self
        cv.delegate = self
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.alwaysBounceVertical = true
        return cv
    }()
    
    private let dateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.blackDayNew, for: .normal)
        button.backgroundColor = .fieldBackground
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont(name: "SFPro-Regular", size: 17)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 5.5, bottom: 6, right: 5.5)
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.titleLabel?.lineHeight(22)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.trackers
        label.font = UIFont(name: "SFPro-Bold", size: 34)
        label.numberOfLines = 1
        label.lineHeight(40.8)
        label.textColor = .blackDayNew
        return label
    }()
    
    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "Add tracker")
        button.setImage(image, for: .normal)
        button.tintColor = .blackDayNew
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 42).isActive = true
        button.heightAnchor.constraint(equalToConstant: 42).isActive = true
        return button
    }()
    
    private let searchField: UITextField = {
        let textField = UITextField()
        textField.placeholder = L10n.search
        textField.backgroundColor = .fieldBackground
        textField.layer.cornerRadius = 10
        textField.setLeftPaddingPoints(0)
        
        let imageView = UIImageView(image: UIImage(named: "Mangnifyingglass"))
        let iconContainer = UIView(frame: CGRect(x: 0, y: 0, width: 31, height: 36))
        imageView.frame = CGRect(x: 8, y: 10, width: 16, height: 16)
        iconContainer.addSubview(imageView)
        textField.leftView = iconContainer
        textField.leftViewMode = .always
        textField.clearButtonMode = .whileEditing
        
        return textField
    }()
    
    private let emptyIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "Empty"))
        imageView.tintColor = .lightGray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.baseScreenPrompt
        label.font = UIFont(name: "SFPro-Medium", size: 12)
        label.textAlignment = .center
        label.textColor = .blackDayNew
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let calendarContainer: UIView = {
        let container = UIView()
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.1
        container.layer.shadowOffset = CGSize(width: 0, height: 10)
        container.layer.shadowRadius = 30
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isHidden = true
        container.backgroundColor = .whiteDayNew
        container.layer.cornerRadius = 13
        container.clipsToBounds = false
        return container
    }()
    
    private let calendarView: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.locale = .current
        picker.backgroundColor = .clear
        picker.clipsToBounds = true
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private let filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(L10n.filters, for: .normal)
        button.titleLabel?.font = UIFont(name: "SFPro-Regular", size: 17)
        button.backgroundColor = UIColor(hex: "#3772E7")
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.isHidden = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteDayNew
        // (Optional) Early hook before appear
        report(event: "open")
        setupLayout()
        dateButton.addTarget(self, action: #selector(openCalendar), for: .touchUpInside)
        calendarView.addTarget(self, action: #selector(calendarDateChanged), for: .valueChanged)
        plusButton.addTarget(self, action: #selector(openModal), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(openFilter), for: .touchUpInside)
        view.bringSubviewToFront(calendarContainer)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutsideCalendar(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        // Long-press on dateButton toggles "All days" mode
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(toggleAllDaysMode(_:)))
        dateButton.addGestureRecognizer(longPress)
        
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        
        enableHideKeyboardOnTap()
        updateEmptyState()
        dateButton.setTitle(Date().formattedString(), for: .normal)
        
        trackerStore.onChange = { [weak self] sections in
            guard let self = self else { return }
            self.myTracker = sections
            self.rebuildVisibleSections()
            self.collectionView.reloadData()
            self.updateEmptyState()
            self.updateFilterButtonVisibility()
        }
        trackerStore.startObserving()
        updateFilterButtonVisibility()

        // Restore saved filter (default to .today)
        if let savedIndex = UserDefaults.standard.object(forKey: kTrackerFilterSelectedIndexKey) as? Int,
           savedIndex >= 0, savedIndex < EnumTrackerFilter.allCases.count {
            currentFilter = EnumTrackerFilter.allCases[savedIndex]
        } else {
            currentFilter = .today
            if let idx = EnumTrackerFilter.allCases.firstIndex(of: .today) {
                UserDefaults.standard.set(idx, forKey: kTrackerFilterSelectedIndexKey)
            }
        }

        // If filter is .today — ensure today's date shown
        if currentFilter == .today {
            currentDate = Date()
            dateButton.setTitle(currentDate.formattedString(), for: .normal)
        }
        rebuildVisibleSections(); collectionView.reloadData(); updateEmptyState();
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        report(event: "open")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        report(event: "close")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        let spacing: CGFloat = 9
        let sideInset: CGFloat = 16
        let totalSpacing = spacing + sideInset * 2
        let itemWidth = (view.bounds.width - totalSpacing) / 2
        let itemHeight: CGFloat = 90 + 58
        
        if layout.itemSize.width != itemWidth || layout.itemSize.height != itemHeight || layout.headerReferenceSize.width != view.bounds.width {
            layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
            layout.headerReferenceSize = CGSize(width: view.bounds.width, height: 38)
            layout.invalidateLayout()
        }
        updateCollectionBottomInset()
    }

    private func rebuildVisibleSections() {
        var result: [TrackerCategory] = []
        let calendarWeekday = Calendar.current.component(.weekday, from: currentDate)
        let mapped = (calendarWeekday == 1) ? 7 : (calendarWeekday - 1)
        let neededDay = DayOfWeek(rawValue: mapped)

        for section in myTracker {
            var trackers = section.trackers

            if !showAllTrackers, let needDay = neededDay {
                trackers = trackers.filter { $0.schedule.contains(needDay) }
            }

            switch currentFilter {
            case .all:
                break
            case .today:
                // .today — действие (выбор сегодняшнего дня) и сброс фильтра
                break
            case .completed:
                trackers = trackers.filter { isCompleted($0, on: currentDate) }
            case .uncompleted:
                trackers = trackers.filter { !isCompleted($0, on: currentDate) }
            }

            if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                trackers = trackers.filter { $0.name.lowercased().contains(q) }
            }

            if !trackers.isEmpty {
                result.append(TrackerCategory(title: section.title, trackers: trackers))
            }
        }
        visibleSections = result
    }
    
    private func setupLayout() {
        [plusButton, titleLabel, dateButton, searchField, calendarContainer, collectionView, filterButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        view.addSubview(emptyIcon)
        view.addSubview(emptyLabel)
        
        calendarContainer.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            plusButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            plusButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            plusButton.widthAnchor.constraint(equalToConstant: 42),
            plusButton.heightAnchor.constraint(equalToConstant: 42),
            
            dateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dateButton.centerYAnchor.constraint(equalTo: plusButton.centerYAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: plusButton.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            collectionView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            searchField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 36),
            
            emptyIcon.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            emptyIcon.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -24),
            emptyIcon.widthAnchor.constraint(equalToConstant: 80),
            emptyIcon.heightAnchor.constraint(equalToConstant: 80),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 16),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            calendarContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            calendarContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            calendarContainer.topAnchor.constraint(equalTo: dateButton.bottomAnchor, constant: 53),
            calendarContainer.heightAnchor.constraint(equalTo: calendarContainer.widthAnchor, constant: -18),
            
            calendarView.topAnchor.constraint(equalTo: calendarContainer.topAnchor),
            calendarView.bottomAnchor.constraint(equalTo: calendarContainer.bottomAnchor),
            calendarView.leadingAnchor.constraint(equalTo: calendarContainer.leadingAnchor, constant: 16),
            calendarView.trailingAnchor.constraint(equalTo: calendarContainer.trailingAnchor, constant: -16)
        ])
        filterButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 114),
            filterButton.heightAnchor.constraint(equalToConstant: 50),
            filterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    @objc private func openCalendar() {
        calendarContainer.isHidden.toggle()
    }
    
    @objc private func calendarDateChanged(_ sender: UIDatePicker) {
        showAllTrackers = false
        currentDate = sender.date
        dateButton.setTitle(sender.date.formattedString(), for: .normal)
        calendarContainer.isHidden = true
        self.rebuildVisibleSections()
        collectionView.reloadData()
        updateEmptyState()
        updateFilterButtonVisibility()
    }
    
    @objc private func toggleAllDaysMode(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        showAllTrackers.toggle()
        if showAllTrackers {
            dateButton.setTitle(L10n.allTrackers, for: .normal)
            calendarContainer.isHidden = true
        } else {
            dateButton.setTitle(currentDate.formattedString(), for: .normal)
        }
        self.rebuildVisibleSections()
        collectionView.reloadData()
        updateEmptyState()
        updateFilterButtonVisibility()
    }
    
    private func isCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        return recordStore.isCompleted(trackerId: tracker.id, on: date)
    }

    @objc private func openFilter() {
        report(event: "click", item: "filter")
        let initial = currentFilter
        let vc = TrackerFilterViewController(currentFilter: initial)
        vc.modalPresentationStyle = .pageSheet
        vc.onFilterSelected = { [weak self] selected in
            guard let self = self else { return }
            switch selected {
            case .all:
                self.currentFilter = .all
            case .today:
                self.currentFilter = .today
                self.showAllTrackers = false
                self.currentDate = Date()
                self.dateButton.setTitle(self.currentDate.formattedString(), for: .normal)
            case .completed:
                self.currentFilter = .completed
            case .uncompleted:
                self.currentFilter = .uncompleted
            }
            if let idx = EnumTrackerFilter.allCases.firstIndex(of: selected) {
                UserDefaults.standard.set(idx, forKey: self.kTrackerFilterSelectedIndexKey)
            }
            self.rebuildVisibleSections()
            self.collectionView.reloadData()
            self.updateEmptyState()
            self.updateFilterButtonVisibility()
        }
        present(vc, animated: true)
    }

    private func hasAnyForSelectedDay() -> Bool {
        if showAllTrackers { return myTracker.contains { !$0.trackers.isEmpty } }
        let weekday = Calendar.current.component(.weekday, from: currentDate)
        let mapped = (weekday == 1) ? 7 : (weekday - 1)
        guard let needDay = DayOfWeek(rawValue: mapped) else { return false }
        return myTracker.contains { section in section.trackers.contains { $0.schedule.contains(needDay) } }
    }

    private func updateFilterButtonVisibility() {
        let canShow = hasAnyForSelectedDay()
        filterButton.isHidden = !canShow
        updateCollectionBottomInset()
    }

    private func updateCollectionBottomInset() {
        let bottomInset: CGFloat
        if filterButton.isHidden {
            bottomInset = 0
        } else {
            bottomInset = 50 + 16 + view.safeAreaInsets.bottom
        }
        if collectionView.contentInset.bottom != bottomInset {
            var inset = collectionView.contentInset
            inset.bottom = bottomInset
            collectionView.contentInset = inset
            collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }
    
    private func toggleCompletion(for tracker: Tracker) {
        report(event: "click", item: "track", params: ["tracker_id": tracker.id.uuidString, "date": currentDate.formattedString()])
        let day = currentDate
        guard day <= Date() else { return }
        if recordStore.isCompleted(trackerId: tracker.id, on: day) {
            recordStore.removeRecord(TrackerRecord(trackerId: tracker.id, date: day))
        } else {
            recordStore.addRecord(TrackerRecord(trackerId: tracker.id, date: day))
        }
        
        let newCount = recordStore.numberOfCompletions(trackerId: tracker.id)
        print("[TrackersVC] toggled tracker=\(tracker.id), completedToday=\(recordStore.isCompleted(trackerId: tracker.id, on: day)), totalCount=\(newCount))")
        
        collectionView.reloadData()
        updateEmptyState()
    }
    
    private func updateEmptyState() {
        let hasAny = !visibleSections.isEmpty && visibleSections.contains { !$0.trackers.isEmpty }
        emptyIcon.isHidden = hasAny
        emptyLabel.isHidden = hasAny
        collectionView.isHidden = !hasAny

        if !hasAny {
            if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
               currentFilter == .completed || currentFilter == .uncompleted {
                emptyLabel.text = L10n.nothingFound
            } else {
                emptyLabel.text = L10n.baseScreenPrompt
            }
        }
    }
    
    private func presentEdit(for tracker: Tracker) {
        // Вью‑модель категорий
        let categoryVM = TrackerCategoryViewModel(categoryStore: categoryStore)
        // Вью‑модель трекеров (иниц под свой проект — при необходимости поправь сигнатуру)
        let trackersVM = TrackerViewModel(
            trackerStore: trackerStore,
            categoryStore: categoryStore,
            recordStore: recordStore
        )

        let editVC = EditTrackerViewController()
        editVC.viewModel = trackersVM
        editVC.categoryViewModel = categoryVM
        editVC.editingTracker = tracker

        let nav = UINavigationController(rootViewController: editVC)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }
    
    @objc private func openModal() {
        report(event: "click", item: "add_track")
        TrackerAddViewController.present(from: self) { [weak self] _ in
            self?.updateEmptyState()
        }
    }
    
    @objc private func handleTapOutsideCalendar(_ gesture: UITapGestureRecognizer) {
        if !calendarContainer.isHidden {
            let location = gesture.location(in: view)
            if !calendarContainer.frame.contains(location) {
                calendarContainer.isHidden = true
            }
        }
    }

    // MARK: - Search
    @objc private func searchChanged() {
        searchQuery = (searchField.text ?? "")
        rebuildVisibleSections()
        collectionView.reloadData()
        updateEmptyState()
        updateFilterButtonVisibility()
    }
}

extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        visibleSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return visibleSections[section].trackers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.reuseIdentifier, for: indexPath) as? TrackerCell else {
            return UICollectionViewCell()
        }
        let trackers = visibleSections[indexPath.section].trackers
        let tracker = trackers[indexPath.item]
        
        let count = recordStore.numberOfCompletions(trackerId: tracker.id)
        let done = isCompleted(tracker, on: currentDate)
        
        cell.configure(with: tracker, completed: done, count: count) { [weak self] in
            self?.toggleCompletion(for: tracker)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: TrackerHeaderView.reuseIdentifier, for: indexPath) as? TrackerHeaderView else {
            return UICollectionReusableView()
        }
        header.titleLabel.text = visibleSections[indexPath.section].title
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        let trackers = visibleSections[indexPath.section].trackers
        guard indexPath.item < trackers.count else { return nil }
        let tracker = trackers[indexPath.item]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return UIMenu() }
            let editAction = UIAction(title: L10n.edit,
                                      image: UIImage(systemName: "pencil")) { [weak self] _ in
                guard let self = self else { return }
                self.report(event: "click", item: "edit", params: ["tracker_id": tracker.id.uuidString])
                self.presentEdit(for: tracker)
            }
            let deleteAction = UIAction(title: L10n.delete,
                                        image: UIImage(systemName: "trash"),
                                        attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.report(event: "click", item: "delete", params: ["tracker_id": tracker.id.uuidString])
                self.trackerStore.deleteTracker(for: tracker.id)
            }
            return UIMenu(title: "", children: [editAction, deleteAction])
        }
    }
}
extension TrackersViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        searchQuery = ""
        rebuildVisibleSections()
        collectionView.reloadData()
        updateEmptyState()
        updateFilterButtonVisibility()
        return true
    }
}
