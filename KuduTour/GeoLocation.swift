//
//  GeoLocation.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/26/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//

import Foundation
import CoreData

class GeoLocation: NSManagedObject {

  @NSManaged var altitude: NSNumber
  @NSManaged var latitude: NSNumber
  @NSManaged var longitude: NSNumber
  @NSManaged var id: NSNumber

}
