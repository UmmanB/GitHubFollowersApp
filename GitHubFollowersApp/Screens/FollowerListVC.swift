//
//  FollowerListVC.swift
//  GitHubFollowersApp
//
//  Created by Umman on 03.09.24.
//

import UIKit

class FollowerListVC: GFDataLoadingVC
{
    enum Section { case main }
    
    var username: String!
    var followers: [Follower] = []
    var filteredFollowers: [Follower] = []
    var page = 1
    var hasMoreFollowers = true
    var isSearching = false
    var isLoadingMoreFollowers = false
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, Follower>!
    
    init(username: String)
    {
        super.init(nibName: nil, bundle: nil)
        self.username = username
        title = username
    }
    
    required init?(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        configureCollectionView()
        configureViewController()
        getFollowers(username: username, page: page)
        configureDataSource()
        configureSearchController()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState)
    {
        if followers.isEmpty
        {
            var config = UIContentUnavailableConfiguration.empty()
            config.image = .init(systemName: "person.slash")
            config.text = "No Followers"
            config.secondaryText = "This user has no followers"
            contentUnavailableConfiguration = config
        }
        
        else if isSearching && filteredFollowers.isEmpty
        {
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.search()
        }
        
        else
        {
            contentUnavailableConfiguration = nil
        }
    }
    
    func configureViewController()
    {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton
    }
    
    func configureCollectionView()
    {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UIHelper.createThreeColumnFlowLayout(in: view))
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(FollowerCell.self, forCellWithReuseIdentifier: FollowerCell.reuseID)
    }
    
    func configureSearchController()
    {
        let searchController = UISearchController()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search for a username"
        navigationItem.searchController = searchController
    }
    
    func getFollowers(username: String, page: Int)
    {
        showLoadingView()
        isLoadingMoreFollowers = true
        
        Task
        {
            do
            {
                let followers = try await NetworkManager.shared.getFollowers(for: username, page: page)
                updateUI(with: followers)
                dismissLoadingView()
                isLoadingMoreFollowers = false
            }
            
            catch
            {
                if let gfError = error as? GFError
                {
                    presentGFAlert(title: "Bad Stuff Happened", message: gfError.rawValue, buttonTitle: "OK")
                }
                else { presentDefaultError() }
                
                isLoadingMoreFollowers = false
                dismissLoadingView()
            }
        }
    }
    
    func updateUI(with followers: [Follower])
    {
        if followers.count < 99 { self.hasMoreFollowers = false }
        self.followers.append(contentsOf: followers)
        self.updateData(on: self.followers)
        setNeedsUpdateContentUnavailableConfiguration()
    }
    
    func configureDataSource()
    {
        dataSource = UICollectionViewDiffableDataSource<Section, Follower>(collectionView: collectionView, cellProvider: { collectionView, indexPath, follower in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FollowerCell.reuseID, for: indexPath) as! FollowerCell
            cell.set(follower: follower)
            return cell
        })
    }
    
    func updateData(on followers: [Follower])
    {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Follower>()
        snapshot.appendSections([.main])
        snapshot.appendItems(followers)
        DispatchQueue.main.async{ self.dataSource.apply(snapshot, animatingDifferences: true) }
    }
    
    @objc func addButtonTapped()
    {
        showLoadingView()
        
        Task
        {
            do
            {
                let user = try await NetworkManager.shared.getUserInfo(for: username)
                addUserToFavorites(user: user)
                dismissLoadingView()
            }
            
            catch
            {
                if let gfError = error as? GFError
                {
                    presentGFAlert(title: "Something Went Wrong", message: gfError.rawValue, buttonTitle: "OK")
                }
                
                else {  presentDefaultError() }
            
                dismissLoadingView()
            }
        }
    }
    
    func addUserToFavorites(user: User)
    {
        let favorite = Follower(login: user.login, avatarUrl: user.avatarUrl)
        
        PersistenceManager.updateWith(favorite: favorite, actionType: .add) { [weak self] error in
            guard let self else { return }
            
            guard let error else
            {
                DispatchQueue.main.async
                {
                    self.presentGFAlert(title: "Success", message: "You have successfully favorited this user.", buttonTitle: "OK")
                }
                return
            }
            
            DispatchQueue.main.async
            {
                self.presentGFAlert(title: "Something went wrong", message: error.rawValue, buttonTitle: "OK")
            }
        }
    }
}

extension FollowerListVC: UICollectionViewDelegate
{
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        let offSetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offSetY > contentHeight - height
        {
            guard hasMoreFollowers, !isLoadingMoreFollowers else { return }
            page += 1
            getFollowers(username: username, page: page)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let activeArray = isSearching ? filteredFollowers : followers
        let follower = activeArray[indexPath.item]
        
        let destinationVC = UserInfoVC()
        destinationVC.username = follower.login
        destinationVC.delegate = self
        let navController = UINavigationController(rootViewController: destinationVC)
        present(navController, animated: true)
    }
}

extension FollowerListVC: UISearchResultsUpdating
{
    func updateSearchResults(for searchController: UISearchController)
    {
        guard let filter = searchController.searchBar.text, !filter.isEmpty else
        {
            filteredFollowers.removeAll()
            updateData(on: followers)
            isSearching = false
            setNeedsUpdateContentUnavailableConfiguration()
            return
        }
        
        isSearching = true
        filteredFollowers = followers.filter { $0.login.lowercased().contains(filter.lowercased()) }
        updateData(on: filteredFollowers)
        setNeedsUpdateContentUnavailableConfiguration()
    }
}

extension FollowerListVC: UISearchBarDelegate
{
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        isSearching = false
        filteredFollowers.removeAll()
        updateData(on: followers)
        setNeedsUpdateContentUnavailableConfiguration()
    }
}

extension FollowerListVC: UserInfoVCDelegate
{
    func didRequestFollowers(for username: String)
    {
        self.username = username
        title = username
        page = 1
        followers.removeAll()
        filteredFollowers.removeAll()
        navigationItem.searchController?.searchBar.text = ""
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .top, animated: true)
        getFollowers(username: username, page: page)
    }
}

