//
//  ApplicationData.swift
//  CloudKitDash
//
//  Created by Afonso H Sabino on 25/05/19.
//  Copyright © 2019 Afonso H Sabino. All rights reserved.
//
// All code in this project is come from the book "iOS Apps for Masterminds"
// You can know more about that in http://www.formasterminds.com

import UIKit
import CloudKit
import CoreData

//Enum to the Entities Name
enum Type: String {
    case Countries
    case Cities
}

class ApplicationData {
    
    //MARK: - Property to store the data locally
    
    ///Store a reference to the CloudKit's database
    var database: CKDatabase!
    
    ///It's the reference to knbow which country has been selected by the user at any given moment
    var selectedCountry: CKRecord.ID!
    
    ///Array with the list of the countries already inserted in the database
    var listCountries: [CKRecord] = []
    
    ///Array with the list of the cities available for a specific country
    var listCities: [CKRecord] = []
    
    ///Reference to the CoreData Context
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
            let record = CKRecord(recordType: Type.Countries.rawValue, recordID: id)
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
            let record = CKRecord(recordType: Type.Cities.rawValue, recordID: id)
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
        let query = CKQuery(recordType: Type.Countries.rawValue, predicate: predicate)
        
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
            let query = CKQuery(recordType: Type.Cities.rawValue, predicate: predicate)
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
                
                if type == Type.Countries.rawValue {
                    self.insertCountry(name: name)
                } else if type == Type.Cities.rawValue {
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
    
    //MARK: - Local Data Manipulation - Downloading Data
    
    ///This method is called after all the records are downloaded from CloudKit.
    //Here, we have to read each record, extract the information, and store it in the persistent store.
    func updateLocalRecords(listRecordsUpdated: [CKRecord]) {
        
        for record in listRecordsUpdated {
            
            //we first get the record's metadata.
            //Because this is a collection of values, the framework offers a convenient
            //method for this purpose called encodeSystemFields().
            //This method takes an NSKeyedArchiver object to encode all the values at once
            //and produces a Data structure we can get from the object's encodedData property.
            let coder = NSKeyedArchiver(requiringSecureCoding: true)
            record.encodeSystemFields(with: coder)
            let recordMetadata = coder.encodedData
            
            //Note: With this Data structure containing the record's metadata, the record's type,
            // and its identifier (record's name), we have all the information we need to insert
            // the record in the persistent store.
            
            let recordType = record.recordType
            let recordName = record.recordID.recordName
            
            
            //Check the Type (Countries or Cities)
            if recordType == Type.Countries.rawValue {
                
                //Create a predicate to look for a record with the same record name
                //Note: This is not the name of the country or city but the name of the record we
                // defined with the UUID() function when the record was created for the first time)
                let request: NSFetchRequest<Countries> = Countries.fetchRequest()
                request.predicate = NSPredicate(format: "ckRecordName = %@", recordName)
                
                do {
                    var country: Countries!
                    let result = try context.fetch(request)
                    
                    //If the record is not found (result is empty), we create a new Countries object
                    //and assign the record name to its ckRecordName property
                    if result.isEmpty {
                        country = Countries(context: context)
                        country.ckRecordName = recordName
                    } else {
                        country = result[0]
                    }
                    
                    //Otherwise, we get the record and update its attributes
                    country.ckMetadata = recordMetadata
                    country.ckUpload = false
                    country.name = record["name"] as? String
                } catch {
                    print("Error Fetching Data")
                }
            } else if recordType == Type.Cities.rawValue {
                
                //Create a predicate to look for a record with the same record name
                //Note: This is not the name of the country or city but the name of the record we
                // defined with the UUID() function when the record was created for the first time)
                let request: NSFetchRequest<Cities> = Cities.fetchRequest()
                request.predicate = NSPredicate(format: "ckRecordName = %@", recordName)
                
                do {
                    var city: Cities!
                    let result = try context.fetch(request)
                    
                    //If the record is not found (result is empty), we create a new Countries object
                    //and assign the record name to its ckRecordName property
                    if result.isEmpty {
                        city = Cities(context: context)
                        city.ckRecordName = recordName
                    } else {
                        city = result[0]
                    }
                    
                    //Otherwise, we get the record and update its attributes
                    city.ckMetadata = recordMetadata
                    city.ckUpload = false
                    city.ckPicture = false
                    city.name = record["name"] as? String
                    
                    //Store the record name of the country the city belongs to (stored in the
                    //Reference object identified with the string "country")
                    if let reference = record["country"] as? CKRecord.Reference {
                        city.ckReference = reference.recordID.recordName
                    }
                    
                    //Get the picture from the CKAsset.
                    if let asset = record["picture"] as? CKAsset {
                        let picture = UIImage(contentsOfFile: asset.fileURL!.path)
                        city.picture = picture?.pngData()
                    }
                } catch {
                    print("Error Fetching Data")
                }
            }
        }
        
        //If there are changes in context, save it.
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error Saving Context")
            }
        }
    }
    
    ///This method is called after records were deleted in CloudKit.
    //Here, we have to find the records of the same type and with the same name
    //in the persistent store and then use the delete() method to delete them.
    func deleteLocalRecords(listRecordsDeleted: [String:String]) {
        
        for (recordName, recordType) in listRecordsDeleted {
            
            if recordType == Type.Countries.rawValue {
                let request: NSFetchRequest<Countries> = Countries.fetchRequest()
                request.predicate = NSPredicate(format: "ckRecordName = %@", recordName)
                
                do {
                    let result = try context.fetch(request)
                    if !result.isEmpty {
                        let country = result[0]
                        context.delete(country)
                    }
                } catch {
                    print("Error Fetching")
                }
            } else if recordType == Type.Cities.rawValue {
                let request: NSFetchRequest<Cities> = Cities.fetchRequest()
                request.predicate = NSPredicate(format: "ckRecordName = %@", recordName)
                
                do {
                    let result = try context.fetch(request)
                    if !result.isEmpty {
                        let city = result[0]
                        context.delete(city)
                    }
                } catch {
                    print("Error Fetching")
                }
            }
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error Saving Context")
            }
        }
    }
    
    ///Read all the Cities objects that have a value stored in the ckreference attribute
    ///and connect them with their Countries object through their country attribute
    func updateLocalReference() {
        let requestCities: NSFetchRequest<Cities> = Cities.fetchRequest()
        
        //We use the value of the ckreference attribute in the Cities objects to determine
        //whether the reference was already created in Core Data or not.
        requestCities.predicate = NSPredicate(format: "ckReference != nil")
        
        //If the value is different than nil, we search for a country with that record name
        //and if we find it, we assign it to the country property of the Cities object, thus
        //defining the relationship and connecting the city with its country.
        do {
            let listCities = try context.fetch(requestCities)
            for city in listCities {
                let requestCountries: NSFetchRequest<Countries> = Countries.fetchRequest()
                requestCountries.predicate = NSPredicate(format: "ckRecordName = %@", city.ckReference!)
                
                do {
                    let listCountries = try context.fetch(requestCountries)
                    if !listCountries.isEmpty {
                        city.country = listCountries[0]
                        city.ckReference = nil
                    }
                } catch {
                    print("Error Fetching")
                }
            }
        } catch {
            print("Error Fetching")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error Saving Context")
            }
        }
    }
    
    //MARK: - Local Data Manipulation - Uploading Data
    
    /*
     Note: Uploading the records one by one is not appropriate when working with a local storage.
     We have to anticipate problems in the connection or the operation that will prevent some records
     from being uploaded to the server. This is why we decided to mark each object in the persistent
     store with a Boolean value stored in the ckupload attribute. If the attribute is true, we know that
     the record was not uploaded yet and therefore we can include it on the list. This way, if a process
     failed before, we do it again until all the records are uploaded to the CloudKit database.
     */
    
    ///Methods to upload the records the user creates and delete those that the user removes.
    //Uploading Multiple Records
    func uploadRecords() {
        let listRecordsToUpload = getRecordsToUpload()
        if !listRecordsToUpload.isEmpty {
            
            //We call the configureDatabase() method first to make sure the database is properly configured.
            configureDatabase {
                let operation = CKModifyRecordsOperation(recordsToSave: listRecordsToUpload, recordIDsToDelete: nil)
                operation.modifyRecordsCompletionBlock = { (records, recordsID, error) in
                    if error != nil {
                        print("ERROR Uploading Records")
                    } else {
                        
                        //Set the values of the ckupload attribute of each record in the persistent store
                        //back to false, so they are not uploaded again.
                        self.clearCoreDataRecord()
                    }
                }
                self.database.add(operation)
            }
        }
    }
    
    ///Getting all the records in the persistent store that has to be uploaded
    //The method looks for the Countries and Cities objects with the ckupload
    //attribute equal to true, adds them to an array, and returns it.
    func getRecordsToUpload() -> [CKRecord] {
        
        /*
         NOTE: We can't send Core Data objects to CloudKit, we first have to convert them
         to CKRecord objects. The problem is that if we just create a new CKRecord object
         every time the user modifies an existing record in the persistent store, the database
         won't be able to match the records and will add a new record instead of modifying the old one
         
         This is another reason why we included the ckmetadata attribute in every Countries and
         Cities object with the metadata of the record. To allow the server to match the record
         we are sending with those already stored in the database, we have to include the values
         contained in this metadata, and this is the first thing we do with each record.
         */
        
        var list: [CKRecord] = []
        
        //First to Countries
        let requestCountries: NSFetchRequest<Countries> = Countries.fetchRequest()
        requestCountries.predicate = NSPredicate(format: "ckUpload = true")
        
        do {
            let result = try context.fetch(requestCountries)
            
            for item in result {
                var recordTemp: CKRecord!
                
                //The metadata is unarchived with an NSKeyedUnarchiver object and we get
                //a CKRecord object in return.
                if let coder = try? NSKeyedUnarchiver(forReadingFrom: item.ckMetadata!) {
                    coder.requiresSecureCoding = true
                    
                    //Returns a CKRecord object with the values
                    recordTemp = CKRecord(coder: coder)
                    coder.finishDecoding()
                }
                
                //Assign to this CKRecord object the rest of the values that were modified by the user
                //(e.g., the name of the country)
                if let record = recordTemp {
                    record.setObject(item.name! as NSString, forKey: "name")
                    
                    //Add the record to the array
                    list.append(record)
                }
            }
        } catch {
            print("Error Fetching")
        }
        
        //Second to Cities
        let requestCities: NSFetchRequest<Cities> = Cities.fetchRequest()
        requestCities.predicate = NSPredicate(format: "ckUpload = true")
        
        do {
            let result = try context.fetch(requestCities)
            
            for item in result {
                var recordTemp: CKRecord!
                if let coder = try? NSKeyedUnarchiver(forReadingFrom: item.ckMetadata!) {
                    coder.requiresSecureCoding = true
                    recordTemp = CKRecord(coder: coder)
                    coder.finishDecoding()
                }
                if let record = recordTemp {
                    record.setObject(item.name! as NSString, forKey: "name")
                    
                    //Get the Picture
                    if item.ckPicture && item.picture != nil {
                        
                        //Get URL of  the Temp Directory
                        var url = URL(fileURLWithPath: NSTemporaryDirectory())
                        
                        //Add the name of the file to the path
                        url = url.appendingPathComponent("tempFile.png")
                        
                        //Create a temporary file with this data and then create the CKAsset
                        // object from the URL of this file
                        do {
                            let pngImage = item.picture!
                            
                            //Store the data in the file
                            try pngImage.write(to: url, options: .atomic)
                            let asset = CKAsset(fileURL: url)
                            record.setObject(asset, forKey: "picture")
                        } catch {
                            print("Error Image Not Stored")
                        }
                    }
                    
                    //Get the Zone and Reference
                    if let country = item.country {
                        let  zone = CKRecordZone(zoneName: "listPlaces")
                        let id = CKRecord.ID(recordName: country.ckRecordName!, zoneID: zone.zoneID)
                        let reference = CKRecord.Reference(recordID: id, action: .deleteSelf)
                        record.setObject(reference, forKey: "country")
                    }
                    list.append(record)
                }
            }
        } catch {
            print("Error Fetching")
        }
        return list
    }
    
    ///Cleaning up the objects in the persistent store
    func clearCoreDataRecord() {
        
        /*
         When the operation finish uploading all the records, we have to change the values of the
         ckupload attribute of each object to false, so they are not uploaded again.
         Notice that for the Cities objects, we also have to change the value of the ckpicture
         attribute to indicate that the pictures were also uploaded.
         */
        
        //First fetch Countries and change ckUpload to false
        let requestCountries: NSFetchRequest<Countries> = Countries.fetchRequest()
        requestCountries.predicate = NSPredicate(format: "ckUpload = true")
        
        do {
            let result = try context.fetch(requestCountries)
            for item in result {
                item.ckUpload = false
            }
        } catch {
            print("Error Fetching Countries in clearCoreDataRecord()")
        }
        
        //Second repeat the same fetch to Cities
        let requestCities: NSFetchRequest<Cities> = Cities.fetchRequest()
        requestCities.predicate = NSPredicate(format: "ckUpload = true")
        
        do {
            let result = try context.fetch(requestCities)
            for item in result {
                item.ckUpload = false
                item.ckPicture = false
            }
        } catch {
            print("Error Fetching Cities in clearCoreDataRecord()")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error Saving Context in clearCoreDataRecord()")
            }
        }
    }
    
    ///Erase the records in CloudKit that correspond to the objects removed by the user from the persistent store.
    func removeRecords() {
        
        /*
         Create an object of type CKDelete with the record name of each of the Countries and Cities
         objects deleted by the user and then remove them from the persistent store. This way,
         to reflect the changes in the CloudKit database, we just have to call a method in our model
         to erase the records that match the record names stored in the CKDelete entity.
         */
        
        var listRecordsToDelete: [CKRecord.ID] = []
        
        let request: NSFetchRequest<CKDelete> = CKDelete.fetchRequest()
        
        do {
            let result = try context.fetch(request)
            for item in result {
                let zone = CKRecordZone(zoneName: item.zoneName!)
                let id = CKRecord.ID(recordName: item.recordName!, zoneID: zone.zoneID)
                listRecordsToDelete.append(id)
            }
        } catch {
            print("Error Fetching Record ID in removeRecords()")
        }
        if !listRecordsToDelete.isEmpty {
            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: listRecordsToDelete)
            operation.modifyRecordsCompletionBlock = { (records, recordsID, error) in
                if error != nil {
                    print("Error Releting Records in removeRecords()")
                } else {
                    let request: NSFetchRequest<CKDelete> = CKDelete.fetchRequest()
                    
                    do {
                        let result = try self.context.fetch(request)
                        for item in result {
                            self.context.delete(item)
                        }
                        try self.context.save()
                    } catch {
                        print("Error Deleting in removeRecords()")
                    }
                }
            }
            database.add(operation)
        }
    }
    
    //MARK: - Contact the CloudKit Servers
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
                    if record.recordType == Type.Countries.rawValue {
                        
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
                        
                    } else if record.recordType == Type.Cities.rawValue {
                        
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
                    
                    if recordType == Type.Countries.rawValue {
                        let index = self.listCountries.firstIndex(where: { (item) -> Bool in
                            return item.recordID == recordID
                        })
                        if index != nil {
                            self.listCountries.remove(at: index!)
                        }
                    } else if recordType == Type.Cities.rawValue {
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
