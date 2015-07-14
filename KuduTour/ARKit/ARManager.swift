//
//  ARManager.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/14/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//
import AVFoundation
import CoreLocation
import CoreMotion
import UIKit

let kFilteringFactor = 0.05
let M_2PI = 2.0 * M_PI
let BOX_WIDTH = 150
let BOX_HEIGHT = 100
let BOX_GAP = 10
let ADJUST_BY: CGFloat = 30.0
let DISTANCE_FILTER = 2.0
let HEADING_FILTER = 1.0
let INTERVAL_UPDATE = 0.75
let SCALE_FACTOR = 1.0
let HEADING_NOT_SET = -1.0
let DEGREE_TO_UPDATE = 1

class ARController: CMMotionManager, CLLocationManagerDelegate {
  // MARK: Private properties
  private var latestHeading: CGFloat?
  private var degreeRange: CGFloat?
  private var viewAngle: CGFloat?
  private var prevHeading: CGFloat?
  private var cameraOrientation: Int?

  // MARK: Public properties
  var scaleViewsBasedOnDistance = false
  var rotateViewsBasedOnPerspective = false
  var debugMode = false
  var maxScaleDistance: Float64 = 0.0
  var minScaleFactor: Float64 = 1.0
  var maxRotationAngle: Float64 = M_PI / 6.0
  var locationManager = CLLocationManager()
  var centerCoordinate = ARCoordinate()
  var centerLocation = CLLocation()
  var displayView: UIView?
  var parentViewController: UIViewController?
  var captureSession = AVCaptureSession()
  var previewLayer = AVCaptureVideoPreviewLayer()
  var delegate: ARDelegate?
  var debugView = UILabel()
  var coordinates: NSMutableArray = []
  var captureDevice : AVCaptureDevice?

  convenience init(arView: UIView, parentVC: UIViewController, arDelegate: ARDelegate) {
    self.init()
    delegate = arDelegate
    parentViewController = parentVC
    degreeRange = arView.frame.size.width / ADJUST_BY
  }

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
    displayView!.layer.addSublayer(previewLayer)
    previewLayer?.frame = displayView!.bounds
    previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
    videoOrientation()
    captureSession.startRunning()
  }

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