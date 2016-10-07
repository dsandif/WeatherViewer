//
//  ForecastViewController.swift
//  WeatherViewer
//
//  Created by Darien Sandifer on 8/19/16.
//  Copyright © 2016 Darien Sandifer. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import CoreData

class ForecastViewController: UIViewController, UITableViewDataSource{
    
    // MARK: - Member Vars
    var selectedCityID: String = ""
    var forecast: JSON = []
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var refreshControl: UIRefreshControl!
    
    // MARK: - UI outlets
    @IBOutlet weak var dailyWeatherTable: UITableView!
    
    // MARK: - Viewcontroller Methods
    override func viewWillAppear(animated: Bool) {
        if NetworkConnection.isConnectedToNetwork() {
            Endpoints.apiManager.getFiveDayForecast(selectedCityID, completion: {response in
                self.forecast = response
                self.title = "5 Day Forecast"
                self.deleteAllData()
                self.saveForecast(newData: self.forecast)
                self.dailyWeatherTable.reloadData()
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareTable()
        
        if !NetworkConnection.isConnectedToNetwork()  {
            forecast = JSON(fetchData())
            if forecast.count == 0{
                Alerts.alert.connectionError(fromController: self)
            }
            
            dailyWeatherTable.reloadData()
        }
    }
    
    func prepareTable() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ForecastViewController.refreshData(_:)), forControlEvents: UIControlEvents.ValueChanged)
        dailyWeatherTable.addSubview(refreshControl)
    }

    // MARK: - Core Data Helper methods
    /**
     Deletes all core data
     */
    func deleteAllData() {
        let entityDescription = NSEntityDescription.entityForName("SavedForecast", inManagedObjectContext: managedObjectContext)
        
        let request = NSFetchRequest()
        request.entity = entityDescription
        let predicate = NSPredicate(format: "%K == %@", "cityId", selectedCityID)
        request.predicate = predicate
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            
            try self.managedObjectContext.executeRequest(deleteRequest)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    /**
     Fetches data from Core Data
     - Returns: An array of 5 days worth of weather data
     */
    func fetchData() -> Array<Dictionary<String, String>>{
        var currentDay: Dictionary<String, String> = [:]
        var responseData: [Dictionary<String, String>] = []
        let entityDescription = NSEntityDescription.entityForName("SavedForecast",inManagedObjectContext: managedObjectContext)
        let request = NSFetchRequest()
        let predicate = NSPredicate(format: "%K == %@", "cityId", selectedCityID)
        request.predicate = predicate
        request.entity = entityDescription
        
        do {
            let results =
                try managedObjectContext.executeFetchRequest(request)
            
            if results.count > 0 {
                for item in results {
                    currentDay["cityId"] = String(item.valueForKey("cityId")!)
                    currentDay["name"] = String(item.valueForKey("cityName")!)
                    currentDay["dateTimestamp"] = String(item.valueForKey("dateTimestamp")!)
                    currentDay["temp"] = String(item.valueForKey("temp")!)
                    currentDay["weatherSummary"] = String(item.valueForKey("weatherSummary")!)

                    responseData.append(currentDay)
                }
                
            } else {
                print("No results found")
            }
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        print(responseData.count)
        
        return responseData
    }
    
    /**
     Saves a forecast to Core Data
     - Parameters: JSON of weather data
     */
    func saveForecast(newData newData: JSON) {
        for day in forecast["list"].arrayValue {
            let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let context:NSManagedObjectContext = appDel.managedObjectContext
            let newForecast = NSEntityDescription.insertNewObjectForEntityForName("SavedForecast", inManagedObjectContext: context) as NSManagedObject
            
            let cityId:String = forecast["city"]["id"].stringValue
            let cityName:String = forecast["name"].stringValue
            let dateTimestamp:String = day["dt"].stringValue
            let temp:String = day["main"]["temp"].stringValue
            let weatherSummary:String = day["weather"][0]["description"].stringValue
            
            newForecast.setValue(cityId,forKey: "cityId")
            newForecast.setValue(cityName,forKey: "cityName")
            newForecast.setValue(dateTimestamp,forKey: "dateTimestamp")
            newForecast.setValue(temp,forKey: "temp")
            newForecast.setValue(weatherSummary,forKey: "weatherSummary")
        }
    }
    
    /**
     Refreshes data from the web or Core Data depending on the Network Connectivity
     */
    func refreshData(refreshControl: UIRefreshControl){
        if refreshControl.refreshing && NetworkConnection.isConnectedToNetwork(){
            Endpoints.apiManager.getFiveDayForecast(selectedCityID, completion: {response in
                self.forecast = response
                self.deleteAllData()
                self.saveForecast(newData: self.forecast)
                self.dailyWeatherTable.reloadData()
            })
        }else if !NetworkConnection.isConnectedToNetwork(){
            Alerts.alert.connectionError(fromController: self)
            forecast = JSON(fetchData())
            //            deleteAllData()
            print(forecast)
            dailyWeatherTable.reloadData()
        }
        refreshControl.endRefreshing()
    }
    
    // MARK: - Timestamp Helper methods
    /**
     Get A formatted date
     
     -Parameters:
        -currentDay: A Timestamp of the current day
     -Returns: A Formatted Date (dd-mm-yyyy)
     */
    func getDateString(currentDay currentDay: Double) -> String {
        let date = NSDate(timeIntervalSince1970: currentDay)
        let dayTimePeriodFormatter = NSDateFormatter()
        dayTimePeriodFormatter.dateFormat = "dd-mm-yyyy"
        let dateString = dayTimePeriodFormatter.stringFromDate(date)
        return dateString
    }
    
    /**
     Get A formatted date to be used as a heading.
     
     -Parameters:
        -newDate: A Timestamp of the current day
     -Returns: A Formatted Date for a heading (Saturday - 3pm)
     */
    func formatDateHeading(newDate newDate: Double) -> String {
        let date = NSDate(timeIntervalSince1970: newDate)
        let dayTimePeriodFormatter = NSDateFormatter()
        dayTimePeriodFormatter.dateFormat = "EEEE - ha"
        let dateString = dayTimePeriodFormatter.stringFromDate(date)
        return dateString
    }
}

// MARK: - Delegate Methods for the Tableview
extension ForecastViewController: UITableViewDelegate{
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("DailyCell") as! DailyCell
        
        if NetworkConnection.isConnectedToNetwork() {
            let currentItem = forecast["list"][indexPath.row]
            cell.dateHeading.text = formatDateHeading(newDate: currentItem["dt"].doubleValue)
            cell.currentTemp.text = String(currentItem["main"]["temp"].intValue) + "\u{00B0}"
            cell.weatherSummary.text = currentItem["weather"][0]["description"].stringValue
        }else{
            let currentItem = forecast[indexPath.row]
            cell.dateHeading.text = formatDateHeading(newDate: Double(currentItem["dateTimestamp"].stringValue)!)
            cell.currentTemp.text = String(currentItem["temp"].intValue) + "\u{00B0}"
            cell.weatherSummary.text = String(currentItem["weatherSummary"]).capitalizedString
        }
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !NetworkConnection.isConnectedToNetwork() {
            return forecast.count
        }else{
            return forecast["cnt"].intValue
        }
    }
}