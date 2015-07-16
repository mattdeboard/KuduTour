//
//  KTPOIMarkerManager.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/15/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//
import AFNetworking
import CoreLocation
import Foundation
import SwiftyJSON
import UIKit

class Marker: NSObject {
  var latitude: CLLocationDegrees?
  var longitude: CLLocationDegrees?
  var altitude: CLLocationDistance?
  var title: String?
  var subtitle: String?

  convenience init(data: JSON) {
    self.init()
    let geoloc: JSON = data["geolocation"]
    latitude = CLLocationDegrees(geoloc["lat"].numberValue)
    longitude = CLLocationDegrees(geoloc["lon"].numberValue)
    altitude = data["altitude"].numberValue as CLLocationDistance
    title = data["title"].stringValue
    subtitle = data["description"].stringValue
  }
}

class KTPOIMarkerManager: NSObject {
  var netManager = networkManager()
  var fetchNotification = NSNotification(name: "markerFetchComplete", object: nil)
  var markers: [ARGeoCoordinate?] = []

  func fetchmarkers(vc: UIViewController, url: String) {
    netManager.GET(url,
      parameters: nil,
      success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
        let json = JSON(responseObject)
        for (index: String, subJson: JSON) in json["results"] {
          self.markers.append(self.geoCoordFromMarker(Marker(data: subJson)))
        }
        NSNotificationCenter.defaultCenter().postNotification(self.fetchNotification)
      },
      failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
        println("Error: \(error.localizedDescription)")
      }
    )
  }

  func fetchMarkers(vc: UIViewController) {
    return fetchmarkers(vc, url: resourcePath(netManager, "markers/?page=2"))
  }

  func geoCoordFromMarker(marker: Marker) -> ARGeoCoordinate {
    let loc = ARGeoCoordinate()
    loc.geoLocation = CLLocation(
      coordinate: CLLocationCoordinate2D(latitude: marker.latitude!, longitude: marker.longitude!),
      altitude: marker.altitude!,
      horizontalAccuracy: CLLocationAccuracy(),
      verticalAccuracy: CLLocationAccuracy(),
      timestamp: nil
    )
    loc.title = marker.title!
    loc.subtitle = marker.subtitle!
    return loc
  }
}