//
//  Brain.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 08.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import Foundation

/// Model class responsible for loading and parse data.
class Brain {
    
    // MARK: - Download data functions
    /// Search albums in iTunes database by name, download and parse it.
    ///
    /// - parameter name: searching string.
    /// - parameter completion: completion block for data pass.
    func getAlbums(for name: String, completion: @escaping ((_ data: AlbumItunesData?) -> Void)) {
        let semaphore = DispatchSemaphore(value: 0)
        var albumItunesData: AlbumItunesData?
        let urlString = "https://itunes.apple.com/search?term=\(name)&media=music&entity=album"
        if let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            guard let url = URL(string: encoded) else { return }
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, error) in
                guard let data = data else { return }
                do {
                    let decoder = JSONDecoder()
                    albumItunesData = try decoder.decode(AlbumItunesData.self, from: data)
                    completion(albumItunesData)
                    semaphore.signal()
                } catch {
                    completion(albumItunesData)
                    semaphore.signal()
                }
                }.resume()
            semaphore.wait()
        }
    }
    
    /// Search tracks in iTunes database by collectionId, download and parse it.
    ///
    /// - parameter for: collectionId.
    /// - parameter completion: completion block for data pass.
    func getTracks(for collectionId: Int, completion: @escaping ((_ data: TrackItunesData?) -> Void)) {
        let semaphore = DispatchSemaphore(value: 0)
        var trackItunesData: TrackItunesData?
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(collectionId)&entity=song") else { return }
        let session = URLSession.shared
        session.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                trackItunesData = try decoder.decode(TrackItunesData.self, from: data)
                completion(trackItunesData)
                semaphore.signal()
            } catch {
                completion(trackItunesData)
                semaphore.signal()
            }
            }.resume()
        semaphore.wait()
    }
}

// MARK: - Classes for data parse
/// Model class of tracks.
struct TrackItunesData: Codable {
    
    let resultCount: Int
    var results: [Track]
    
    struct Track: Codable {
        let trackName: String?
        let trackViewUrl: URL?
    }
}

/// Model class of albums.
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
