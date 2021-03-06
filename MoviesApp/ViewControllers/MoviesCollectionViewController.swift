//
//  MoviesCollectionViewController.swift
//  MoviesApp
//
//  Created by Александр on 10.12.21.
//

import UIKit

private let reuseIdentifier = "Cell"

class MoviesCollectionViewController: UICollectionViewController {
    
    private var movies: Movies?
    private var filteredFilm: [Film] = []
    
    private let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        return searchController
    }()
    
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    private var isFiltering: Bool {
        searchController.isActive && !searchBarIsEmpty
    }
    
    let itemsPerRow: CGFloat = 3
    let sectionInserts = UIEdgeInsets(top: 10, left: 10, bottom: 25, right: 10)
    
    private var activityIndicator: UIActivityIndicatorView?
    
    init() {
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator = showActivityIndicator(in: view)
        setupNavigationBar()
        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.backgroundColor = .black
        fetchMoviesInfo()
        setupSearchController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func showActivityIndicator(in view: UIView) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.startAnimating()
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        return activityIndicator
    }
    private func setupNavigationBar() {
        title = "Movies List"
        
        let navBarAppearance = UINavigationBarAppearance()
        
        navBarAppearance.backgroundColor = .black
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
    }
    
    // MARK: - Navigation
    private func openDetailMovie() {
        let detailMovieViewController = DetailMovieViewController()
        guard let indexPath = collectionView.indexPath(for: MovieCollectionViewCell()) else { return }
        let film = isFiltering ? filteredFilm[indexPath.item] : movies?.movies[indexPath.item]
        detailMovieViewController.film = film
        
        navigationController?.pushViewController(detailMovieViewController, animated: true)
    }
    
    private func setupSearchController() {
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.automaticallyShowsSearchResultsController = true
        searchController.searchBar.placeholder = "Search"
        definesPresentationContext = true
    }
    
    private func fetchMoviesInfo() {
        NetworkManager.shared.fetchMoviesInfo { [unowned self] result in
            switch result {
            case .success(let movie):
                DispatchQueue.main.async {
                    movies = movie
                    activityIndicator?.stopAnimating()
                    collectionView.reloadData()
                }
            case .failure(let error):
                print (error)
            }
        }
    }
}

// MARK: UICollectionViewDataSource
extension MoviesCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        isFiltering ? filteredFilm.count : movies?.movies.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MovieCollectionViewCell
        
        let movie = isFiltering ? filteredFilm[indexPath.item] : movies?.movies[indexPath.item]
        cell.configure(with: movie)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MoviesCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let detailMovieViewController = DetailMovieViewController()
        let film = isFiltering ? filteredFilm[indexPath.item] : movies?.movies[indexPath.item]
        detailMovieViewController.film = film
        
        navigationController?.pushViewController(detailMovieViewController, animated: true)
    }
}

extension MoviesCollectionViewController: UICollectionViewDelegateFlowLayout {
    // Устанавливаю размер ячеек
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let paddingWidth: CGFloat = sectionInserts.left * (itemsPerRow + 1)
        let availibleWidth = collectionView.frame.width - paddingWidth
        let widthPerItem = availibleWidth / itemsPerRow
        let heightPerItem = 1.8 * widthPerItem
        
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
    
    //  Устанавливаю отступы для секции от границы коллекции
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        sectionInserts
    }
    
    // Устанавливаю растояние по линия
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        sectionInserts.bottom
    }
    
    // устанавливаю растояние между элементами
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        sectionInserts.left
    }
}

extension MoviesCollectionViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text ?? "")
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        filteredFilm = movies?.movies.filter { film in
            (film.titleEn ?? film.title).lowercased().contains(searchText.lowercased())
        } ?? []
        
        collectionView.reloadData()
    }
}
