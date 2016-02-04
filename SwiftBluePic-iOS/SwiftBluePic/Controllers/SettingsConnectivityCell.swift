//
//  Created by Samuel Kallner on 2/25/15.
//  Copyright (c) 2015 IBM Corporation. All rights reserved.
//

import UIKit

class SettingsConnectivityCell: UITableViewCell, UITextFieldDelegate {
    
    @IBOutlet weak var serverField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateUI()
    }
    
    private func updateUI() {
        
        serverField.delegate = self
        serverField.returnKeyType = UIReturnKeyType.Done
        refreshUI()
    }
    
    
    func refreshUI() {
        let server = NSUserDefaults.standardUserDefaults().stringForKey(Utils.PREFERENCE_SERVER)
        serverField.text = server
    }
    
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidEndEditing(textField: UITextField) {
        if serverField.text != NSUserDefaults.standardUserDefaults().stringForKey(Utils.PREFERENCE_SERVER)  {
            NSUserDefaults.standardUserDefaults().setObject(serverField.text, forKey: Utils.PREFERENCE_SERVER)
            
            PhotosDataManager.SharedInstance.connect(serverField.text!) { error in
                if let _ = error {
                    DataManagerCalbackCoordinator.SharedInstance.sendNotification(.ServerConnectionFailure("Bad server URL: " + self.serverField.text!))
                }
                else {
                    DataManagerCalbackCoordinator.SharedInstance.sendNotification(.ServerConnectionSuccess)
                }
            }
        }
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
