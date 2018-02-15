//
//  DetailsViewController.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 09.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{

    @IBOutlet weak var copyrightLabel: UILabel!
    @IBOutlet weak var costLabel: UILabel!
    @IBOutlet weak var explicitLabel: UILabel!
    @IBOutlet weak var albumArtworkImageView: UIImageView!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var artistNameButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var trackTableView: UITableView!
    @IBOutlet weak var tracksCountLabel: UILabel!
    var currentAlbum: AlbumItunesData.Album!
    var tracksForCurrentAlbum: [TrackItunesData.Track]!
    var trackCount: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        uiSetUp()
    }
    
    /// Set up elements on a screen.
    func uiSetUp() {
        trackTableView.rowHeight = 44
        costLabel.makeRounded()
        explicitLabel.makeRounded()
        albumArtworkImageView.makeRounded()
        
        costLabel.layer.borderWidth = 1
        costLabel.layer.borderColor = #colorLiteral(red: 0.1058823529, green: 0.6784313725, blue: 0.9725490196, alpha: 1)
        explicitLabel.layer.borderWidth = 1
        explicitLabel.layer.borderColor = #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)
        
        if let currentAlbum = currentAlbum {
            self.title = currentAlbum.collectionName
            artistNameButton.setTitle(currentAlbum.artistName, for: .normal)
            dateLabel.text = Date.getFormattedDate(from: currentAlbum.releaseDate)
            genderLabel.text = currentAlbum.primaryGenreName
            tracksCountLabel.text = "Tracks count: \(trackCount ?? 0)"
            copyrightLabel.text = currentAlbum.copyright ?? " "
            
            if String(describing: currentAlbum.artworkUrl60) != "" {
                albumArtworkImageView.downloadedFrom(url: currentAlbum.artworkUrl60)
            } else {
                albumArtworkImageView.image = #imageLiteral(resourceName: "noArtwork")
            }
            
            if currentAlbum.collectionExplicitness != "explicit" {
                explicitLabel.isHidden = true
            }
            
            
            if let price = currentAlbum.collectionPrice {
                costLabel.text = String(price)
                
                switch currentAlbum.currency {
                case "USD":
                    costLabel.text?.append(Currency.USD.rawValue)
                case "EUR":
                    costLabel.text?.append(Currency.EUR.rawValue)
                case "RUB":
                    costLabel.text?.append(Currency.RUB.rawValue)
                default:
                    return
                }
            } else {
                costLabel.text = "Free"
            }
        }
    }
    
    //MARK: - IBActions
    @IBAction func artistNameButtonPressed(_ sender: UIButton) {
        if let url = currentAlbum?.artistViewUrl {
            url.openInAppOrSafari()
        }
    }
    
    @IBAction func showInItunes(_ sender: UIBarButtonItem) {
        if let url = currentAlbum?.collectionViewUrl {
            url.openInAppOrSafari()
        }
    }
    
    //MARK: - TableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = trackTableView.dequeueReusableCell(withIdentifier: "track") as! TrackTableViewCell
        cell.trackNameLabel.text = tracksForCurrentAlbum?[indexPath.row].trackName
        cell.trackNumberLabel.text = String(indexPath.row + 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        if let url = tracksForCurrentAlbum[indexPath.row].trackViewUrl {
            url.openInAppOrSafari()
        }
    }
}

extension URL {
    
    /// Open url in native app or in Safari.
    func openInAppOrSafari() {
        if UIApplication.shared.canOpenURL(self) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(self, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(self)
            }
        }
    }
}
