import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }

    private func setupTabs() {
        let homeVC = UINavigationController(rootViewController: HomeViewController())
        homeVC.tabBarItem = UITabBarItem(
            title: "首页",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let wardrobeVC = UINavigationController(rootViewController: WardrobeViewController())
        wardrobeVC.tabBarItem = UITabBarItem(
            title: "衣橱",
            image: UIImage(systemName: "square.grid.2x2"),
            selectedImage: UIImage(systemName: "square.grid.2x2.fill")
        )

        let outfitVC = UINavigationController(rootViewController: OutfitViewController())
        outfitVC.tabBarItem = UITabBarItem(
            title: "搭配",
            image: UIImage(systemName: "sparkles"),
            selectedImage: UIImage(systemName: "sparkles")
        )

        let tryOnVC = UINavigationController(rootViewController: TryOnViewController())
        tryOnVC.tabBarItem = UITabBarItem(
            title: "试穿",
            image: UIImage(systemName: "tshirt"),
            selectedImage: UIImage(systemName: "tshirt.fill")
        )

        let profileVC = UINavigationController(rootViewController: ProfileViewController())
        profileVC.tabBarItem = UITabBarItem(
            title: "我的",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )

        viewControllers = [homeVC, wardrobeVC, tryOnVC, profileVC]
    }

    private func setupAppearance() {
        tabBar.tintColor = WTWColor.primary
        tabBar.backgroundColor = WTWColor.secondary
        tabBar.unselectedItemTintColor = WTWColor.textPrimary

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = WTWColor.secondary
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}