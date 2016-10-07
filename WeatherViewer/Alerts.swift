//
//  Alerts.swift
//  WeatherViewer
//
//  Created by Darien Sandifer on 8/19/16.
//  Copyright © 2016 Darien Sandifer. All rights reserved.
//

import Foundation
import UIKit

//An interface for showing alerts
class Alerts {
    
    //Static Instance
    static var alert = Alerts()
    
    /**
     Shows an alert for a connection error
     
     - Parameter fromController: The viewController that is presenting the alert
     */
    func connectionError(fromController controller: UIViewController) {
    
        let alertController = UIAlertController(title: "Connection Error", message: "Make sure you are connected to the internet, then pull to refresh.", preferredStyle: .Alert)
        let okayAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: {(alert :UIAlertAction!) in})
        alertController.addAction(okayAction)
        controller.presentViewController(alertController, animated: true, completion: nil)
    }
}