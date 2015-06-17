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
    // LICENSE_KEY is defined in a separate Swift file.
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