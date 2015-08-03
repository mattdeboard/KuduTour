//
//  NetworkManager.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/15/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//
import AFNetworking
import Foundation

let reacher = ReachabilityManager()

func networkManager() -> AFHTTPRequestOperationManager {
  let mgr = AFHTTPRequestOperationManager(
    baseURL: NSURL(string: "https://eb31ba9f.ngrok.io")?.URLByAppendingPathComponent("/api/v1"))
  mgr.requestSerializer = AFJSONRequestSerializer()
  mgr.requestSerializer.setValue("Token \(API_TOKEN)", forHTTPHeaderField: "Authorization")
  return mgr
}

func resourcePath(mgr: AFHTTPRequestOperationManager, path: String) -> String {
  return NSURL(string: path, relativeToURL: mgr.baseURL!)!.absoluteString!
}

func networkAvailable() -> Bool {
  let avail = reacher.networkAvailable()
  println(avail)
  return avail
}

class ReachabilityManager: NSObject {
  private var reachable: Bool = false

  override init() {
    super.init()
    AFNetworkReachabilityManager.sharedManager().startMonitoring()
    AFNetworkReachabilityManager.sharedManager().setReachabilityStatusChangeBlock {
      (status: AFNetworkReachabilityStatus) in

      switch status {
      case AFNetworkReachabilityStatus.Unknown,
      AFNetworkReachabilityStatus.ReachableViaWWAN,
      AFNetworkReachabilityStatus.ReachableViaWiFi:
        self.reachable = true
        NSNotificationCenter.defaultCenter().postNotificationName("networkAvailable", object: nil)
        break;
      case AFNetworkReachabilityStatus.NotReachable:
        self.reachable = false
        break;
      default:
        break;
      }
    }
  }

  func networkAvailable() -> Bool {
    return reachable
  }

  deinit {
    AFNetworkReachabilityManager.sharedManager().stopMonitoring()
  }
}