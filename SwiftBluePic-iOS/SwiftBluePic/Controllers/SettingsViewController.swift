/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

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
