//
//  PictureViewController.swift
//  CloudKitDash
//
//  Created by Afonso H Sabino on 26/05/19.
//  Copyright © 2019 Afonso H Sabino. All rights reserved.
//
// All code in this project is come from the book "iOS Apps for Masterminds"
// You can know more about that in http://www.formasterminds.com

import UIKit
import CloudKit

class PictureViewController: UIViewController {

    @IBOutlet weak var cityPicture: UIImageView!
    
    var selectedCity: Cities!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if selectedCity != nil {
            
            if let picture = selectedCity.picture {
                cityPicture.image = UIImage(data: picture)
            }
        }
    }
}
