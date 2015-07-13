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
    avPreviewView!.layer.addSublayer(previewLayer)
    avPreviewView!.layer.addSublayer(buttonLabel.layer)
    avPreviewView!.layer.addSublayer(someButton.layer)
    previewLayer?.frame = avPreviewView!.layer.frame

    captureSession.startRunning()
  }
}
