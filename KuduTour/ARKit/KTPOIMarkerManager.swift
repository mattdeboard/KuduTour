//
//  KTPOIMarkerManager.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/15/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//
import AFNetworking
import CoreData
import CoreLocation
import Foundation
import SwiftyJSON
import UIKit

class KTPOIMarkerManager: NSObject {
  var netManager = networkManager()
  var fetchNotification = NSNotification(name: "markerFetchComplete", object: nil)
  var markers: [ARGeoCoordinate?] = []

  func fetchMarkers(vc: UIViewController, url: String) {
    netManager.GET(url,
      parameters: nil,
      success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
        let json = JSON(responseObject)
        let app = appDelegate()

        if let moContext = app.managedObjectContext {
          for (index: String, subJson: JSON) in json["results"] {
            if let myMarker = self.createOrUpdateMarkerEntity(subJson, moContext: moContext) {
              self.markers.append(self.geoCoordFromMarker(myMarker))
            }
          }
          NSNotificationCenter.defaultCenter().postNotification(self.fetchNotification)
        }
      },
      failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in
        let alert: UIAlertView = UIAlertView(title: "Server Unreachable",
          message: "KuduTour could not reach the server. Check network connectivity and try again.",
          delegate: nil, cancelButtonTitle: "OK")
        alert.show()
      }
    )
  }

  func fetchMarkers(vc: UIViewController) {
    return fetchMarkers(vc, url: resourcePath(netManager, "markers/?page=2"))
  }

  func createOrUpdateMarkerEntity(data: JSON, moContext: NSManagedObjectContext) -> Marker? {
    var localEntity: Marker?

    if let markerID = data["id"].number {
      var err: NSError?
      var fetchRequest = NSFetchRequest(entityName: "Marker")
      fetchRequest.predicate = NSPredicate(format: "id = %@", markerID)
      let fetchedResults = moContext.executeFetchRequest(fetchRequest, error: &err)

      if let matches = fetchedResults {
        if matches.count == 0 {
          localEntity = NSEntityDescription.insertNewObjectForEntityForName("Marker",
            inManagedObjectContext: moContext) as? Marker
          localEntity?.id = markerID
        } else {
          localEntity = matches[0] as? Marker
        }
        localEntity?.title = data["title"].stringValue
        localEntity?.desc = data["description"].stringValue

        if let geoloc = createOrUpdateGeoLocationEntity(data, moContext: moContext) {
          localEntity?.geolocation = geoloc
        }
      }
    }
    return localEntity
  }

  func createOrUpdateGeoLocationEntity(data: JSON, moContext: NSManagedObjectContext) -> GeoLocation? {
    var localEntity: GeoLocation?
    if let geolocID = data["id"].number {
      var err: NSError?
      var fetchRequest = NSFetchRequest(entityName: "GeoLocation")
      fetchRequest.predicate = NSPredicate(format: "id = %@", geolocID)
      let fetchedResults = moContext.executeFetchRequest(fetchRequest, error: &err)
      if let matches = fetchedResults {
        if matches.count == 0 {
          localEntity = NSEntityDescription.insertNewObjectForEntityForName("GeoLocation",
            inManagedObjectContext: moContext) as? GeoLocation
          localEntity?.id = geolocID
        } else {
          localEntity = matches[0] as? GeoLocation
        }
        let coords = data["geolocation"] as JSON
        localEntity?.latitude = coords["latitude"].numberValue
        localEntity?.longitude = coords["longitude"].numberValue
        localEntity?.altitude = data["altitude"].numberValue
      }
    }
    return localEntity
  }

  func geoCoordFromMarker(marker: Marker) -> ARGeoCoordinate {
    let loc = ARGeoCoordinate(view: KTGeoCoordinateViewController())
    loc.geoLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(
        latitude: CLLocationDegrees(marker.geolocation.latitude),
        longitude: CLLocationDegrees(marker.geolocation.longitude)),
      altitude: CLLocationDistance(marker.geolocation.altitude),
      horizontalAccuracy: CLLocationAccuracy(),
      verticalAccuracy: CLLocationAccuracy(),
      timestamp: nil)
    loc.title = marker.title
    loc.subtitle = marker.desc
    return loc
  }
}