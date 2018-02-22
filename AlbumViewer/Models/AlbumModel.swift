//
//  Brain.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 08.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import Foundation

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
