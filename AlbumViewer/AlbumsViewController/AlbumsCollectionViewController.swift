//
//  HomeCollectionViewController.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 09.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"
private let brain = Brain()
private let searchCollectionReusableView = SearchCollectionReusableView()

private var albumItunesData: AlbumItunesData? {
    didSet {
        albumsCount = albumItunesData?.resultCount
        albums = albumItunesData?.results
    }
}
private var albumsCount: Int?
private var albums: [AlbumItunesData.Album]?

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
private var tracks: [TrackItunesData.Track]? {
    didSet {
        tracks?.remove(at: 0)
    }
}

class AlbumsCollectionViewController: UICollectionViewController, UISearchBarDelegate {
    
    @IBOutlet weak var noDataStackView: UIStackView!
    @IBOutlet weak var noDataLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
    }
    
    private func useAlbumData(data: AlbumItunesData?) {
        albumItunesData = data
    }
    
    private func useTrackData(data: TrackItunesData?) {
        trackItunesData = data
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DetailsViewSegue" {
            let detailsVC = segue.destination as! DetailsViewController
            let cell = sender as! AlbumCollectionViewCell
            let indexPaths = self.collectionView?.indexPath(for: cell)
            if let thisAlbum = albums?[indexPaths!.row], let collectionId = thisAlbum.collectionId {
                brain.getTracks(for: collectionId, completion: { [weak self] (data: TrackItunesData?) in
                    self?.useTrackData(data: data)
                })
                detailsVC.currentAlbum = thisAlbum
                detailsVC.tracksForCurrentAlbum = tracks
                detailsVC.trackCount = trackCount
            }
        }
    }
    
    // MARK: UICollectionViewDataSource
    
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
    
    // MARK: SearchBar
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if (kind == UICollectionElementKindSectionHeader) {
            let headerView:UICollectionReusableView =  collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "CollectionViewHeader", for: indexPath)
            
            return headerView
        }
        return UICollectionReusableView()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if(!(searchBar.text?.isEmpty)!){
            makeSearch(sender: searchBar.text!)
            if albums?.count == 0 || albums == nil {
                noDataStackView.isHidden = false
                noDataLabel.text = "No results"
            }
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !(searchText.isEmpty) {
            noDataStackView.isHidden = true
        } else if albums?.count == 0 || albums == nil {
            noDataStackView.isHidden = false
            noDataLabel.text = "Start your search"
        }
    }
    
    func makeSearch(sender: String) {
        brain.getAlbums(for: sender, completion: { [weak self] (data: AlbumItunesData?) in
            self?.useAlbumData(data: data)
        })
        collectionView?.reloadData()
    }
}

enum Currency: String {
    case USD = "$"
    case RUB = "₽"
    case EUR = "€"
}

extension UIImageView {
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
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}

extension UIView {
    func makeRounded() {
        self.layer.cornerRadius = 8.0
        self.clipsToBounds = true
    }
}

extension UIViewController {
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
