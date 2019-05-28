//
//  ApplicationData.swift
//  CloudKitDash
//
//  Created by Afonso H Sabino on 25/05/19.
//  Copyright © 2019 Afonso H Sabino. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

class ApplicationData {
    
    //MARK: - Property to store the data locally
    
    //Store a reference to the CloudKit's database
    var database: CKDatabase!
    
    //It's the reference to knbow which country has been selected by the user at any given moment
    var selectedCountry: CKRecord.ID!
    
    //Array with the list of the countries already inserted in the database
    var listCountries: [CKRecord] = []
    
    //Array with the list of the cities available for a specific country
    var listCities: [CKRecord] = []
    
    //Reference to the CoreData Context
    var context: NSManagedObjectContext!
    
    init() {
        
        let app = UIApplication.shared
        let appDelegate = app.delegate as! AppDelegate
        context = appDelegate.context
        
        //Get the container from PrivateCloudDatabase
        let container = CKContainer.default()
        database = container.privateCloudDatabase
    }
    
    //MARK: - Model Functions to Insert Data
    
    ///Method to insert a new Country
    func insertCountry(name: String) {
        let text = name.trimmingCharacters(in: .whitespaces)
        
        if text != "" {
            
            //As we know subscriptions require the records to be stored in a custom zone.
            // So we have to create one.
            let zone = CKRecordZone(zoneName: "listPlaces")
            
            //Create a unique value ID for the Countries in a specific custom zone
            let id = CKRecord.ID(recordName: "idcountry-\(UUID())", zoneID: zone.zoneID)
            
            //Create a record object of type Countries
            let record = CKRecord(recordType: "Countries", recordID: id)
            record.setObject(text as NSString, forKey: "countryName")
            
            //Save record in CloudKit server
            database.save(record) { (recordSaved, error) in
                
                if error != nil {
                    print("ERROR: O Registro do País não foi salvo")
                } else {
                    
                    //Add the record in Array listCountries
                    self.listCountries.append(record)
                    
                    //Method to post a notification to tell the views that
                    //they have to update the tables.
                    self.updateInterface()
                }
            }
        }
    }
    
    ///Method to insert a new City
    func insertCity(name: String) {
        let text = name.trimmingCharacters(in: .whitespaces)
        
        if text != "" {
            
            //As we know subscriptions require the records to be stored in a custom zone.
            // So we have to create one.
            let zone = CKRecordZone(zoneName: "listPlaces")
            
            //Create a unique value ID for the City in a specific custom zone
            let id = CKRecord.ID(recordName: "idcity-\(UUID())", zoneID: zone.zoneID)
            
            //Create a record object of type Cities
            let record = CKRecord(recordType: "Cities", recordID: id)
            record.setObject(text as NSString, forKey: "cityName")
            
            //Create a reference to the Country the City belongs to, and an action of type "deleteSelf"
            //"when the record of the country is deleted, this record is deleted as well."
            let reference = CKRecord.Reference(recordID: selectedCountry, action: .deleteSelf)
            record.setObject(reference, forKey: "country")
            
            //We get the URL of an image included in the project called Vancouver.jpg
            let bundle = Bundle.main
            if let fileURL = bundle.url(forResource: "Vancouver", withExtension: "jpg") {
                
                //Create a CKAsset object with it, and assign the object to the record
                //of every city with the key "picture"
                let asset = CKAsset(fileURL: fileURL)
                record.setObject(asset, forKey: "picture")
            }
            
            //Save record in CloudKit server asynchronously
            database.save(record) { (recordSaved, error) in
                
                if error != nil {
                    print("ERROR: O Registro da Cidade não foi salvo")
                } else {
                    
                    //Add the record in Array listCities
                    self.listCities.append(record)
                    
                    //Method to post a notification to tell the views that
                    //they have to update the tables.
                    self.updateInterface()
                }
            }
        }
    }
    
    //MARK: - Model Functions to Read Data
    
    ///Mehtod to read Countries
    func readCountries() {
        
        //Ask the server to only look for Countries
        //TRUEPREDICATE keyword determines that the predicate will always return
        //the value true, so we get back all the records available
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: "Countries", predicate: predicate)
        
        database.perform(query, inZoneWith: nil) { (records, error) in
            
            if error != nil {
                print("ERROR: Registro de Country não encontrado")
            } else if let list = records {
                
                //If there is no error, add the records received to the Array
                self.listCountries = []
                for record in list {
                    self.listCountries.append(record)
                }
                self.updateInterface()
            }
        }
    }
    
    ///Method to read Cities
    func readCities() {
        
        //Getting the list of cities that belong to the country selected by the user
        if selectedCountry != nil {
            let predicate = NSPredicate(format: "country = %@", selectedCountry)
            let query = CKQuery(recordType: "Cities", predicate: predicate)
            database.perform(query, inZoneWith: nil) { (records, error) in
                
                if error != nil {
                    print("ERROR: Registro de City não encontrado")
                } else if let list = records {
                    self.listCities = []
                    for record in list {
                        self.listCities.append(record)
                    }
                    self.updateInterface()
                }
            }
        }
    }
    
    //MARK: - Update Interface
    
    ///The purpose of this method is to tell the rest of the application that new information is available and should be shown to the user.
    func updateInterface() {
        let main = OperationQueue.main
        main.addOperation {
            let center = NotificationCenter.default
            let name = Notification.Name("Update Interface")
            center.post(name: name, object: nil, userInfo: nil)
        }
    }
    
    ///Alert Template for Country and City
    func setAlert(type: String, title: String, style: UIAlertController.Style, message: String?) -> UIAlertController {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancel)
        let action = UIAlertAction(title: "Save", style: .default) { (action) in
            if let fields = alert.textFields {
                let name = fields[0].text!
                
                if type == "Country" {
                    self.insertCountry(name: name)
                } else if type == "City" {
                    self.insertCity(name: name)
                } else {
                    print("Type não indentificado")
                }
            }
        }
        alert.addAction(action)
        alert.addTextField(configurationHandler: nil)
        
        return alert
    }
    
    //MARK: - Contact the CloudKit servers
    //Two methods that are going to contact the CloudKit servers and process the information by Subscription
    
    ///Method to create the subscription and the zone
    func configureDatabase(executeClosure: @escaping () -> Void) {
        let userSettings = UserDefaults.standard
        
        //Check whether subscriptionSaved has been created
        if !userSettings.bool(forKey: "subscriptionSaved") {
            
            //If not we create a new CKDatabaseSubscription
            let newSubscription = CKDatabaseSubscription(subscriptionID: "updatesDatabase")
            
            //Setting the Nofication are going to be sent by the server
            let info = CKSubscription.NotificationInfo()
            info.shouldSendContentAvailable = true
            newSubscription.notificationInfo = info
            
            //The subscription is saved on the server
            database.save(newSubscription) { (subscription, error) in
                
                if error != nil {
                    print("ERROR Creating Subscription")
                } else {
                    
                    //Set TRUE if the operation is successful
                    userSettings.set(true, forKey: "subscriptionSaved")
                }
            }
        }
        
        //Create the custom Zone and check if it was already created
        if !userSettings.bool(forKey: "zoneCreated") {
            
            //Create Zone listPlaces to store our records
            let newZone = CKRecordZone(zoneName: "listPlaces")
            
            //The newZone is saved on the server
            database.save(newZone) { (zone, error) in
                
                if error != nil {
                    print("ERROR Creating Zone")
                } else {
                    
                    //Set TRUE if the operation is successful
                    userSettings.set(true, forKey: "zoneCreated")
                    
                    //We call the closure because we have to be sure that the zone
                    //was created before trying to store any records.
                    executeClosure()
                }
            }
        } else {
            
            //The closure is also called if the zone was already created to make sure
            //that its code is always executed.
            executeClosure()
        }
    }
    
    ///Method to download and process the changes in the database
    func checkUpdates(finishClosure: @escaping (UIBackgroundFetchResult) -> Void) {
        
        //To make sure that the database is configured properly, we call configureDatabase()
        configureDatabase {
            
            //Code to be execute after we make sure that the Zone was created
            let mainQueue = OperationQueue.main
            mainQueue.addOperation {
                self.downloadUpdates(finishClosure: finishClosure)
            }
        }
    }
    
    ///Getting the updates from the server
    func downloadUpdates(finishClosure: @escaping (UIBackgroundFetchResult) -> Void) {
        
        var listRecordsUpdated: [CKRecord] = []
        var listRecordsDeleted: [String:String] = [:]
        
        // 1. Defining the properties we are going to use to store the tokens
        // (one for the database and another for the custom zone)
        
        //For the database Token
        var changeToken: CKServerChangeToken!
        
        //For the our custom Zone
        var changeZoneToken: CKServerChangeToken!
        
        let userSettings = UserDefaults.standard
        
        // 2. Check if there are tokens already stored in the User Defaults Database
        
        //Note: Because the tokens are instances of the CKServerChangeToken class,
        // we can't store their values directly in User Defaults, we first have
        // to convert them into Data structures.
        
        if let data = userSettings.value(forKey: "changeToken") as? Data {
            
            //If there is a token unarchive it...
            if let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data) {
                
                // and store it here.
                changeToken = token
            }
        }
        
        if let data = userSettings.value(forKey: "changeZoneToken") as? Data {
            
            //If there is a token unarchive it...
            if let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data) {
                
                // and store it here.
                changeZoneToken = token
            }
        }
        
        // 3. Configure the operations necessary to get the updates from the server.
        
        //Note: We have to perform two operations on the database, one to download
        // the list of changes available and another to download the actual changes
        // and show them to the user
        
        var zonesIDs: [CKRecordZone.ID] = []
        
        //This Operation requires the previous database token to get only the changes
        // that are not available on the device, so we pass the value of the changeToken property.
        let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)
        
        //Report the zone that changed
        // The closure assigned to this property is executed every time the system
        // finds a zone whose content has changed.
        operation.recordZoneWithIDChangedBlock = { (zoneID) in
            zonesIDs.append(zoneID)
        }
        
        //Report the creation a new database token
        // This closure is executed every time the system decides to perform the operation
        // again to download the changes in separate processes. To make sure that we only
        // receive the changes that we did not process yet, we use this closure to update
        // the changeToken property with the current token.
        operation.changeTokenUpdatedBlock = { (token) in
            changeToken = token
        }
        
        //Report the conclusion of the operation
        // The closure assigned to this property is executed to let the app know that the
        // operation is over, and this is the signal that indicates that we have all the
        // information we need to begin downloading the changes with the second operation.
        
        //Note: This last closure receives three values: the latest database token, a Boolean
        // value that indicates whether there are "more changes" available (by default, the system
        // takes care of fetching all the changes, so we don't need to consider this value),
        // and a CKError structure to report errors
        operation.fetchDatabaseChangesCompletionBlock = { (token, more, error) in
            if error != nil {
                finishClosure(.failed)
                print("ERROR in fetchDatabseChangesComplitionBlock")
                
                
            } else if !zonesIDs.isEmpty {
                
                //If the array is not empty, we have to configure the CKFetchRecordZoneChangesOperation
                // operation to get the changes.
                changeToken = token
                
                //Because in this example we only work with one zone, we read the first element of the
                // zonesIDs array to get the ID of our custom zone and provide a ZoneConfiguration object
                // with the current token stored in the changeZoneToken property.
                let configuration = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
                configuration.previousServerChangeToken = changeZoneToken
                
                let fetchOperation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zonesIDs, configurationsByRecordZoneID: [zonesIDs[0] : configuration])
                
                //The changes are fetched, and the results are reported to the closures assigned to its properties.
                
                //Operation 1: This closure is called every time a new or updated record is received.
                fetchOperation.recordChangedBlock = { (record) in
                    
                    listRecordsUpdated.append(record)
                    
                    //First we have to check if the record is of type Countries or Cities
                    // and store the record in the corresponding array
                    if record.recordType == "Countries" {
                        
                        //We use the firstIndex() method to look for duplicates
                        //If the record already exists in the array, we update its values,
                        // otherwise, we add the record to the list.
                        let index = self.listCountries.firstIndex(where: { (item) -> Bool in
                            return item.recordID == record.recordID
                        })
                        if index != nil {
                            self.listCountries[index!] = record
                        } else {
                            self.listCountries.append(record)
                        }
                        
                    } else if record.recordType == "Cities" {
                        
                        //we first check whether the record contains a reference to a country and
                        //only update or add the record to the array if the reference corresponds
                        //to the country currently selected by the user
                        if let country = record["country"] as? CKRecord.Reference {
                            if country.recordID == self.selectedCountry {
                                
                                //We use the firstIndex() method to look for duplicates.
                                //If the record already exists in the array, we update its values,
                                // otherwise, we add the record to the list.
                                let index = self.listCities.firstIndex(where: { (item) -> Bool in
                                    return item.recordID == record.recordID
                                })
                                if index != nil {
                                    self.listCities[index!] = record
                                } else {
                                    self.listCities.append(record)
                                }
                            }
                        }
                    }
                }
                
                //Operation 2: This closure is called every time the app receives the ID of a deleted
                //record (a record that was deleted from the CloudKit database).
                fetchOperation.recordWithIDWasDeletedBlock = { (recordID, recordType) in
                    
                    listRecordsDeleted[recordID.recordName] = recordType
                    
                    if recordType == "Countries" {
                        let index = self.listCountries.firstIndex(where: { (item) -> Bool in
                            return item.recordID == recordID
                        })
                        if index != nil {
                            self.listCountries.remove(at: index!)
                        }
                    } else if recordType == "Cities" {
                        let index = self.listCities.firstIndex(where: { (item) -> Bool in
                            return item.recordID == recordID
                        })
                        if index != nil {
                            self.listCities.remove(at: index!)
                        }
                    }
                }
                
                //Operation 3: Next two closures are executed when the process completes a cycle
                //Note: Depending on the characteristics of our application, we may need to perform
                // some tasks in these closures
                fetchOperation.recordZoneChangeTokensUpdatedBlock = { (zoneID, token, data) in
                    changeZoneToken = token
                }
                
                //Operation 4: The same above
                fetchOperation.recordZoneFetchCompletionBlock = { (zoneID, token, data, more, error) in
             
                    if error != nil {
                        print("Error in fetchOperation.recordZoneFetchCompletionBlock")
                    } else {
                        changeZoneToken = token
                        
                        //To store the records that were updated in an array called listRecordsUpdated and
                        //the record IDs of the records that were deleted in a dictionary called listRecordsDeleted.
                        
                        //When the fetching of the record zone is finished, we call the methods updateLocalRecords()
                        //and deleteLocalRecords() with these values to perform the corresponding changes in the
                        //persistent store.
                        self.updateLocalRecords(listRecordsUpdated: listRecordsUpdated)
                        self.deleteLocalRecords(listRecordsDeleted: listRecordsDeleted)
                        listRecordsUpdated.removeAll()
                        listRecordsDeleted.removeAll()
                    }
                }
                
                //Operation 5: This closure is called to report that the operation is over.
                fetchOperation.fetchRecordZoneChangesCompletionBlock = { (error) in
                    if error != nil {
                        finishClosure(.failed)
                        print("Error in fetchOperation.fetchRecordZoneChangesCompletionBlock")
                    } else {
                        
                        //If no error is found, we permanently store the current tokens in the User Defaults database
                        if changeToken != nil {
                            
                            //To store the tokens we have to turn them into Data structures and encode them with the archivedData()
                            if let data = try? NSKeyedArchiver.archivedData(withRootObject: changeToken!, requiringSecureCoding: false) {
                                userSettings.set(data, forKey: "changeToken")
                            }
                        }
                        if changeZoneToken != nil {
                            
                            //To store the tokens we have to turn them into Data structures and encode them with the archivedData()
                            if let data = try? NSKeyedArchiver.archivedData(withRootObject: changeZoneToken!, requiringSecureCoding: false) {
                                userSettings.set(data, forKey: "changeZoneToken")
                            }
                        }
                        ///Removida com a implementação do CoreData
//                        self.updateInterface()
                        
                        self.updateLocalReference()
                        
                        //If there are chnages we have to tell the system that new data has been downloaded.
                        finishClosure(.newData)
                    }
                }
                
                // 4. After the definition of each fetchOperation and their properties, we call the add() method
                // of the CKDatabase object to add them to the database.
                self.database.add(fetchOperation)
            } else {
                
                //If there are no changes available
                finishClosure(.noData)
            }
        }
        
        // 5. After the definition of each operation and their properties, we call the add() method
        // of the CKDatabase object to add them to the database.
        database.add(operation)
    }
}

var AppData = ApplicationData()
