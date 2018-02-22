//
//  DetailsViewController.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 09.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
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
    private var trackItunesData: TrackItunesData?

    override func viewDidLoad() {
        super.viewDidLoad()
        getTracks(for: currentAlbum.collectionId!)
        uiSetUp()
    }

    /// Set up elements on a screen.
    private func uiSetUp() {
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
                let currencyIcon = currentAlbum.currency.сurrencyIconFromAbbreviation()
                costLabel.text = String(price) + currencyIcon
            } else {
                costLabel.text = "Free"
            }
        }
    }

    // MARK: - IBActions
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

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trackItunesData?.resultCount ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = trackTableView.dequeueReusableCell(withIdentifier: "track") as! TrackTableViewCell
        cell.trackNameLabel.text = trackItunesData?.results[indexPath.row].trackName
        cell.trackNumberLabel.text = String(indexPath.row + 1)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        if let url = trackItunesData?.results[indexPath.row].trackViewUrl {
            url.openInAppOrSafari()
        }
    }
    
    /// Search tracks in iTunes database by collectionId, download and parse it.
    ///
    /// - parameter for: collectionId.
    /// - parameter completion: completion block for data pass.
    func getTracks(for collectionId: Int) {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(collectionId)&entity=song") else { return }
        let session = URLSession.shared
        session.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    self.tracksCountLabel.text = error!.localizedDescription
                }
                return
            }
            do {
                let decoder = JSONDecoder()
                var outputData = try decoder.decode(TrackItunesData.self, from: data)
                outputData.results.remove(at: 0)
                outputData.resultCount -= 1
                self.trackItunesData = outputData
                DispatchQueue.main.async {
                    self.tracksCountLabel.text = "Tracks count: \(outputData.resultCount)"
                    self.trackTableView.reloadData()
                }
            } catch {
                DispatchQueue.main.async {
                    self.tracksCountLabel.text = error.localizedDescription
                }
            }
            }.resume()
    }
}

extension String {
    
    /// Convert currency from abbreviation to icon
    ///
    /// - returns: abbreviation
    func сurrencyIconFromAbbreviation() -> String {
        switch self {
        case "USD":
            return "$"
        case "RUB":
            return "₽"
        case "EUR":
            return "€"
        default:
            return "?"
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
