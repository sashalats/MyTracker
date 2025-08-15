import UIKit

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let topBorder = CALayer()
        topBorder.frame = CGRect(x: 0, y: 0, width: tabBar.frame.width, height: 0.5)
        topBorder.backgroundColor = UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor // AEAFB4
        tabBar.layer.addSublayer(topBorder)
        tabBar.layer.masksToBounds = true
        
        let trackersVC = TrackersViewController()
        let trackersNav = UINavigationController(rootViewController: trackersVC)
        
        trackersNav.setNavigationBarHidden(true, animated: false)
        trackersNav.navigationBar.isTranslucent = true
        trackersNav.tabBarItem = UITabBarItem(title: "Трекеры", image: UIImage(named: "TapBar_Tracker"), tag: 0)
        
        let statsVC = UIViewController()
        statsVC.view.backgroundColor = .white
        statsVC.tabBarItem = UITabBarItem(title: "Статистика", image: UIImage(named: "TapBar_Stats"), tag: 1)
        
        viewControllers = [trackersNav, statsVC]
        selectedIndex = 0
    }
}
