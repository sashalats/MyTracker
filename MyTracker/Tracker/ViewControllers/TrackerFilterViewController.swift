import UIKit

private let kTrackerFilterSelectedIndexKey = "TrackerFilter.SelectedIndex"

final class TrackerFilterViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let filters = EnumTrackerFilter.allCases
    private var currentFilter: EnumTrackerFilter = .all
    
    var onFilterSelected: ((EnumTrackerFilter) -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.filters
        label.font = UIFont(name: "SFPro-Medium", size: 16)
        label.textColor = .blackDayNew
        label.textAlignment = .center
        return label
    }()
    
    init(currentFilter: EnumTrackerFilter) {
        self.currentFilter = currentFilter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .whiteDayNew
        setupUI()
        if let savedIndex = UserDefaults.standard.object(forKey: kTrackerFilterSelectedIndexKey) as? Int,
           savedIndex >= 0, savedIndex < filters.count {
            currentFilter = filters[savedIndex]
        } else {
            currentFilter = .today
            if let idx = filters.firstIndex(of: .today) {
                UserDefaults.standard.set(idx, forKey: kTrackerFilterSelectedIndexKey)
            }
        }
        tableView.reloadData()
    }
    
    private func setupUI() {
        [titleLabel, tableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(FilterCell.self, forCellReuseIdentifier: "FilterCell")
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 26),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reload to reflect any changes made while this screen was not visible
        tableView.reloadData()
    }
}

extension TrackerFilterViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filters.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FilterCell", for: indexPath) as? FilterCell else {
            return UITableViewCell()
        }
        let filter = filters[indexPath.row]
        let isFirst = indexPath.row == 0
        let isLast = indexPath.row == filters.count - 1
        // Per spec, "All" and "Today" are reset options and must not show a blue checkmark
        let isResetOption: Bool
        switch filter {
        case .all, .today: isResetOption = true
        default: isResetOption = false
        }
        let isChecked = (filter == currentFilter) && !isResetOption
        
        cell.configure(title: filter.title, isChecked: isChecked, isFirst: isFirst, isLast: isLast)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = filters[indexPath.row]
        // Persist selected filter by index (robust to enum rawValue changes)
        if let idx = filters.firstIndex(of: selected) {
            UserDefaults.standard.set(idx, forKey: kTrackerFilterSelectedIndexKey)
        }
        // Update current selection so the checkmark logic reflects immediately (if not dismissed)
        currentFilter = selected
        tableView.reloadData()
        onFilterSelected?(selected)
        dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}
