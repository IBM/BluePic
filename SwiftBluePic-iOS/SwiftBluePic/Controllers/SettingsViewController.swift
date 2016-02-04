//
//  Created by Samuel Kallner on 2/24/15.
//  Copyright (c) 2015 IBM Corporation. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    let CONNECTIVITY_SECTION = 0
    
    func refreshUI() {
        if  let tv = tableView  {
            let connectivityCell = tv.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: CONNECTIVITY_SECTION)) as! SettingsConnectivityCell
            connectivityCell.refreshUI()
        }
    }
    
    override func viewDidLoad() {
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRectZero) // disable empty rows
        // keep the cells from shrinking vertically when segueing from the view (the number is not really important)
        tableView.estimatedRowHeight = 111
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return  "Connectivity"
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = indexPath.section
        
        var cell: UITableViewCell
        
        switch(section) {
        case CONNECTIVITY_SECTION:
            let cellConn = tableView.dequeueReusableCellWithIdentifier("SettingsConnectivityCell") as! SettingsConnectivityCell
            cell = cellConn
            
        default:
            cell = UITableViewCell()
        }
        return cell
    }
    
}
