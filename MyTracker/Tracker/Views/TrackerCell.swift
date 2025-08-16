import UIKit

final class TrackerCell: UICollectionViewCell {
    
    static let reuseIdentifier = "TrackerCell"
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFPro-Medium", size: 14)
        label.textAlignment = .center
        label.lineHeight(22)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    private let emojiBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
        view.layer.cornerRadius = 12
        view.clipsToBounds = false
        return view
    }()
    
    private let trackerCardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 0.3).cgColor // AEAFB4 @ 30%
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFPro-Medium", size: 12)
        label.textColor = .white
        label.numberOfLines = 2
        return label
    }()
    
    private let footerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let counterLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFPro-Medium", size: 12)
        label.lineHeight(18)
        label.textColor = .black
        label.textAlignment = .left
        return label
    }()
    
    private let markButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.layer.cornerRadius = 17
        button.widthAnchor.constraint(equalToConstant: 34).isActive = true
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        return button
    }()
    
    private var isCompleted: Bool = false
    private var completionAction: (() -> Void)?
    private var trackerId: UUID?
    private var currentCount: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        markButton.addTarget(self, action: #selector(markTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with tracker: Tracker, completed: Bool, count: Int, onToggle: @escaping () -> Void) {
        isCompleted = completed
        completionAction = onToggle
        self.trackerId = tracker.id
        self.currentCount = count
        print(tracker)
        emojiLabel.text = tracker.emoji
        nameLabel.text = tracker.name
        nameLabel.lineHeight(18)
        counterLabel.text = "\(count) дней"
        counterLabel.lineHeight(18)
        
        trackerCardView.backgroundColor = tracker.color
        
        let iconName = completed ?  "Done" : "Approove"
        markButton.setImage(UIImage(named: iconName), for: .normal)
        markButton.backgroundColor = tracker.color
        markButton.alpha = completed ? 0.3 : 1.0
    }
    
    @objc private func markTapped() {
        print("Mark button tapped")
        guard let trackerId = trackerId else { return }
        
        isCompleted.toggle()
        
        currentCount = max(0, isCompleted ? currentCount + 1 : currentCount - 1)
        counterLabel.text = "\(currentCount) дней"
        counterLabel.lineHeight(18)
        
        let iconName = isCompleted ? "Done" : "Approove"
        markButton.setImage(UIImage(named: iconName), for: .normal)
        markButton.alpha = isCompleted ? 0.3 : 1.0
        
        completionAction?()
    }
    
    private func setupLayout() {
        contentView.addSubview(trackerCardView)
        contentView.addSubview(footerView)
        
        [emojiBackgroundView, nameLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            trackerCardView.addSubview($0)
        }
        
        footerView.addSubview(counterLabel)
        footerView.addSubview(markButton)
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        markButton.translatesAutoresizingMaskIntoConstraints = false
        
        emojiBackgroundView.addSubview(emojiLabel)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([

            trackerCardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            trackerCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            trackerCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            trackerCardView.heightAnchor.constraint(equalToConstant: 90),
            
            emojiBackgroundView.topAnchor.constraint(equalTo: trackerCardView.topAnchor, constant: 12),
            emojiBackgroundView.leadingAnchor.constraint(equalTo: trackerCardView.leadingAnchor, constant: 12),
            emojiBackgroundView.widthAnchor.constraint(equalToConstant: 24),
            emojiBackgroundView.heightAnchor.constraint(equalToConstant: 24),
            
            emojiLabel.centerXAnchor.constraint(equalTo: emojiBackgroundView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBackgroundView.centerYAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: emojiBackgroundView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: trackerCardView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: trackerCardView.trailingAnchor, constant: -12),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: trackerCardView.bottomAnchor, constant: -8),
            
            footerView.topAnchor.constraint(equalTo: trackerCardView.bottomAnchor, constant: 0),
            footerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 58),
            footerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0),
            
            counterLabel.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 16),
            counterLabel.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -16),
            counterLabel.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 12),
            
            markButton.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 8),
            markButton.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -12),
            markButton.widthAnchor.constraint(equalToConstant: 34),
            markButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
}
