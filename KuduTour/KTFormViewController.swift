//
//  KTFormViewController.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/13/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//
import AFNetworking
import CoreLocation
import SwiftForms
import UIKit

class KTFormViewController: FormViewController, CLLocationManagerDelegate {
  var formDescriptor: FormDescriptor?
  var locationManager = CLLocationManager()
  var netManager = networkManager()
  var arManager: ARManager?

  private var latitude: CLLocationDegrees? {
    if let coord = COORDINATES {
      return coord.latitude
    }
    return nil
  }

  private var longitude: CLLocationDegrees? {
    if let coord = COORDINATES {
      return coord.longitude
    }
    return nil
  }

  private var altitude: CLLocationDegrees? {
    return ALTITUDE
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.initForm()
  }

  // MARK: Private interface

  func initForm() {
    formDescriptor = FormDescriptor()
    formDescriptor!.title = "Create POI"
    let section1 = FormSectionDescriptor()
    var row: FormRowDescriptor! = FormRowDescriptor(tag: "title", rowType: .Text, title: "Title",
      placeholder: "POI Title")
    row.configuration[FormRowDescriptor.Configuration.CellConfiguration] = [
      "textField.placeholder" : "Sample POI Title",
      "textField.textAlignment" : NSTextAlignment.Center.rawValue
    ]
    section1.addRow(row)

    row = FormRowDescriptor(tag: "description", rowType: .MultilineText, title: "Description",
      placeholder: "Long Description of POI")
    row.configuration[FormRowDescriptor.Configuration.CellConfiguration] = [
      "textField.textAlignment" : NSTextAlignment.Center.rawValue
    ]
    section1.addRow(row)
    
    formDescriptor!.sections = [section1]
    self.form = formDescriptor
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: .Plain, target: self, action: "submit:")
  }

  func clearForm() {
    for section in form.sections {
      for row in section.rows {
        (row as FormRowDescriptor).value = ""
      }
    }
  }

  // MARK: Actions

  func submit(_: UIBarButtonItem!) {

    var message: [String: AnyObject] = [
      "geolocation": [
        "lat": "\(latitude!)",
        "lon": "\(longitude!)",
        "altitude": "\(altitude!)"
      ]
    ]

    for (key, val) in form.formValues() {
      message[key as! String] = val
    }

    netManager.POST(resourcePath(netManager, "markers/"),
      parameters: message,
      success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
        self.clearForm()
        let alert: UIAlertView = UIAlertView(title: "POI Created!",
          message: "Your Point of Interest marker was created successfully!",
          delegate: nil, cancelButtonTitle: "OK")
        alert.show()
      },
      failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
        let errMsg = "Your marker was not created: \(error.localizedDescription)"
        let alert: UIAlertView = UIAlertView(title: "Error!",
          message: errMsg,
          delegate: nil, cancelButtonTitle: "OK")
        alert.show()
      }
    )
  }
}