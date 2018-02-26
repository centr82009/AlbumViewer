//
//  noDataView.swift
//  AlbumViewer
//
//  Created by Mazeev Roman on 26.02.2018.
//  Copyright © 2018 Mazeev Roman. All rights reserved.
//

import UIKit

class NoDataView: UIView {
    @IBOutlet weak var noDataImageView: UIImageView!
    @IBOutlet weak var noDataLabel: UILabel!
    @IBOutlet weak var reloadButton: CustomButton!

    class func createView() -> NoDataView {
        let noDataViewNib = UINib(nibName: "NoDataView", bundle: nil)
        return (noDataViewNib.instantiate(withOwner: nil, options: nil)[0] as? NoDataView)!
    }
}
