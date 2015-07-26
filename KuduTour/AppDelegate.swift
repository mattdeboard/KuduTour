//
//  AppDelegate.swift
//  KuduTour
//
//  Created by Matt DeBoard on 6/10/15.
//  Copyright (c) 2015 Matt DeBoard. All rights reserved.
//
import CoreData
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  // MARK: CoreData stack

  lazy var applicationDocumentsDirectory: NSURL = {
    let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    return urls[urls.count - 1] as! NSURL
  }()

  lazy var managedObjectModel: NSManagedObjectModel = {
    let modelURL = NSBundle.mainBundle().URLForResource("AppState", withExtension: "momd")!
    return NSManagedObjectModel(contentsOfURL: modelURL)!
  }()

  lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
    var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(
      managedObjectModel: self.managedObjectModel)
    let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("AppState.sqlite")
    var error: NSError? = nil
    var failureReason = "There was an error creating or loading the application's saved data."
    let options = [NSMigratePersistentStoresAutomaticallyOption: true,
      NSInferMappingModelAutomaticallyOption: true]
    if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil,
      URL: url, options: nil, error: &error) == nil {
        coordinator = nil
        let dict = NSMutableDictionary()
        dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
        dict[NSLocalizedFailureReasonErrorKey] = failureReason
        dict[NSUnderlyingErrorKey] = error
        error = NSError(domain: "KUDU_APP_ERROR", code: 9999, userInfo: dict as [NSObject : AnyObject])
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        abort()
    }
    return coordinator
  }()

  lazy var managedObjectContext: NSManagedObjectContext? = {
    let coordinator = self.persistentStoreCoordinator

    if coordinator == nil {
      return nil
    }

    var managedObjectContext = NSManagedObjectContext()
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
  }()

  // MARK: Fetched Results Controllers

  func markerFetchedResultsController() -> NSFetchedResultsController? {
    var result: NSFetchedResultsController?
    if let moc = self.managedObjectContext {
      var fetchRequest = NSFetchRequest(entityName: "Marker")
      fetchRequest.sortDescriptors = [NSSortDescriptor(key: "markerID", ascending: true)]
      result = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc,
        sectionNameKeyPath: nil, cacheName: "marker-fetch.cache")
    }
    return result
  }

  func geolocationFetchedResultsController() -> NSFetchedResultsController? {
    var result: NSFetchedResultsController?
    if let moc = self.managedObjectContext {
      var fetchRequest = NSFetchRequest(entityName: "GeoLocation")
      fetchRequest.sortDescriptors = [NSSortDescriptor(key: "geolocationID", ascending: true)]
      result = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc,
        sectionNameKeyPath: nil, cacheName: "geolocation-fetch.cache")
    }
    return result
  }

  // MARK: -
  // MARK: UIApplicationDelegate methods

  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    // Override point for customization after application launch.
    return true
  }

  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }

  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }

  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }


}

