//
//  AppDelegate.swift
//  CloudKitDash
//
//  Created by Afonso H Sabino on 25/05/19.
//  Copyright © 2019 Afonso H Sabino. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var container: NSPersistentContainer!
    var context: NSManagedObjectContext!


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /*
        Note: Subscriptions only report changes in customs zones.
         Therefore, if we want to receive notifications, besidescreating the
         subscription we also have to create a record zone and store all our
         records in it. This is why, the first thing we do when the application
         is launched, is to store two Boolean values in the User Defaults database
         called "subscriptionSaved" and "zoneCreated". These values will be used
         later to know whether or not we have already created the subscription and
         the custom zone.
        */
        let userSettings = UserDefaults.standard
        let values = ["subscriptionSaved" : false, "zoneCreated" : false]
        userSettings.register(defaults: values)
        
        //Setting CoreData's container and context
        container = NSPersistentContainer(name: "places")
        container.loadPersistentStores { (storeDescription, error) in
            if error != nil {
                print("Error loading data")
            } else {
                self.context = self.container.viewContext
            }
        }
        
        //Register the application with icloud servers
        application.registerForRemoteNotifications()
        
        AppData.configureDatabase {}
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        //Check whether the notification received is of type CKDatabaseNotification, sent by a CloudKit server,
        //creating a CKNotification
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) as? CKDatabaseNotification
        
        /*
         Note: We call the closure to tell the system that the process is over,
         but because the operations are performed asynchronously, we can't do it
         until they are finished. This way we send a closure to the method we use
         to download the new information which sole purpose is to execute the
         completionHandler closure with the value "result" returned by the operations.
         */
        
        if notification != nil {
            AppData.checkUpdates { (result) in
                let mainQueue = OperationQueue.main
                mainQueue.addOperation {
                    //Tell to excute closure only with process is over.
                    //Por isso usamos o result na sua execução.
                    completionHandler(result)
                }
            }
        }
    }
}

