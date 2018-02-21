//
//  TrackModel.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 21.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import Foundation

struct TrackModel {
    
    /// Search tracks in iTunes database by collectionId, download and parse it.
    ///
    /// - parameter for: collectionId.
    /// - parameter completion: completion block for data pass.
    func getTracks(for collectionId: Int, completion: @escaping (((TrackItunesData?, error: Error?)) -> Void)) {
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=\(collectionId)&entity=song") else { return }
        let session = URLSession.shared
        session.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                completion((nil, error))
                return
            }
            do {
                let decoder = JSONDecoder()
                let trackItunesData = try decoder.decode(TrackItunesData.self, from: data)
                completion((trackItunesData, error))
            } catch {
                completion((nil, error))
            }
            }.resume()
    }
}

// MARK: - Class of tracks
struct TrackItunesData: Codable {
    
    let resultCount: Int
    var results: [Track]
    
    struct Track: Codable {
        let trackName: String?
        let trackViewUrl: URL?
    }
}

