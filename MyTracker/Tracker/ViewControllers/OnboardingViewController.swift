import UIKit

struct PageModel {
    let image: UIImage?
    let text: String
}

extension PageModel {
    static let aboutTracking = PageModel(
        image: UIImage(named: "blueScreenImage"),
        text: "Отслеживайте только то, что хотите"
    )
    static let aboutWaterAndYoga = PageModel(
        image: UIImage(named: "redScreenImage"),
        text: "Даже если это не литры воды и йога"
    )
}

private final class OnboardingPageViewController: UIViewController {

    private let model: PageModel
    private let onStart: (() -> Void)?

    init(model: PageModel, onStart: (() -> Void)? = nil) {
        self.model = model
        self.onStart = onStart
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Background image
        let bgImage = UIImageView(image: model.image)
        bgImage.contentMode = .scaleAspectFill
        bgImage.translatesAutoresizingMaskIntoConstraints = false

        // Title label
        let titleLabel = UILabel()
        titleLabel.text = model.text
        titleLabel.font = UIFont(name: "SFPro-Bold", size: 32)
        titleLabel.textColor = .justBlack
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Primary button
        let primaryButton = UIButton(type: .system)
        primaryButton.setTitle("Вот это технологии!", for: .normal)
        primaryButton.backgroundColor = .justBlack
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.titleLabel?.font = UIFont(name: "SFPro-Medium", size: 16)
        primaryButton.layer.cornerRadius = 16
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)

        view.addSubview(bgImage)
        view.addSubview(titleLabel)
        view.addSubview(primaryButton)
        view.sendSubviewToBack(bgImage)

        NSLayoutConstraint.activate([
            bgImage.topAnchor.constraint(equalTo: view.topAnchor),
            bgImage.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bgImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: primaryButton.topAnchor, constant: -160),

            primaryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            primaryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            primaryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            primaryButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc private func didTapStart() {
        onStart?()
    }
}

final class OnboardingViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    var onFinished: (() -> Void)?
    lazy var pages: [UIViewController] = {
        let models: [PageModel] = [.aboutTracking, .aboutWaterAndYoga]
        return models.map { model in
            OnboardingPageViewController(model: model, onStart: { [weak self] in
                self?.didTapStart()
            })
        }
    }()
    
    override init(transitionStyle: UIPageViewController.TransitionStyle = .scroll,
                  navigationOrientation: UIPageViewController.NavigationOrientation = .horizontal,
                  options: [UIPageViewController.OptionsKey : Any]? = nil) {
        super.init(transitionStyle: transitionStyle,
                   navigationOrientation: navigationOrientation,
                   options: options)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не реализован")
    }
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = 0
        
        pageControl.currentPageIndicatorTintColor = .justBlack
        pageControl.pageIndicatorTintColor = .gray
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        dataSource = self
        delegate = self
        
        if let first = pages.first {
            setViewControllers([first], direction: .forward, animated: true, completion: nil)
        }
        
        view.addSubview(pageControl)
        
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -134),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        return pages[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = pages.firstIndex(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        
        guard nextIndex < pages.count else {
            return nil
        }
        
        return pages[nextIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if let currentViewController = pageViewController.viewControllers?.first,
           let currentIndex = pages.firstIndex(of: currentViewController) {
            pageControl.currentPage = currentIndex
        }
    }
    
    @objc private func didTapStart() {
        onFinished?()
    }
}
