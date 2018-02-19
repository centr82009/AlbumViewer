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
    
    ///Model instance
    private let brain = Brain()
    
    private let searchCollectionReusableView = SearchCollectionReusableView()
    
    private let myActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    private var albumItunesData: AlbumItunesData? {
        didSet {
            albumsCount = albumItunesData?.resultCount
            albums = albumItunesData?.results
        }
    }
    
    private var albumsCount: Int?
    
    private var error: Error?
    
    private var searchText: String!
    
    private var albums: [AlbumItunesData.Album]?
    
    // We delete 1 in trackCount cause in in the first element stores information about the album.
    private var trackItunesData: TrackItunesData? {
        didSet {
            tracks = trackItunesData?.results
            if let resultCount = trackItunesData?.resultCount {
                trackCount = resultCount - 1
            } else {
                trackCount = 0
            }
        }
    }
    
    private var trackCount: Int?
    
    // We delete 1st element in tracks cause in in the first element stores information about the album.
    private var tracks: [TrackItunesData.Track]? {
        didSet {
            tracks?.remove(at: 0)
        }
    }
    
    @IBOutlet weak var noDataStackView: UIStackView!
    @IBOutlet weak var noDataLabel: UILabel!
    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var noDataImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
       
        noDataImage.image = #imageLiteral(resourceName: "search")
        
        reloadButton.isHidden = true
        reloadButton.makeRounded()
        reloadButton.layer.borderWidth = 1
        reloadButton.layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        myActivityIndicator.center = view.center
        view.addSubview(myActivityIndicator)
    }
    
    // MARK: - Take data from model
    
    private func useAlbumData(request: (data: AlbumItunesData?, error: Error?)) {
        albumItunesData = request.data
        error = request.error
    }
    
    private func useTrackData(request: (data: TrackItunesData?, error: Error?)) {
        trackItunesData = request.data
        error = request.error
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        noDataStackView.isHidden = false
        if segue.identifier == "DetailsViewSegue" {
            let detailsVC = segue.destination as! DetailsViewController
            let cell = sender as! AlbumCollectionViewCell
            let indexPaths = self.collectionView?.indexPath(for: cell)
            
            if let error = error {
                detailsVC.tracksCountLabel.text = error.localizedDescription
            }
            
            if let thisAlbum = albums?[indexPaths!.row], let collectionId = thisAlbum.collectionId {
                
                tracksSearch(for: collectionId)
                
                detailsVC.currentAlbum = thisAlbum
                detailsVC.tracksForCurrentAlbum = tracks
                detailsVC.trackCount = trackCount
                noDataStackView.isHidden = true
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
    
    /// Search tracks by collectionId
    ///
    /// - parameter collectionId: searching collectionId.
    func tracksSearch(for collectionId: Int) {
        myActivityIndicator.startAnimating()
        brain.getTracks(for: collectionId, completion: { [weak self] (data: TrackItunesData?, error: Error?) in
            self?.useTrackData(request: (data: data, error: error))
        })
        myActivityIndicator.stopAnimating()
    }
    
    /// Search albums by term
    ///
    /// - parameter name: searching term.
    func albumSearch(for name: String) {
        myActivityIndicator.startAnimating()
        noDataStackView.isHidden = true
        brain.getAlbums(for: name, completion: { [weak self] (data: AlbumItunesData?, error: Error?) in
            self?.useAlbumData(request: (data: data, error: error))
        })
        collectionView?.reloadData()
        myActivityIndicator.stopAnimating()
    }
    
    // MARK: - SearchBar
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if (kind == UICollectionElementKindSectionHeader) {
            let headerView:UICollectionReusableView =  collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "CollectionViewHeader", for: indexPath)
            
            return headerView
        }
        return UICollectionReusableView()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if(!(searchBar.text?.isEmpty)!) {
            albumSearch(for: searchBar.text!)
            searchText = searchBar.text!
        }
        
        if error != nil {
            setupFor(status: .noInternet)
            
        } else if albums?.count == 0 || albums == nil {
            setupFor(status: .noResult)
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !(searchText.isEmpty) {
            noDataStackView.isHidden = true
        } else if albums?.count == 0 || albums == nil {
            setupFor(status: .startSearch)
        }
    }
    
    // MARK: - NoDataStackView
    
    /// noDataStackView status.
    enum ScreenStatus {
        case startSearch
        case noResult
        case noInternet
    }
    
    /// Setup noDataStackView for status.
    ///
    /// - parameter status: status for noDataStackView.
    func setupFor(status: ScreenStatus) {
        noDataStackView.isHidden = false
        switch status {
        case .startSearch:
            noDataImage.image = #imageLiteral(resourceName: "search")
            reloadButton.isHidden = true
            noDataLabel.text = "Start your search"
        case .noResult:
            noDataImage.image = #imageLiteral(resourceName: "search")
            reloadButton.isHidden = true
            noDataLabel.text = "No results"
        case .noInternet:
            noDataImage.image = #imageLiteral(resourceName: "noInternet")
            reloadButton.isHidden = false
            noDataLabel.text = error!.localizedDescription
        }
    }
    
    @IBAction func refreshButton(_ sender: UIButton) {
        albumSearch(for: searchText)
        
        if error != nil {
            setupFor(status: .noInternet)
            
        } else if albums?.count == 0 || albums == nil {
            setupFor(status: .noResult)
        } else {
            reloadButton.isHidden = true
        }
    }
    
    func setupActivityIndicator() {
        
    }
}

///Contains currency data
enum Currency: String {
    case USD = "$"
    case RUB = "₽"
    case EUR = "€"
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

extension UIViewController {
    
    /// Hide keyboard when you tapped around.
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension Date {
    
    /// Formatte date.
    ///
    /// - parameter string: date for formatte.
    /// - returns: formatted date.
    static func getFormattedDate(from string: String) -> String{
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
