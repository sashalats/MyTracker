import UIKit

class TrackersViewController: UIViewController {
    
    private var myTracker: [TrackerCategory] = []
    
    private lazy var trackerStore: TrackerStore = {
        let app = UIApplication.shared.delegate as! AppDelegate
        return TrackerStore(context: app.persistentContainer.viewContext)
    }()
    private lazy var recordStore: TrackerRecordStore = {
        let app = UIApplication.shared.delegate as! AppDelegate
        return TrackerRecordStore(context: app.persistentContainer.viewContext)
    }()
    private lazy var categoryStore: TrackerCategoryStore = {
        let app = UIApplication.shared.delegate as! AppDelegate
        return TrackerCategoryStore(context: app.persistentContainer.viewContext)
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
        return cv
    }()
    
    private let dateButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont(name: "SFPro-Regular", size: 17)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 5.5, bottom: 6, right: 5.5)
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.addTarget(nil, action: #selector(openCalendar), for: .touchUpInside)
        button.titleLabel?.lineHeight(22)
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Трекеры"
        label.font = UIFont(name: "SFPro-Bold", size: 34)
        label.numberOfLines = 1
        label.lineHeight(40.8)
        return label
    }()
    
    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(named: "Add tracker")
        button.setImage(image, for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 42).isActive = true
        button.heightAnchor.constraint(equalToConstant: 42).isActive = true
        return button
    }()
    
    private let searchField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Поиск"
        textField.backgroundColor = UIColor(hex: "#efeff0")
        textField.layer.cornerRadius = 10
        textField.setLeftPaddingPoints(0)
        
        let imageView = UIImageView(image: UIImage(named: "Mangnifyingglass"))
        let iconContainer = UIView(frame: CGRect(x: 0, y: 0, width: 31, height: 36))
        imageView.frame = CGRect(x: 8, y: 10, width: 16, height: 16)
        iconContainer.addSubview(imageView)
        textField.leftView = iconContainer
        textField.leftViewMode = .always
        
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
        label.text = "Что будем отслеживать?"
        label.font = UIFont(name: "SFPro-Medium", size: 12)
        label.textAlignment = .center
        label.textColor = .black
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
        container.backgroundColor = .white
        container.layer.cornerRadius = 13
        container.clipsToBounds = false
        return container
    }()
    
    private let calendarView: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.locale = .init(identifier: "ru_RU")
        picker.backgroundColor = .clear
        picker.clipsToBounds = true
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private let filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Фильтр", for: .normal)
        button.titleLabel?.font = UIFont(name: "SFPro-Regular", size: 17)
        button.backgroundColor = .blue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.layer.masksToBounds = true
        button.isHidden = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        calendarView.addTarget(self, action: #selector(calendarDateChanged), for: .valueChanged)
        plusButton.addTarget(self, action: #selector(openModal), for: .touchUpInside)
        view.bringSubviewToFront(calendarContainer)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutsideCalendar(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        updateEmptyState()
        dateButton.setTitle(DateFormater.formatDate(Date()), for: .normal)
        loadTrackersFromDB()
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
    }
    
    private func trackersForCurrentDate(in section: Int) -> [Tracker] {
        guard section >= 0 && section < myTracker.count else { return [] }
        
        let calendarWeekday = Calendar.current.component(.weekday, from: currentDate)
        let mapped = (calendarWeekday == 1) ? 7 : (calendarWeekday - 1)
        guard let needDay = DayOfWeek(rawValue: mapped) else { return [] }
        return myTracker[section].trackers.filter { $0.schedule.contains(needDay) }
    }
    
    private func setupLayout() {
        [plusButton, titleLabel, dateButton, searchField, calendarContainer, collectionView].forEach {
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
    }
    
    @objc private func openCalendar() {
        calendarContainer.isHidden.toggle()
    }
    
    @objc private func calendarDateChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
        dateButton.setTitle(DateFormater.formatDate(sender.date), for: .normal)
        calendarContainer.isHidden = true
        collectionView.reloadData()
        updateEmptyState()
    }
    
    private func isCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        return recordStore.isCompleted(trackerId: tracker.id, on: date)
    }
    
    private func toggleCompletion(for tracker: Tracker) {
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
        let hasAny = myTracker.indices.contains { section in
            !trackersForCurrentDate(in: section).isEmpty
        }
        emptyIcon.isHidden = hasAny
        emptyLabel.isHidden = hasAny
        collectionView.isHidden = !hasAny
    }
    
    private func loadTrackersFromDB() {
        myTracker = trackerStore.fetchTrackersGroupedByCategory()
        collectionView.reloadData()
        updateEmptyState()
    }
    
    @objc private func openModal() {
        TrackerAddViewController.present(from: self) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.loadTrackersFromDB()
            }
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
}

extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        myTracker.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return trackersForCurrentDate(in: section).count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.reuseIdentifier, for: indexPath) as? TrackerCell else {
            return UICollectionViewCell()
        }
        let trackers = trackersForCurrentDate(in: indexPath.section)
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
        header.titleLabel.text = myTracker[indexPath.section].title
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 38)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        let trackers = trackersForCurrentDate(in: indexPath.section)
        guard indexPath.item < trackers.count else { return nil }
        let tracker = trackers[indexPath.item]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return UIMenu() }
            let deleteAction = UIAction(title: "Удалить",
                                        image: UIImage(systemName: "trash"),
                                        attributes: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.trackerStore.deleteTracker(for: tracker.id)
                self.loadTrackersFromDB()
            }
            return UIMenu(title: "", children: [deleteAction])
        }
    }
}
