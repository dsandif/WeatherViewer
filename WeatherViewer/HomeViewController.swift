//
//  ViewController.swift
//  WeatherViewer
//
//  Created by Darien Sandifer on 8/19/16.
//  Copyright © 2016 Darien Sandifer. All rights reserved.
//
import Alamofire
import SwiftyJSON
import UIKit
import CoreData


class HomeViewController: UIViewController, UITableViewDataSource {
    
    // MARK: - Member Vars
    var cityList: Array = ["4887398","5368361","5128581","4699066","5391959","4671654","5419384","4990729","5809844","4644585"]
    
    var cities: JSON = []
    var refreshControl: UIRefreshControl!
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    // MARK: - UI outlets
    @IBOutlet weak var weatherTable: UITableView!
    
    // MARK: - Viewcontroller Methods
    override func viewWillAppear(animated: Bool) {
        self.title = "Current Weather"
        loadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareTable()
    }
    
    // MARK: - Core Data Helper methods
    /**
        Deletes All data from Core Data for debugging
     */
    func deleteAllData() {
        let entityDescription = NSEntityDescription.entityForName("SavedCurrentWeather", inManagedObjectContext: managedObjectContext)
        let request = NSFetchRequest()
        request.entity = entityDescription
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {

            try self.managedObjectContext.executeRequest(deleteRequest)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    /**
     Fetches data from Core Data
     */
    func fetchData() -> Array<Dictionary<String, String>>{
        var currentCity: Dictionary<String, String> = [:]
        var responseData: [Dictionary<String, String>] = []
        let entityDescription = NSEntityDescription.entityForName("SavedCurrentWeather",inManagedObjectContext: managedObjectContext)
        let request = NSFetchRequest()
        
        request.entity = entityDescription
        do {
            let results =
                try managedObjectContext.executeFetchRequest(request)
            
            if results.count > 0 {
                for item in results {
                    currentCity["cityId"] = String(item.valueForKey("cityId")!)
                    currentCity["name"] = String(item.valueForKey("cityName")!)
                    currentCity["dateTimestamp"] = String(item.valueForKey("dateTimestamp")!)
                    currentCity["temp"] = String(item.valueForKey("temp")!)
                    currentCity["weatherSummary"] = String(item.valueForKey("weatherSummary")!)
                    responseData.append(currentCity)
                }

            } else {
                print("No results found")
            }
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return responseData
    }
    
    /**
     Saves data to Core Data
     - Parameters:
        - newData: a JSON object representing weather data from a city
     */
    func saveData(newData newData:JSON) {
        for city in newData["list"].arrayValue {
            let entityDescription =
                NSEntityDescription.entityForName("SavedCurrentWeather",
                                                  inManagedObjectContext: managedObjectContext)
            
            let currentWeather = SavedCurrentWeather(entity: entityDescription!,
                                                     insertIntoManagedObjectContext: managedObjectContext)

            let cityId:String = city["id"].stringValue
            let cityName:String = city["name"].stringValue
            let dateTimestamp:String = city["dt"].stringValue
            let temp:String = city["main"]["temp"].stringValue
            let weatherSummary:String = city["weather"][0]["description"].stringValue
            
            currentWeather.setValue(cityId,forKey: "cityId")
            currentWeather.setValue(cityName,forKey: "cityName")
            currentWeather.setValue(dateTimestamp,forKey: "dateTimestamp")
            currentWeather.setValue(temp,forKey: "temp")
            currentWeather.setValue(weatherSummary,forKey: "weatherSummary")
        }
        
        do {
            try managedObjectContext.save()
            
        } catch let error as NSError {
            print(error.localizedFailureReason)
        }

    }
    
    /**
     Refreshes data
     - Parameters:
        - refreshControl: a loading spinner
     */
    func refreshData(refreshControl: UIRefreshControl){
        loadData()
        refreshControl.endRefreshing()
    }
    /**
     Loads weather Data
     */
    func loadData() {
        if NetworkConnection.isConnectedToNetwork() {
            Endpoints.apiManager.getCurrentWeather(cityList, completion: {response in
                self.cities = response
                self.deleteAllData()
                self.saveData(newData: self.cities)
                self.weatherTable.reloadData()
            })
        }else if !NetworkConnection.isConnectedToNetwork(){
            cities = JSON(fetchData())
            weatherTable.reloadData()
            if cities.count == 0 {
                Alerts.alert.connectionError(fromController: self)
            }
        }
    }
    
    func prepareTable() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(HomeViewController.refreshData(_:)), forControlEvents: UIControlEvents.ValueChanged)
        weatherTable.addSubview(refreshControl)
    }
    // MARK: - Segue Logic
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ForecastSegue" {
            
            if NetworkConnection.isConnectedToNetwork() {
                let selectedID:String = cityList[(weatherTable.indexPathForSelectedRow?.row)!]
                
                if let destination = segue.destinationViewController as? ForecastViewController{
                    destination.selectedCityID = selectedID
                }
            }else{
                let selectedID:String = cities[weatherTable.indexPathForSelectedRow!.row]["cityId"].stringValue
                
                if let destination = segue.destinationViewController as? ForecastViewController{
                    destination.selectedCityID = selectedID
                }
            }
        }
    }
}

// MARK: - Delegate Methods for the Tableview
extension HomeViewController: UITableViewDelegate{
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("CityCell") as! CityCell
        
        if NetworkConnection.isConnectedToNetwork() {
            var currentCity = cities["list"][indexPath.row]
            cell.cityName.text = currentCity["name"].stringValue
            cell.summary.text = currentCity["weather"][0]["description"].stringValue.capitalizedString
            cell.temperature.text = String(currentCity["main"]["temp"].intValue) + "\u{00B0}"

        }else if !NetworkConnection.isConnectedToNetwork(){
            var savedCity = cities[indexPath.row]
            cell.cityName.text = String(savedCity["name"])
            cell.summary.text = String(savedCity["weatherSummary"]).capitalizedString
            cell.temperature.text = String(savedCity["temp"].intValue) + "\u{00B0}"
        }
        
        return cell
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if NetworkConnection.isConnectedToNetwork() {
            return cities["cnt"].intValue
        }else{
            return cities.count
        }
    }
}

