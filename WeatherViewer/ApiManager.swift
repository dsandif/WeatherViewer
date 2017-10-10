//
//  ApiManager.swift
//  WeatherViewer
//
//  Created by Darien Sandifer on 8/19/16.
//  Copyright © 2016 Darien Sandifer. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

//An interface for interacting with the weather API Asynchronously
class Endpoints{
    
    // STATIC INSTANCE
    static var  apiManager = Endpoints()
    
    // ENDPOINT URLS
    let currentEndpoint = "http://api.openweathermap.org/data/2.5/group?id="
    let fiveDayEndpoint = "http://api.openweathermap.org/data/2.5/forecast?id="
    
    //API keys -- Add yours
    let apiKey: String = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    
    /**
     Gets a 5 day forecast for a city
     
     - Parameter cityId: The ID of a city
     */
    func getFiveDayForecast(cityId: String, completion: (JSON) ->()) {
        let url = fiveDayEndpoint+cityId+"&appid="+apiKey+"&units=imperial"
        
        Alamofire.request(.GET, url).validate().responseJSON { response in

            switch response.result {
            case .Success:
                if let value = response.result.value {
                    let json = JSON(value)
                    completion(json)
                }
            case .Failure(let error):
                print(error)
            }
        }
    }
    
    /**
     Gets the current weather for a list of cities
     
     - Parameter cityIds: an array of city ID's
     */
    func getCurrentWeather(cityIds: [String], completion: (JSON) ->()) {
        
        let parameters = cityIds.joinWithSeparator(",")
        let url = currentEndpoint+parameters+"&appid="+apiKey+"&units=imperial"
        
        Alamofire.request(.GET, url).validate().responseJSON { response in
            
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    let json = JSON(value)
                    completion(json)
                }
            case .Failure(let error):
                print(error)
            }
        }
    }
}
