//
//  CustomButton.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 25.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import UIKit

@IBDesignable class CustomButton: UIButton {

    @IBInspectable var rounded: Bool = true {
        didSet {
            makeRounded()
        }
    }

    @IBInspectable var border: Double = 1.0 {
        didSet {
            self.layer.borderWidth = CGFloat(border)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.borderColor = titleLabel?.textColor.cgColor
    }
}
