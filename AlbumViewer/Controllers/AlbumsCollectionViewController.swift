//
//  AlbumsCollectionViewController.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 09.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import UIKit

class AlbumsCollectionViewController: UICollectionViewController, UISearchBarDelegate {

    private var albumItunesData: AlbumItunesData?

    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()

        noDataView.center = (collectionView?.center)!
        noDataView.reloadButton.addTarget(self, action: #selector(refreshButton(_:)), for: .touchUpInside)
        setupFor(status: .startSearch)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DetailsViewSegue" {
            let detailsVC = segue.destination as? DetailsViewController
            let cell = sender as? AlbumCollectionViewCell
            let indexPaths = self.collectionView?.indexPath(for: cell!)

            if let thisAlbum = albumItunesData?.results[indexPaths!.row] {
                detailsVC?.currentAlbum = thisAlbum
            }
        }
    }

    // MARK: - UICollectionViewDataSource

    private let reuseIdentifier = "Cell"

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albumItunesData?.resultCount ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath) as? AlbumCollectionViewCell
        cell?.albumImageView.image = nil
        if let albumArtworkURL = albumItunesData?.results[indexPath.row].artworkUrl100 {
            cell?.albumImageView.downloadedFrom(url: albumArtworkURL)
        } else {
            cell?.albumImageView.image = #imageLiteral(resourceName: "noArtwork")
        }

        cell?.albumNameLabel.text = albumItunesData?.results[indexPath.row].collectionName
        cell?.albumAuthorLabel.text = albumItunesData?.results[indexPath.row].artistName

        return cell!
    }

    // MARK: - SearchBar

    private let searchCollectionReusableView = SearchCollectionReusableView()
    private var searchText: String!

    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerView: UICollectionReusableView = collectionView.dequeueReusableSupplementaryView(
                ofKind: UICollectionElementKindSectionHeader,
                withReuseIdentifier: "CollectionViewHeader",
                for: indexPath
            )
            return headerView
        }
        return UICollectionReusableView()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !(searchBar.text?.isEmpty)! {
            getAlbums(for: searchBar.text!)
            searchText = searchBar.text!
            searchBar.endEditing(true)
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty && (albumItunesData?.resultCount == nil || albumItunesData?.resultCount == 0) {
            setupFor(status: .startSearch)
        } else {
            setupFor(status: .haveResult)
        }
    }

    // MARK: - NoDataView

    private let noDataView = NoDataView.createView()

    @objc func refreshButton(_ sender: UIButton) {
        getAlbums(for: searchText)
    }

    /// noDataView status.
    private enum ScreenStatus {
        case startSearch
        case noResult
        case error
        case haveResult
    }

    /// Setup noDataView for status.
    ///
    /// - parameter status: status for noDataStackView.
    private func setupFor(status: ScreenStatus, error: Error? = nil) {
        switch status {
        case .haveResult:
            noDataView.removeFromSuperview()
        case .startSearch:
            noDataView.reloadButton.isHidden = true
            noDataView.noDataLabel.text = "Start your search"
            view.addSubview(noDataView)
        case .noResult:
            noDataView.reloadButton.isHidden = true
            noDataView.noDataLabel.text = "No results"
            view.addSubview(noDataView)
        case .error:
            noDataView.reloadButton.isHidden = false
            noDataView.noDataLabel.text = error?.localizedDescription
            view.addSubview(noDataView)
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

    /// Search albums in iTunes database by name, download and parse it.
    ///
    /// - parameter name: searching string.
    /// - parameter completion: completion block for data pass.
    func getAlbums(for name: String ) {
        let urlString = "https://itunes.apple.com/search?term=\(name)&media=music&entity=album"
        if let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            guard let url = URL(string: encoded) else { return }
            let session = URLSession.shared
            session.dataTask(with: url) { (data, _, error) in
                guard let data = data else {
                    DispatchQueue.main.async {
                        self.albumItunesData = nil
                        self.setupFor(status: .error, error: error)
                        self.collectionView?.reloadData()
                    }
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    self.albumItunesData = nil
                    self.albumItunesData = try decoder.decode(AlbumItunesData.self, from: data)

                    DispatchQueue.main.async {
                        if self.albumItunesData?.resultCount == 0 {
                            self.setupFor(status: .noResult)
                        } else {
                            self.setupFor(status: .haveResult)
                        }
                        self.collectionView?.reloadData()
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.albumItunesData = nil
                        self.setupFor(status: .error, error: error)
                        self.collectionView?.reloadData()
                    }
                }
                }.resume()
        }
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
            DispatchQueue.main.async {
                self.image = image
            }
            }.resume()
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
