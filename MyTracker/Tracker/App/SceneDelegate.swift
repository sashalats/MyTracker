import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            // Если онбординг уже пройден — открываем главный интерфейс
            window.rootViewController = makeMainRoot()
        } else {
            // Если онбординг не пройден — показываем его
            let onboardingVC = OnboardingViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
            onboardingVC.onFinished = { [weak self] in
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                self?.window?.rootViewController = self?.makeMainRoot()
            }
            window.rootViewController = onboardingVC
        }
        
        window.makeKeyAndVisible()
        self.window = window
    }
    
    private func makeMainRoot() -> UIViewController {
        return MainTabBarController()
    }
}
