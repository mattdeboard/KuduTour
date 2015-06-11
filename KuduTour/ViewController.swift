//
//  ViewController.swift
//  KuduTour
//
//  Created by Matt DeBoard on 6/10/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//

import AVFoundation
import UIKit
import CoreMotion


let LICENSE_KEY = "txf3/M8836mURJELv+UTWUMezy3KwcdMl6hm5UOqVKn8BdlPWm5GZ5pujnQuEkHFE5icA63D6vt03XuHCCAO0wL3MrUgcn9+d1iLPbP3IWJjRCywS8RczZcBSSZ90gNKTOJ2UrZIAn4vLEH2ZldwnYVqJf9u0FKdLgfi2w+kQDFTYWx0ZWRfX6NdXu+DPz0ePH8YN1TpLGmYyUhVXbc7kAIbD1utIdhocgR+HBbe21KJvpxKtdpIO6Y5ZQJ2xuK7eoAeYSJr/4zvrYf2/dFBvBoWzJ8OUhvu25P3pqj2PavJabMd5EIN+a3nQ8ooDyH1FfMEnSBMhQloPGk0fmEJzcvT8iEdH1M0Uzw+LbqNFgatZBhY5GzffRifi+5wkYJZsGkzBlNN5mcydNd2lbpbl+3Uv/CJdDUVPsJFZPgt7yXirIaxS98k6mevELfxTnIQKjfzFgjJQ250mKeIJ4plwuEbH/q9ANzaCznIWkft0YrprAWSxSjuST0dVAj1xbMTJHU9QCEtBQEPwXpAH4EvM+RDUFFuT7P/aWChLFG4Do0q1C++bVqE14EZHlyhQtS6V/kOwJmE3XiLlIT1XNM45OwvRCqws7N5Zj7F2HhOjLssb+itPPyDQVL9SW42rrmNXFgfrgAWjwB1yE3/0URJY9p9N/ewcX+zQGwJI6v3mwE="


class ViewController: UIViewController, WTArchitectViewDelegate, WTArchitectViewDebugDelegate {

  var architectView: WTArchitectView?
  var architectWorldNavigation: WTNavigation?

  override func viewDidLoad() {
    super.viewDidLoad()
    var error: NSError? = nil
    if !WTArchitectView.isDeviceSupportedForRequiredFeatures(WTFeatures._Geo, error: &error)
    {
      NSLog("This device is not supported! '%@'", error!)
      return
    }
    if (architectView == nil) {
      let moMgr: CMMotionManager? = nil
      self.architectView = WTArchitectView(frame: CGRectZero, motionManager: moMgr)
    }
    self.architectView!.delegate = self
    self.architectView!.debugDelegate = self
    self.architectView!.setLicenseKey(LICENSE_KEY)
    view.addSubview(architectView!)
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func architectView(architectView: WTArchitectView!, didFailToLoadArchitectWorldNavigation navigation: WTNavigation!, withError error: NSError!) {
    /* nil */
  }

  func architectView(architectView: WTArchitectView!, didFinishLoadArchitectWorldNavigation navigation: WTNavigation!) {
    // nil
  }

  func architectView(architectView: WTArchitectView!, didEncounterInternalWarning warning: WTWarning!) {
    // nil
  }

  func architectView(architectView: WTArchitectView!, didEncounterInternalError error: NSError!) {
    NSLog("WTArchitectView encountered an internal error '%@'", error)
  }
}