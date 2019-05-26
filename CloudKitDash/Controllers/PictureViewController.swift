//
//  PictureViewController.swift
//  CloudKitDash
//
//  Created by Afonso H Sabino on 26/05/19.
//  Copyright © 2019 Afonso H Sabino. All rights reserved.
//

import UIKit
import CloudKit

class PictureViewController: UIViewController {

    @IBOutlet weak var cityPicture: UIImageView!
    
    var selectedCity: CKRecord!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if selectedCity != nil {
            if let asset = selectedCity["picture"] as? CKAsset {
                self.cityPicture.image = UIImage(contentsOfFile: asset.fileURL!.path)
            }
        }
        
    }


}
