//
//  ARKit.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/14/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//

import AVFoundation
import CoreLocation
import Foundation

class ARKit: NSObject {
  func deviceSupportsAR() -> Bool {
    let devices = AVCaptureDevice.devices()
    var supportsVideo = false

    if (devices != nil && devices.count > 0) {
      for device in devices {
        if device.hasMediaType(AVMediaTypeVideo) {
          supportsVideo = true
          break
        }
      }
    }

    return supportsVideo
  }
}