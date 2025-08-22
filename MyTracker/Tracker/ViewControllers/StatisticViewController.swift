import UIKit

final class StatisticViewController: UIViewController {

    // MARK: - Deps
    private let trackerStore: TrackerStore
    private let recordStore: TrackerRecordStore

    // MARK: - State
    private var viewModel: StatisticViewModel? {
        didSet { updateUI() }
    }

    // MARK: - UI
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        l.text = L10n.statistic
        l.numberOfLines = 1
        return l
    }()

    private let emptyIcon: UIImageView = {
        let image = UIImage(named: "placeholderStatistic")
        let view = UIImageView(image: image)
        return view
    }()
    
    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.numberOfLines = 0
        l.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        l.textColor = .secondaryLabel
        l.text = L10n.nothingToAnalyze
        return l
    }()

    private lazy var completedCard = StatisticCardView(number: 0, description: L10n.trackersCompleted)
    private lazy var averageCard   = StatisticCardView(number: 0, description: L10n.averageValue)
    private lazy var idealCard     = StatisticCardView(number: 0, description: L10n.idealDays)
    private lazy var bestCard      = StatisticCardView(number: 0, description: L10n.bestPeriod)

    private let stack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 12
        return s
    }()

    // MARK: - Init
    init(trackerStore: TrackerStore, recordStore: TrackerRecordStore) {
        self.trackerStore = trackerStore
        self.recordStore = recordStore
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteDayNew
        setupLayout()
        rebuildViewModel()

        trackerStore.onChange = { [weak self] _ in
            self?.rebuildViewModel()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recordsChanged),
            name: .trackerRecordsDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Build VM
    private func rebuildViewModel() {
        // Актуальные трекеры из Store
        let grouped = trackerStore.fetchTrackersGroupedByCategory()
        let trackers = grouped.flatMap { $0.trackers }

        // Все записи (completions)
        let records = recordStore.fetchAllRecords()

        viewModel = StatisticViewModel(trackers: trackers, records: records)
    }

    @objc private func recordsChanged() {
        rebuildViewModel()
    }

    // MARK: - UI
    private func setupLayout() {
        [titleLabel, stack, emptyIcon, emptyLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        [completedCard, averageCard, idealCard, bestCard].forEach { stack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),

            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            emptyIcon.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            emptyIcon.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -24),
            emptyIcon.widthAnchor.constraint(equalToConstant: 80),
            emptyIcon.heightAnchor.constraint(equalToConstant: 80),
            
            emptyLabel.topAnchor.constraint(equalTo: emptyIcon.bottomAnchor, constant: 16),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
        ])
    }

    private func updateUI() {
        guard let vm = viewModel else { return }

        let hasStats = vm.hasStatistics
        emptyIcon.isHidden = hasStats
        emptyLabel.isHidden = hasStats
        stack.isHidden = !hasStats

        completedCard.configure(number: vm.completedTrackers)
        averageCard.configure(number: vm.averageValue)
        idealCard.configure(number: vm.idealDays)
        bestCard.configure(number: vm.bestPeriod)
    }
}
