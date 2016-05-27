/**
 * Stub code for reading data from Cloudant in a whisk action
 */

//import KituraNet
import Dispatch
import Foundation

func main(args: [String:Any]) -> [String:Any] {

    let result: [String:Any] = [String:Any]()

    //read data from cloudant
    print("inside Cloudant read action")
    print("(assuming we're not reusing the existin cloudant read actions written in JS)")

    // return, which should be a dictionary
    return result
}
