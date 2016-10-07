//
//  SavedCurrentWeather+CoreDataProperties.swift
//  WeatherViewer
//
//  Created by Darien Sandifer on 8/20/16.
//  Copyright © 2016 Darien Sandifer. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension SavedCurrentWeather {

    @NSManaged var cityId: String?
    @NSManaged var cityName: String?
    @NSManaged var weatherSummary: String?
    @NSManaged var temp: String?
    @NSManaged var dateTimestamp: String?

}
