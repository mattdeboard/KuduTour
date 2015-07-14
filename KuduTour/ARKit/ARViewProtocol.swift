//
//  ARViewProtocol.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/14/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//
import CoreLocation
import UIKit

protocol ARMarkerDelegate {
  func didTapMarker(coordinate: ARGeoCoordinate) -> Void
}

protocol ARDelegate {
  func didUpdateHeading(newHeading: CLHeading) -> Void
  func didUpdateLocation(newLocation: CLLocation) -> Void
  func didUpdateOrientation(newOrientation: UIDeviceOrientation) -> Void
}