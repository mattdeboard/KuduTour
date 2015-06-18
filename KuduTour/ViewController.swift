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

class ViewController: UIViewController, WTArchitectViewDelegate {

  @IBOutlet var architectView: WTArchitectView?
  var architectWorldNavigation: WTNavigation?

  override func viewDidLoad() {
    super.viewDidLoad()

    var error: NSError? = nil
    if !WTArchitectView.isDeviceSupportedForRequiredFeatures(WTFeatures._Geo | WTFeatures._2DTracking, error: &error) {
      NSLog("This device is not supported! '%@'", error!)
      return
    }

    self.architectView?.delegate = self
    // LICENSE_KEY is defined in a separate Swift file.
    self.architectView?.setLicenseKey(LICENSE_KEY)

    let indexURL = NSURL(scheme: "http", host: "9d8062b3.ngrok.io", path: "/")
    self.architectWorldNavigation = architectView!.loadArchitectWorldFromURL(indexURL, withRequiredFeatures: WTFeatures._2DTracking)

    NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue:NSOperationQueue.mainQueue()) { _ in
      if ((self.architectWorldNavigation?.wasInterrupted)! == true) {
        self.architectView?.reloadArchitectWorld()
      }
      self.startWikitudeSDKRendering()
    }

    NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationWillResignActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) { _ in
      self.stopWikitudeSDKRendering()
    }
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    self.architectView?.isRunning.boolValue
    self.startWikitudeSDKRendering()
  }

  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    self.stopWikitudeSDKRendering()
  }

  // MARK: Rendering cycle

  private func startWikitudeSDKRendering() {
    if !(self.architectView?.isRunning)! {
      self.architectView?.start(
        { (config: WTStartupConfiguration?) in },
        completion: { (completed, err) in return })
    }
  }

  private func stopWikitudeSDKRendering() {
    if (self.architectView?.isRunning)! {
      self.architectView!.stop()
    }
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

  // MARK: Delegate methods

  func architectView(architectView: WTArchitectView!, didFailToLoadArchitectWorldNavigation navigation: WTNavigation!,
    withError error: NSError!) {
      NSLog("Failed to load architecture world navigation: '%@'", error)
      NSLog("AWN: '%@'", navigation)
  }

  func architectView(architectView: WTArchitectView!, didFinishLoadArchitectWorldNavigation navigation: WTNavigation!) {
    NSLog("Finished loading ArchitectWorldNavigation: '%@'", navigation)
  }

  func architectView(architectView: WTArchitectView!, didEncounterInternalWarning warning: WTWarning!) {
    NSLog("Encountered Warning: '%@'", warning)
  }

  func architectView(architectView: WTArchitectView!, didEncounterInternalError error: NSError!) {
    NSLog("WTArchitectView encountered an internal error '%@'", error)
  }
}