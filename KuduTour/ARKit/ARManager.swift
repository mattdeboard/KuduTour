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
let ADJUST_BY: Double = 30.0
let DISTANCE_FILTER = 2.0
let HEADING_FILTER = 1.0
let INTERVAL_UPDATE = 0.75
let SCALE_FACTOR = 1.0
let HEADING_NOT_SET = -1.0
let DEGREE_TO_UPDATE = 1

struct Azimuth {
  var azimuth: Float64
  var isBetweenNorth: Bool
}

class ARManager: NSObject, CLLocationManagerDelegate {
  // MARK: Private properties
  private var latestHeading: Float64?
  private var degreeRange: Float64?
  private var viewAngle: Float64?
  private var prevHeading: Float64?
  private var cameraOrientation: UIDeviceOrientation?

  // MARK: Public properties
  var scaleViewsBasedOnDistance = false
  var rotateViewsBasedOnPerspective = false
  var debugMode = false
  var maxScaleDistance: Float64 = 0.0
  var minScaleFactor: Float64 = SCALE_FACTOR
  var maxRotationAngle: Float64 = M_PI / 6.0
  var centerCoordinate = ARCoordinate()
  var centerLocation = CLLocation()
  var displayView: UIView?
  var parentViewController: UIViewController?
  var captureSession = AVCaptureSession()
  var previewLayer = AVCaptureVideoPreviewLayer()
  var delegate: ARDelegate?
  var debugView = UILabel()
  var coordinates: [ARGeoCoordinate?]?
  var captureDevice : AVCaptureDevice?

  // MARK: Managers
  var motionManager = CMMotionManager()
  var locationManager = CLLocationManager()

  // MARK: Initialization

  convenience init(arView: UIView, parentVC: UIViewController, arDelegate: ARDelegate) {
    self.init()
    delegate = arDelegate
    parentViewController = parentVC
    displayView = arView
    latestHeading = HEADING_NOT_SET
    prevHeading = HEADING_NOT_SET

    degreeRange = arView.frame.size.width.native / ADJUST_BY

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
    startLocationServices()
    startMotionServices()
    centerLocation = CLLocation(latitude: locationManager.location.coordinate.latitude,
      longitude: locationManager.location.coordinate.longitude)
  }

  // MARK: Services init

  func startMotionServices() {
    motionManager.gyroUpdateInterval = 0.1
    motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
      [weak self](data: CMDeviceMotion!, error: NSError!) in

      let rotation = atan2(data.gravity.x, data.gravity.y) - M_PI
      self?.displayView!.transform = CGAffineTransformMakeRotation(CGFloat(rotation))
    }
  }

  func startLocationServices() {
    locationManager.headingFilter = HEADING_FILTER
    locationManager.distanceFilter = DISTANCE_FILTER
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    locationManager.startUpdatingLocation()
    locationManager.startUpdatingHeading()
  }

  func updateCenterCoordinate() {
    var adjustment: Float64

    switch cameraOrientation! {
    case UIDeviceOrientation.LandscapeLeft:
      adjustment = degreesToRadians(270)
    case UIDeviceOrientation.LandscapeRight:
      adjustment = degreesToRadians(90)
    case UIDeviceOrientation.PortraitUpsideDown:
      adjustment = degreesToRadians(180)
    default:
      adjustment = 0
    }

    centerCoordinate.azimuth = latestHeading! - adjustment
    updateLocations()
  }

  func findDeltaOfRadianCenter(centerAzimuth: Float64, pointAzimuth: Float64, isBetweenNorth: Bool) -> Azimuth {

    var center = centerAzimuth

    if centerAzimuth < 0.0 {
      center = M_2PI + centerAzimuth
    } else if centerAzimuth > M_2PI {
      center = centerAzimuth - M_2PI
    }

    let clockwiseRadians = degreesToRadians(degreeRange! as Float64)
    let counterClockwiseRadians = degreesToRadians(360 - degreeRange!)
    var deltaAzimuth = abs(pointAzimuth - centerAzimuth)
    var betweenNorth = false

    if (centerAzimuth < clockwiseRadians && pointAzimuth > counterClockwiseRadians) {
      deltaAzimuth = centerAzimuth + (M_2PI - pointAzimuth)
      betweenNorth = true
    } else if (pointAzimuth < clockwiseRadians && centerAzimuth > counterClockwiseRadians) {
      deltaAzimuth = pointAzimuth + (M_2PI - centerAzimuth)
      betweenNorth = true
    }

    return Azimuth(azimuth: deltaAzimuth, isBetweenNorth: betweenNorth)
  }

  func shouldDisplayCoordinate(coordinate: ARCoordinate) -> Bool {
    let currentAzimuth = centerCoordinate.azimuth!
    let pointAzimuth = coordinate.azimuth!
    let deltaAzimuth = findDeltaOfRadianCenter(currentAzimuth, pointAzimuth: pointAzimuth, isBetweenNorth: false)

    if deltaAzimuth.azimuth <= degreesToRadians(pointAzimuth) {
      return true
    }
    return deltaAzimuth.isBetweenNorth
  }

  func updateLocations() {
    for item in coordinates! {
      let markerView = item!.displayView!
      if shouldDisplayCoordinate(item!) {
        let loc = pointForCoordinate(item!)
        var scaleFactor = SCALE_FACTOR

        if scaleViewsBasedOnDistance {
          let rDist = item?.radialDistance
          scaleFactor = scaleFactor - minScaleFactor * (rDist! / maxScaleDistance)
        }

        let cgFloatScaleFactor = CGFloat(scaleFactor)
        let width = markerView.bounds.size.width.native * scaleFactor
        let height = markerView.bounds.size.height.native * scaleFactor
        markerView.frame = CGRectMake(CGFloat(loc.x.native - width / 2.0), loc.y, CGFloat(width), CGFloat(height))
        markerView.setNeedsDisplay()

        var transform = CATransform3DIdentity

        if scaleViewsBasedOnDistance {
          transform = CATransform3DScale(transform, cgFloatScaleFactor, cgFloatScaleFactor, cgFloatScaleFactor)
        }

        if rotateViewsBasedOnPerspective {
          transform.m34 = 1.0 / 300.0
        }

        markerView.layer.transform = transform

        if markerView.superview != nil {
          displayView?.insertSubview(markerView, atIndex: 1)
        }
      } else if (markerView.superview != nil) {
          markerView.removeFromSuperview()
      }
    }
  }

  func pointForCoordinate(coordinate: ARCoordinate) -> CGPoint {
    var point = CGPoint()
    let bounds = displayView?.bounds
    let currentAzimuth = centerCoordinate.azimuth!
    let pointAzimuth = coordinate.azimuth!
    let azimuth = findDeltaOfRadianCenter(currentAzimuth, pointAzimuth: pointAzimuth, isBetweenNorth: false)
    let deltaAzimuth = azimuth.azimuth
    let halfWidth = bounds!.size.width / 2
    let xAdjust = deltaAzimuth / degreesToRadians(1)

    if (pointAzimuth > currentAzimuth && !azimuth.isBetweenNorth) ||
      (currentAzimuth > degreesToRadians(degreeRange!) && pointAzimuth < degreesToRadians(degreeRange!)) {
      point.x = (bounds!.size.width / 2) + CGFloat(deltaAzimuth / degreesToRadians(1) * ADJUST_BY)
    } else {
      point.x = (bounds!.size.width / 2) - CGFloat((deltaAzimuth / degreesToRadians(1)) * ADJUST_BY)
    }

    point.y = (bounds!.size.height / 2)
    return point
  }

  func currentDeviceOrientation() -> CMAttitude? {
    return motionManager.deviceMotion.attitude
  }

  // MARK: CLLocationManagerDelegate methods

  func locationManagerShouldDisplayHeadingCalibration(manager: CLLocationManager!) -> Bool {
    return true
  }

  func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!,
    fromLocation oldLocation: CLLocation!) {
    centerLocation = newLocation
    delegate?.didUpdateLocation(newLocation)
  }

  // MARK: Camera Setup & Config

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
    captureSession.startRunning()
  }
}