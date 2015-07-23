//
//  ARGeoCoordinateDelegateProtocol.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/21/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//
import CoreLocation
import UIKit

protocol ARGeoCoordinateViewProtocol {
  func didUpdateDistanceFromOrigin(distance: CLLocationDistance) -> Void
  func didUpdateTitle(title: String) -> Void
}