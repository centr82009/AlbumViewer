//
//  AlbumCollectionViewCell.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 09.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import UIKit

class AlbumCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var albumAuthorLabel: UILabel!
}

extension UIView {
    func makeRounded() {
        self.layer.cornerRadius = 8
        self.clipsToBounds = true
    }
}
