//
//  ARCoordinate.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/14/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//

import Foundation

func degreesToRadians(val: Float64) -> Float64 {
  return M_PI * val / 180.0
}

func radiansToDegrees(val: Float64) -> Float64 {
  return val * (180.0/M_PI)
}

class ARCoordinate {
  var radialDistance: Float64?
  var inclination: Float64?
  var azimuth: Float64?
  var title: String?
  var subtitle: String?

  class func coordinateWithRadialDistance(newRadialDistance: Float64, newInclination: Float64,
    newAzimuth: Float64) -> ARCoordinate {
      let newCoordinate = ARCoordinate()
      newCoordinate.radialDistance = newRadialDistance
      newCoordinate.inclination = newInclination
      newCoordinate.azimuth = newAzimuth
      newCoordinate.title = ""
      return newCoordinate
  }

  func hash() -> Int {
    return (title!.hash ^ subtitle!.hash) + (Int)(radialDistance! + inclination! + azimuth!)
  }

  func isEqualToCoordinate(otherCoordinate: ARCoordinate) -> Bool {
    if otherCoordinate === self { return true }

    var equal = radialDistance == otherCoordinate.radialDistance
    equal = equal && inclination == otherCoordinate.inclination
    equal = equal && azimuth == otherCoordinate.azimuth
    equal = equal && title == otherCoordinate.title
    return equal
  }

  func description() -> String {
    return String(format: "%@ r: %.3fm φ: %.3f° θ: %.3f°", title!, radialDistance!, radiansToDegrees(azimuth!), radiansToDegrees(inclination!))
  }
}