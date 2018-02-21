//
//  HomeCollectionViewController.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 09.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import UIKit

class AlbumsCollectionViewController: UICollectionViewController, UISearchBarDelegate {

    private let reuseIdentifier = "Cell"
    private let albumModel = AlbumModel()
    private let searchCollectionReusableView = SearchCollectionReusableView()
    private var searchText: String!

    private var error: Error? {
        didSet {
            if error != nil {
                DispatchQueue.main.async {
                    self.setupFor(status: .error)
                }
            }
        }
    }
    
    private var albumItunesData: AlbumItunesData? {
        didSet {
            albumsCount = albumItunesData?.resultCount
            albums = albumItunesData?.results
        }
    }
    
    private var albums: [AlbumItunesData.Album]? {
        didSet {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }

    private var albumsCount: Int! {
        willSet {
            if newValue == 0 {
                DispatchQueue.main.async {
                    self.setupFor(status: .noResult)
                }
            }
        }
    }
    
    @IBOutlet weak var noDataLabel: UILabel!
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var noDataImage: UIImageView!

    @IBAction func refreshButton(_ sender: UIButton) {
        albumSearch(for: searchText)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()

        setupFor(status: .startSearch)
        reloadButton.makeRounded()
        reloadButton.layer.borderWidth = 1
        reloadButton.layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    // MARK: - Take data from model
    
    /// Search albums by term
    ///
    /// - parameter name: searching term.
    private func albumSearch(for name: String) {
        setupFor(status: .haveResult)
        albumModel.getAlbums(for: name, completion: { [weak self] (data: AlbumItunesData?, error: Error?) in
            self?.useAlbumData(request: (data: data, error: error))
        })
    }

    private func useAlbumData(request: (data: AlbumItunesData?, error: Error?)) {
        albumItunesData = request.data
        error = request.error
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DetailsViewSegue" {
            let detailsVC = segue.destination as! DetailsViewController
            let cell = sender as! AlbumCollectionViewCell
            let indexPaths = self.collectionView?.indexPath(for: cell)

            if let thisAlbum = albums?[indexPaths!.row] {
                    detailsVC.currentAlbum = thisAlbum
            }
        }
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albumsCount ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! AlbumCollectionViewCell
        if let albumArtworkURL = albums?[indexPath.row].artworkUrl100 {
            cell.albumImageView.downloadedFrom(url: albumArtworkURL)
        } else {
            cell.albumImageView.image = #imageLiteral(resourceName: "noArtwork")
        }

        cell.albumNameLabel.text = albums?[indexPath.row].collectionName
        cell.albumAuthorLabel.text = albums?[indexPath.row].artistName
        cell.albumImageView.layer.cornerRadius = 10
        cell.albumImageView.layer.masksToBounds = true

        return cell
    }

    // MARK: - SearchBar
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if (kind == UICollectionElementKindSectionHeader) {
            let headerView: UICollectionReusableView =  collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "CollectionViewHeader", for: indexPath)
            return headerView
        }
        return UICollectionReusableView()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if (!(searchBar.text?.isEmpty)!) {
            albumSearch(for: searchBar.text!)
            searchText = searchBar.text!
            searchBar.endEditing(true)
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" && albums == nil {
            setupFor(status: .startSearch)
        } else {
            setupFor(status: .haveResult)
        }
    }

    // MARK: - NoDataStackView

    /// noDataStackView status.
    private enum ScreenStatus {
        case startSearch
        case noResult
        case error
        case haveResult
    }
    
    /// Hide noData Stuff
    ///
    /// - parameter isHidden: Hide or no
    private func noDataStuffIsHidden(_ isHidden: Bool) {
        noDataImage.isHidden = isHidden
        noDataLabel.isHidden = isHidden
        reloadButton.isHidden = isHidden
    }

    /// Setup noDataStackView for status.
    ///
    /// - parameter status: status for noDataStackView.
    private func setupFor(status: ScreenStatus) {
        switch status {
        case .haveResult:
            noDataStuffIsHidden(true)
        case .startSearch:
            noDataStuffIsHidden(false)
            reloadButton.isHidden = true
            noDataLabel.text = "Start your search"
        case .noResult:
            noDataStuffIsHidden(false)
            reloadButton.isHidden = true
            noDataLabel.text = "No results"
        case .error:
            noDataStuffIsHidden(false)
            reloadButton.isHidden = false
            noDataLabel.text = error!.localizedDescription
        }
    }
    
    // MARK: - Keyboard
    
    private func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
}

extension UIImageView {
    
    /// Download image by URL.
    ///
    /// - parameter url: image url.
    /// - parameter mode : Mode of image.
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
    
    /// Download image by link.
    ///
    /// - parameter link: image url as String.
    /// - parameter mode : Mode of image.
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}

extension UIView {

    /// Make view corners rounded.
    func makeRounded() {
        self.layer.cornerRadius = 8.0
        self.clipsToBounds = true
    }
}

extension Date {

    /// Formatte date.
    ///
    /// - parameter string: date for formatte.
    /// - returns: formatted date.
    static func getFormattedDate(from string: String) -> String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        if let date = dateFormatterGet.date(from: string) {
            return dateFormatter.string(from: date)
        } else {
            return "Error"
        }
    }
}
