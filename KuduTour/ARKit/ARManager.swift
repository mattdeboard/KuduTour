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

func magnitudeFromAttitude(attitude: CMAttitude) -> Double {
  return sqrt(pow(attitude.roll, 2) + pow(attitude.yaw, 2) + pow(attitude.pitch, 2))
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

  var parentViewController: UIViewController?
  var captureSession = AVCaptureSession()
  var delegate: ARDelegate?
  var coordinates: [ARGeoCoordinate?] = []
  var captureDevice: AVCaptureDevice?

  // MARK: Managers
  var motionManager = CMMotionManager()
  var locationManager = CLLocationManager()
  var markerManager = KTPOIMarkerManager()

  // MARK: Subviews/Sublayers
  var displayView: UIView?
  var auxViews: [UIView?]?
  var debugView = UILabel()
  var previewLayer = AVCaptureVideoPreviewLayer()

  // MARK: Initialization
  var initialAttitude: CMAttitude?

  convenience init(arView: UIView, parentVC: UIViewController, arDelegate: ARDelegate, auxViewArr: [UIView?] = []) {
    self.init()
    delegate = arDelegate
    parentViewController = parentVC
    displayView = arView
    auxViews = auxViewArr
    latestHeading = HEADING_NOT_SET
    prevHeading = HEADING_NOT_SET
    degreeRange = arView.frame.size.width.native / ADJUST_BY
    captureSession.sessionPreset = AVCaptureSessionPresetHigh

    NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateCoordinates",
      name: markerManager.fetchNotification.name, object: nil)
    markerManager.fetchMarkers(delegate as! KTViewController)

    if networkAvailable() {
      startAVCaptureSession()
      startLocationServices()
    }
    startMotionServices()
  }

  func updateCoordinates() {
    coordinates = markerManager.markers
  }

  // MARK: Services init

  func startMotionServices() {
    motionManager.gyroUpdateInterval = 0.1
    motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
      (data: CMDeviceMotion!, error: NSError!) in
      if self.initialAttitude == nil {
        self.initialAttitude = data.attitude
        return
      }
      self.updateCenterCoordinate()
      // translate the attitude
      data.attitude.multiplyByInverseOfAttitude(self.initialAttitude)

      // calculate magnitude of the change from our initial attitude
      let magnitude = magnitudeFromAttitude(data.attitude) ?? 0

//      if magnitude >= 0.8 {
//        println("Initial Magnitude: \(magnitudeFromAttitude(self.initialAttitude!))")
//        println("Current Magnitude: \(magnitude)")
//      }
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
    centerLocation = CLLocation(latitude: locationManager.location.coordinate.latitude,
      longitude: locationManager.location.coordinate.longitude)

  }

  func startAVCaptureSession() {
    let devices = AVCaptureDevice.devices()

    // Loop through all the capture devices on this phone
    for device in devices {
      // Make sure this particular device supports video
      if (device.hasMediaType(AVMediaTypeVideo)) {
        // Finally check the position and confirm we've got the back camera
        if(device.position == AVCaptureDevicePosition.Back) {
          captureDevice = device as? AVCaptureDevice
          if captureDevice != nil {
            beginSession()
          }
        }
      }
    }
  }

  // MARK: Coordinate jiggeration

  func updateCenterCoordinate() {
    var adjustment: Float64

    if let orientation = cameraOrientation {
      switch orientation {
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
    }
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
    if centerCoordinate.azimuth == nil {
      return false
    }
    let currentAzimuth = centerCoordinate.azimuth!
    let pointAzimuth = coordinate.azimuth!
    let deltaAzimuth = findDeltaOfRadianCenter(currentAzimuth, pointAzimuth: pointAzimuth, isBetweenNorth: false)

    if deltaAzimuth.azimuth <= degreesToRadians(pointAzimuth) {
      return true
    }
    return deltaAzimuth.isBetweenNorth
  }

  func updateLocations() {
    for item in coordinates {
      if let markerView = (item!.markerView as? UIViewController)?.view {
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
  }

  func pointForCoordinate(coordinate: ARCoordinate) -> CGPoint {
    var point = CGPoint()
    let bounds = displayView?.bounds
    let currentAzimuth = centerCoordinate.azimuth!
    let pointAzimuth = coordinate.azimuth!
    let azimuth: Azimuth = findDeltaOfRadianCenter(currentAzimuth, pointAzimuth: pointAzimuth, isBetweenNorth: false)
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

  func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!) {
    centerCoordinate.azimuth = manager.heading.magneticHeading
  }

  func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!,
    fromLocation oldLocation: CLLocation!) {
      centerLocation = newLocation

      for geoloc in coordinates {
        geoloc?.calibrateUsingOrigin(centerLocation)
      }

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

  func beginSession() {
    println("Capture device found")
    configureDevice()

    var err : NSError? = nil
    captureSession.addInput(AVCaptureDeviceInput(device: captureDevice, error: &err))

    if err != nil {
      println("error: \(err?.localizedDescription)")
    }

    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    displayView!.layer.addSublayer(previewLayer)

    for v in auxViews! {
      displayView!.layer.addSublayer(v?.layer)
    }
    
    previewLayer?.frame = displayView!.bounds
    previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
    videoOrientation()
    captureSession.startRunning()
  }
}