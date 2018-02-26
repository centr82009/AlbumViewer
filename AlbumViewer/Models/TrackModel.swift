//
//  TrackModel.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 21.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import Foundation

struct TrackItunesData: Codable {

    var resultCount: Int
    var results: [Track]

    struct Track: Codable {
        let trackName: String?
        let trackViewUrl: URL?
    }
}
