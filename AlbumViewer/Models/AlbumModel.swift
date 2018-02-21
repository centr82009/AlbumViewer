//
//  Brain.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 08.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import Foundation

/// Model class responsible for loading and parse data.
struct AlbumModel {
    
    /// Search albums in iTunes database by name, download and parse it.
    ///
    /// - parameter name: searching string.
    /// - parameter completion: completion block for data pass.
    func getAlbums(for name: String, completion: @escaping (((AlbumItunesData?, error: Error?)) -> Void)) {
        let urlString = "https://itunes.apple.com/search?term=\(name)&media=music&entity=album"
        if let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            guard let url = URL(string: encoded) else { return }
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, error) in
                guard let data = data else {
                    completion((nil, error))
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let albumItunesData = try decoder.decode(AlbumItunesData.self, from: data)
                    completion((albumItunesData, error))
                } catch {
                    completion((nil, error))
                }
                }.resume()
        }
    }
}

// MARK: - Class of albums

struct AlbumItunesData: Codable {

    var resultCount: Int
    var results: [Album]

    struct Album: Codable {
        let artistName: String
        let collectionName: String
        let collectionViewUrl: URL
        let artworkUrl60: URL
        let artworkUrl100: URL
        let artistViewUrl: URL?
        let collectionPrice: Double?
        let collectionExplicitness: String
        let copyright: String?
        let currency: String
        let releaseDate: String
        let primaryGenreName: String
        let collectionId: Int?
    }
}
