
import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAppearance()
        setupTabs()
        selectedIndex = 0
    }

    private func configureAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1) // AEAFB4

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .blueApp
        tabBar.unselectedItemTintColor = UIColor(white: 0.45, alpha: 1)
    }

    private func setupTabs() {
        // Трекеры
        let trackersVC = TrackersViewController()
        let trackersNav = UINavigationController(rootViewController: trackersVC)
        trackersNav.setNavigationBarHidden(true, animated: false)

        trackersNav.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Трекеры", comment: "Trackers tab"),
            image: UIImage(named: "TapBar_Tracker"),
            selectedImage: UIImage(named: "TapBar_Tracker_Selected")
        )

        // Статистика
        let statsVC = StatisticViewController()
        let statsNav = UINavigationController(rootViewController: statsVC)
        statsNav.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Статистика", comment: "Statistics tab"),
            image: UIImage(named: "TapBar_Stats"),
            selectedImage: UIImage(named: "TapBar_Stats_Selected")
        )

        viewControllers = [trackersNav, statsNav]
    }
}
