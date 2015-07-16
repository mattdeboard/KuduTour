//
//  KuduViewController.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/10/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//

import AVFoundation
import CoreLocation
import UIKit

class KTViewController: UIViewController, ARDelegate {

  let screenWidth = UIScreen.mainScreen().bounds.size.width
  var previewLayer : AVCaptureVideoPreviewLayer?
  var arManager: ARManager?

  // If we find a device we'll store it here for later use
  var captureDevice : AVCaptureDevice?

  // MARK: Subviews
  
  @IBOutlet weak var someButton: UIButton!
  @IBOutlet weak var buttonLabel: UILabel!

  // MARK: View Lifecycle

  override func viewWillAppear(animated: Bool) {
    self.navigationController?.navigationBarHidden = true
  }

  override func viewWillDisappear(animated: Bool) {
    self.navigationController?.navigationBarHidden = false
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    arManager = ARManager(arView: view!, parentVC: self, arDelegate: self)
  }

  override func viewWillTransitionToSize(size: CGSize,
    withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
      // I do not understand why I have to handle this at all. But since I do, I want to know how to make the transition
      // between portrait and landscape seamless as it is in the camera app. I bet I'm doing something wrong here that
      // I'll have to rip out in six months.
      super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
      coordinator.animateAlongsideTransition({ (context) -> Void in
        if (self.arManager!.previewLayer?.connection.supportsVideoOrientation)! {
          self.arManager!.previewLayer?.frame = CGRectMake(0, 0, size.width, size.height)
          self.arManager!.videoOrientation()
        }
        },
        completion: { (context) -> Void in
      })
  }
  // MARK: Touch handlers

  override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    var anyTouch = touches.first as! UITouch
    var touchPercent = anyTouch.locationInView(self.view).x / screenWidth
    focusTo(Float(touchPercent))
  }

  override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
    var anyTouch = touches.first as! UITouch
    var touchPercent = anyTouch.locationInView(self.view).x / screenWidth
    focusTo(Float(touchPercent))
  }


  func focusTo(value : Float) {
    if let device = captureDevice {
      if(device.lockForConfiguration(nil)) {
        device.setFocusModeLockedWithLensPosition(value, completionHandler: nil)
        device.unlockForConfiguration()
      }
    }
  }

  // MARK: ARDelegate protocol methods

  func didUpdateHeading(newHeading: CLHeading) {
    println("New Heading: \(newHeading)")
  }

  func didUpdateLocation(newLocation: CLLocation) {
    // println("New Location: \(newLocation)")
  }

  func didUpdateOrientation(newOrientation: UIDeviceOrientation) {
    println("New Orientation: \(newOrientation)")
  }
}
