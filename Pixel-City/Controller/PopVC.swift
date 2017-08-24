//
//  PopVC.swift
//  Pixel-City
//
//  Created by Tushar Katyal on 24/08/17.
//  Copyright © 2017 Tushar Katyal. All rights reserved.
//

import UIKit
import InstaZoom

class PopVC: UIViewController ,UIGestureRecognizerDelegate {

    @IBOutlet weak var popImgView: UIImageView!
    var passedImage: UIImage!
    
    func initData(forImage image : UIImage){
        self.passedImage = image
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        popImgView.image = passedImage
        popImgView.isPinchable = true
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(screenDoubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }

    
    
    @objc func screenDoubleTapped( _ recognizer : UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

}
