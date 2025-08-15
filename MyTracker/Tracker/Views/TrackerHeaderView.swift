import UIKit

class TrackerHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "TrackerHeaderView"
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "SFPro-Bold", size: 19)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
