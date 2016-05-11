//
//  ImageDetailViewController.swift
//  BluePic
//
//  Created by Alex Buck on 5/11/16.
//  Copyright © 2016 MIL. All rights reserved.
//

import UIKit

class ImageDetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var backButton: UIButton!
    
    
    var image : Image!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubviewWithImageData()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupSubviewWithImageData(){
        
        if let urlString = image.url {
            
            let nsurl = NSURL(string: urlString)
            
            imageView.sd_setImageWithURL(nsurl)
        }
        
    }
    
    
    @IBAction func backButtonAction(sender: AnyObject) {
        
        self.navigationController?.popViewControllerAnimated(true)
        
        
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
