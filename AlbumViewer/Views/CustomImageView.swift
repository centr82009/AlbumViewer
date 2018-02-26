//
//  CustomImageView.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 26.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import UIKit

@IBDesignable class CustomImageView: UIImageView {

    @IBInspectable var rounded: Bool = true {
        didSet {
            makeRounded()
        }
    }
}
