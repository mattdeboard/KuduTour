//
//  KuduViewController.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/10/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//

// Taken from
// http://jamesonquave.com/blog/taking-control-of-the-iphone-camera-in-ios-8-with-swift-part-1/

import AVFoundation
import UIKit

class KuduViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {

  let captureSession = AVCaptureSession()
  let screenWidth = UIScreen.mainScreen().bounds.size.width
  var previewLayer : AVCaptureVideoPreviewLayer?

  // If we find a device we'll store it here for later use
  var captureDevice : AVCaptureDevice?
  var locationManager = CLLocationManager()

  // MARK: Subviews
  var avPreviewView: UIView?
  @IBOutlet weak var someButton: UIButton!
  @IBOutlet weak var buttonLabel: UILabel!

  // MARK: View Lifecycle

  override func viewWillTransitionToSize(size: CGSize,
    withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
      // I do not understand why I have to handle this at all. But since I do, I want to know how to make the transition
      // between portrait and landscape seamless as it is in the camera app. I bet I'm doing something wrong here that
      // I'll have to rip out in six months.
      super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
      coordinator.animateAlongsideTransition({ (context) -> Void in
        if (self.previewLayer?.connection.supportsVideoOrientation)! {
          self.previewLayer?.frame = CGRectMake(0, 0, size.width, size.height)
          self.videoOrientation()
        }
        },
        completion: { (context) -> Void in
      })
  }

  override func viewWillAppear(animated: Bool) {
    self.navigationController?.navigationBarHidden = true
  }

  override func viewWillDisappear(animated: Bool) {
    self.navigationController?.navigationBarHidden = false
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    avPreviewView = self.view.viewWithTag(0)

    // Do any additional setup after loading the view, typically from a nib.
    captureSession.sessionPreset = AVCaptureSessionPresetHigh

    let devices = AVCaptureDevice.devices()

    // Loop through all the capture devices on this phone
    for device in devices {
      // Make sure this particular device supports video
      if (device.hasMediaType(AVMediaTypeVideo)) {
        // Finally check the position and confirm we've got the back camera
        if(device.position == AVCaptureDevicePosition.Back) {
          captureDevice = device as? AVCaptureDevice
          if captureDevice != nil {
            println("Capture device found")
            beginSession()
          }
        }
      }
    }

    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
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

  // MARK: Device operations

  func configureDevice() {
    if let device = captureDevice {
      device.lockForConfiguration(nil)
      device.focusMode = .Locked
      device.unlockForConfiguration()
    }
  }

  func focusTo(value : Float) {
    if let device = captureDevice {
      if(device.lockForConfiguration(nil)) {
        device.setFocusModeLockedWithLensPosition(value, completionHandler: nil)
        device.unlockForConfiguration()
      }
    }
  }

  func beginSession() {
    configureDevice()

    var err : NSError? = nil
    captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))

    if err != nil {
      println("error: \(err?.localizedDescription)")
    }

    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    self.view.layer.addSublayer(previewLayer)
    self.view.layer.addSublayer(buttonLabel.layer)
    self.view.layer.addSublayer(someButton.layer)
    previewLayer?.frame = self.view.bounds
    previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
    videoOrientation()
    captureSession.startRunning()
  }

  // MARK: Utility methods

  func videoOrientation() {
    let previewConn = self.previewLayer?.connection
    let orientation = UIApplication.sharedApplication().statusBarOrientation

    switch orientation {
    case UIInterfaceOrientation.LandscapeLeft:
      previewConn!.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
    case UIInterfaceOrientation.LandscapeRight:
      previewConn!.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
    case UIInterfaceOrientation.Portrait:
      previewConn!.videoOrientation = AVCaptureVideoOrientation.Portrait
    case UIInterfaceOrientation.PortraitUpsideDown:
      previewConn!.videoOrientation = AVCaptureVideoOrientation.PortraitUpsideDown
    default:
      previewConn!.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
    }
  }
}
