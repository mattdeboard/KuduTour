//
//  KTFormViewController.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/13/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//
import UIKit
import SwiftForms

class KTFormViewController: FormViewController, CLLocationManagerDelegate {
  var formDescriptor: FormDescriptor?
  var locationManager = CLLocationManager()
  private var latitude: CLLocationDegrees?
  private var longitude: CLLocationDegrees?
  private var altitude: CLLocationDegrees?

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
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
  }


  // MARK: CLLocationManagerDelegate methods

  func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
    println("Error while updating location " + error.localizedDescription)
  }

  func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
    latitude = manager.location.coordinate.latitude
    longitude = manager.location.coordinate.longitude
    altitude = manager.location.altitude
    println(latitude!)
  }

  // MARK: Actions

  func submit(_: UIBarButtonItem!) {
    var message : [String: AnyObject] = [
      "latitude": "\(latitude!)",
      "longitude": "\(longitude!)",
      "altitude": "\(altitude!)"
    ]

    for (key, val) in self.form.formValues() {
      message[key as! String] = val
    }

    let alert: UIAlertView = UIAlertView(title: "Form output", message: message.description, delegate: nil,
      cancelButtonTitle: "OK")
    alert.show()
  }
}