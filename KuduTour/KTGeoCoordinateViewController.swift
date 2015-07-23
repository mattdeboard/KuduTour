//
//  KTGeoCoordinateViewController.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/21/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//

import CoreLocation
import UIKit

class KTGeoCoordinateViewController: UIViewController, ARGeoCoordinateViewProtocol {
  @IBOutlet weak var markerTitle: UILabel!
  @IBOutlet weak var markerDistance: UILabel!

  func didUpdateDistanceFromOrigin(distance: CLLocationDistance) {
    if let title = markerTitle {
      title.text = distance.description
    }
  }

  func didUpdateTitle(title: String) {
    if let dist = markerDistance {
      dist.text = title
    }
  }
}