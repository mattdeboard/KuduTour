//
//  NetworkManager.swift
//  KuduTour
//
//  Created by Matt DeBoard on 7/15/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//
import AFNetworking
import Foundation

func networkManager() -> AFHTTPRequestOperationManager {
  let mgr = AFHTTPRequestOperationManager(
    baseURL: NSURL(string: "https://758375ee.ngrok.io")?.URLByAppendingPathComponent("/api/v1"))
  mgr.requestSerializer = AFJSONRequestSerializer()
  mgr.requestSerializer.setValue("Token \(API_TOKEN)", forHTTPHeaderField: "Authorization")
  return mgr
}

func resourcePath(mgr: AFHTTPRequestOperationManager, path: String) -> String {
  return NSURL(string: path, relativeToURL: mgr.baseURL!)!.absoluteString!
}

func networkAvailable() -> Bool {
  let checker = AFNetworkReachabilityManager()
  return checker.reachable
}
