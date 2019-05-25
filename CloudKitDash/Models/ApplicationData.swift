//
//  ApplicationData.swift
//  CloudKitDash
//
//  Created by Afonso H Sabino on 25/05/19.
//  Copyright © 2019 Afonso H Sabino. All rights reserved.
//

import UIKit
import CloudKit

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
    
    init() {
        
        //Get the container from PrivateCloudDatabase
        let container = CKContainer.default()
        database = container.privateCloudDatabase
    }
    
    //MARK: - Model Functions to Insert Data
    
    ///Method to insert a new Country
    func insertCountry(name: String) {
        let text = name.trimmingCharacters(in: .whitespaces)
        
        if text != "" {
            
            //Create a unique value ID for the Countries
            let id = CKRecord.ID(recordName: "idcountry-\(UUID())")
            
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
            
            //Create a unique value ID for the Countries
            let id = CKRecord.ID(recordName: "idcity-\(UUID())")
            
            //Create a record object of type Cities
            let record = CKRecord(recordType: "Cities", recordID: id)
            
            record.setObject(text as NSString, forKey: "cityName")
            
            //Create a reference to the Country the City belongs to, and an action of type "deleteSelf"
            //"when the record of the country is deleted, this record is deleted as well."
            let reference = CKRecord.Reference(recordID: selectedCountry, action: .deleteSelf)
            record.setObject(reference, forKey: "country")
            
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
    
    //The purpose of this method is to tell the rest of the application
    //that new information is available and should be shown to the user.
    func updateInterface() {
        let main = OperationQueue.main
        main.addOperation {
            let center = NotificationCenter.default
            let name = Notification.Name("Update Interface")
            center.post(name: name, object: nil, userInfo: nil)
        }
    }
}

var AppData = ApplicationData()
