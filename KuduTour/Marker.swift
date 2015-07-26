//
//  Marker.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/26/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//

import Foundation
import CoreData

class Marker: NSManagedObject {

  @NSManaged var desc: String
  @NSManaged var title: String
  @NSManaged var geolocation: GeoLocation
  @NSManaged var markerID: String

}
