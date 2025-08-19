import UIKit
import Foundation

final class ScheduleViewController: UIViewController {
    
    var onScheduleSelected: (([DayOfWeek]) -> Void)?
    var preselectedDays: Set<DayOfWeek> = []
    private var selectedDays: Set<DayOfWeek> = []
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Расписание"
        label.font = UIFont(name: "SFPro-Medium", size: 16)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let selectionContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let dayList: [NewDayRow] = [
        NewDayRow(title: "Понедельник"),
        NewDayRow(title: "Вторник"),
        NewDayRow(title: "Среда"),
        NewDayRow(title: "Четверг"),
        NewDayRow(title: "Пятница"),
        NewDayRow(title: "Суббота"),
        NewDayRow(title: "Воскресенье")
    ]
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.setTitleColor(.whiteDayNew, for: .normal)
        button.titleLabel?.font = UIFont(name: "SFPro-Medium", size: 16)
        button.backgroundColor = .blackDayNew
        button.layer.cornerRadius = 16
        button.titleLabel?.lineHeight(22)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        selectedDays = preselectedDays
        setupLayout()
        titleLabel.lineHeight(22)
        doneButton.addTarget(self, action: #selector(closeSheet), for: .touchUpInside)
    }
    
    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            selectionContainer
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        var selectionItems: [UIView] = []
        for (index, row) in dayList.enumerated() {
            let day = DayOfWeek(rawValue: index + 1)!
            
            row.setSwitchOn(preselectedDays.contains(day))
            
            row.onToggle = { [weak self] isOn in
                guard let self = self else { return }
                if isOn {
                    self.selectedDays.insert(day)
                } else {
                    self.selectedDays.remove(day)
                }
                print("[ScheduleVC] toggled \(day) → \(self.selectedDays)")
            }
            
            selectionItems.append(row)
            
            if index < dayList.count - 1 {
                let separator = UIView()
                separator.backgroundColor = UIColor(red: 0.75, green: 0.76, blue: 0.77, alpha: 1)
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                selectionItems.append(separator)
            }
        }
        
        let selectionStack = UIStackView(arrangedSubviews: selectionItems)
        selectionStack.axis = .vertical
        selectionStack.spacing = 0
        selectionStack.translatesAutoresizingMaskIntoConstraints = false
        
        selectionContainer.addSubview(selectionStack)
        
        view.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectionStack.topAnchor.constraint(equalTo: selectionContainer.topAnchor),
            selectionStack.leadingAnchor.constraint(equalTo: selectionContainer.leadingAnchor, constant: 16),
            selectionStack.trailingAnchor.constraint(equalTo: selectionContainer.trailingAnchor, constant: -16),
            selectionStack.bottomAnchor.constraint(equalTo: selectionContainer.bottomAnchor),
            
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 13),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }
    
    @objc private func closeSheet() {
        let result = Array(selectedDays).sorted { $0.rawValue < $1.rawValue }
        print("[ScheduleVC] will send days:", result)
        onScheduleSelected?(result)
        dismiss(animated: true, completion: nil)
    }
    
    static func present(from parent: UIViewController,
                        preselected: Set<DayOfWeek> = [],
                        onSelected: (([DayOfWeek]) -> Void)? = nil) {
        let modalVC = ScheduleViewController()
        modalVC.modalPresentationStyle = .pageSheet
        modalVC.preselectedDays = preselected
        modalVC.onScheduleSelected = onSelected
        parent.present(modalVC, animated: true, completion: nil)
    }
}
