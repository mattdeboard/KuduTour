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

func dictionaryOfNames(arr:UIView...) -> Dictionary<String,UIView> {
  var d = Dictionary<String,UIView>()
  for (ix,v) in enumerate(arr) {
    d["v\(ix+1)"] = v
  }
  return d
}

class ViewController: UIViewController, WTArchitectViewDelegate, WTArchitectViewDebugDelegate {

  var architectView: WTArchitectView?
  var architectWorldNavigation: WTNavigation?

  override func viewDidLoad() {
    super.viewDidLoad()
    var error: NSError? = nil
    if !WTArchitectView.isDeviceSupportedForRequiredFeatures(WTFeatures._Geo | WTFeatures._2DTracking, error: &error)
    {
      NSLog("This device is not supported! '%@'", error!)
      return
    }
    let moMgr: CMMotionManager? = nil
    architectView = WTArchitectView(frame: CGRectZero, motionManager: moMgr)
    architectView!.delegate = self
    architectView!.debugDelegate = self
    architectView!.setLicenseKey(LICENSE_KEY)

    let indexURL = NSURL(scheme: "http", host: "9d8062b3.ngrok.io", path: "/")
    self.architectWorldNavigation = architectView!.loadArchitectWorldFromURL(indexURL, withRequiredFeatures: WTFeatures._2DTracking)

    NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue:NSOperationQueue.mainQueue()) { _ in
      println((self.architectWorldNavigation?.wasInterrupted)!)
      if ((self.architectWorldNavigation?.wasInterrupted)! == true) {
        self.architectView?.reloadArchitectWorld()
      }
      self.startWikitudeSDKRendering()
    }

    NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillResignActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) { _ in
      self.stopWikitudeSDKRendering()
    }

    self.view.addSubview(self.architectView!)
    architectView?.setTranslatesAutoresizingMaskIntoConstraints(false)

    let views = [
      "architectView": architectView!,
      "architectWorldNavigation": architectWorldNavigation!
    ]

    self.view.addConstraints(
      NSLayoutConstraint.constraintsWithVisualFormat("|[architectView]|", options: nil, metrics: nil, views: views)
    )
    self.view.addConstraints(
      NSLayoutConstraint.constraintsWithVisualFormat("V:|[architectView]|", options: nil, metrics: nil, views: views)
    )

  }

  private func startWikitudeSDKRendering() {
    if !((self.architectView?.isRunning) != nil) {
      self.architectView?.start(
        { (config: WTStartupConfiguration?) -> Void in return },
        completion: { (completed, err) in return })
    }
  }

  private func stopWikitudeSDKRendering() {
    if ((self.architectView?.isRunning) != nil) {
      self.architectView!.stop()
    }
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    self.startWikitudeSDKRendering()
  }

  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    self.stopWikitudeSDKRendering()
  }


  // MARK: View rotation

  override func shouldAutorotate() -> Bool {
    return true
  }

  override func supportedInterfaceOrientations() -> Int {
    return Int(UIInterfaceOrientationMask.All.rawValue)
  }

  override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
    self.architectView?.setShouldRotate(true, toInterfaceOrientation: toInterfaceOrientation)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func architectView(architectView: WTArchitectView!, didFailToLoadArchitectWorldNavigation navigation: WTNavigation!,
    withError error: NSError!) {
      NSLog("Failed to load architecture world navigation: '%@'", error)
      NSLog("AWN: '%@'", navigation)
  }

  func architectView(architectView: WTArchitectView!, didFinishLoadArchitectWorldNavigation navigation: WTNavigation!) {
    NSLog("Good Things Happened")
  }

  func architectView(architectView: WTArchitectView!, didEncounterInternalWarning warning: WTWarning!) {
    NSLog("Bad Things happened")
  }

  func architectView(architectView: WTArchitectView!, didEncounterInternalError error: NSError!) {
    NSLog("WTArchitectView encountered an internal error '%@'", error)
  }
}