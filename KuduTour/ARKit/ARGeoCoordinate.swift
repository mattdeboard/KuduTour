//
//  ARGeoCoordinate.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/14/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//

import CoreLocation
import Foundation
import UIKit

func angleFromCoordinate(first: CLLocationCoordinate2D, second: CLLocationCoordinate2D) -> Float64 {
  let longitudinalDifference = second.longitude - first.longitude
  let latitudinalDifference = second.latitude - first.latitude
  let possibleAzimuth = (M_PI * 0.5) - atan(longitudinalDifference / latitudinalDifference)

  if longitudinalDifference > 0 {
    return possibleAzimuth
  } else if longitudinalDifference < 0 {
    return possibleAzimuth + M_PI
  } else if latitudinalDifference < 0 {
    return M_PI
  }
  return 0.0
}

private var titleContext = 0

class ARGeoCoordinate: ARCoordinate {
  var distanceFromOrigin: CLLocationDistance?
  var geoLocation: CLLocation?
  var markerView: ARGeoCoordinateViewProtocol?

  convenience init(view: ARGeoCoordinateViewProtocol) {
    self.init()
    markerView = view
  }

  func calibrateUsingOrigin(origin: CLLocation) {
    if let loc = geoLocation {
      let dist = origin.distanceFromLocation(loc)
      distanceFromOrigin = dist
      markerView?.didUpdateDistanceFromOrigin(dist)
      radialDistance = sqrt(pow(origin.altitude - loc.altitude, 2)) + pow(distanceFromOrigin!, 2)

      var angle = sin(abs(origin.altitude - loc.altitude))

      if origin.altitude > loc.altitude {
        angle = -angle
      }

      inclination = angle
      azimuth = angleFromCoordinate(origin.coordinate, loc.coordinate)
      NSLog("Distance from %@ is %f, angle is %f, azimuth is %f", title, distanceFromOrigin!, angle, azimuth!)
    } else {
      return
    }
  }

  override func didSetTitle() {
    markerView?.didUpdateTitle(self.title)
  }
}