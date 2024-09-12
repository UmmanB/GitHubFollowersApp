//
//  GFTabBarController.swift
//  GitHubFollowersApp
//
//  Created by Umman on 12.09.24.
//

import UIKit

class GFTabBarController: UITabBarController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().tintColor = .systemGreen
        viewControllers = [createSearchNC(), createFavoritesNC()]
    }
    
    func createSearchNC() -> UINavigationController
    {
        let searchVC = SearchVC()
        searchVC.title = "Search"
        searchVC.tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 0)
        return UINavigationController(rootViewController: searchVC)
    }
    
    func createFavoritesNC() -> UINavigationController
    {
        let favoritesListVC = FavoritesListVC()
        favoritesListVC.title = "Favorites"
        favoritesListVC.tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 1)
        return UINavigationController(rootViewController: favoritesListVC)
    }
}
