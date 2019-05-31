//
//  CloudErrors.swift
//  CloudKitDash
//
//  Created by Afonso H Sabino on 30/05/19.
//  Copyright © 2019 Afonso H Sabino. All rights reserved.
//

import CloudKit

class CloudErrors {
    
    static func processErrors(error: CKError) {
        let userSettings = UserDefaults.standard
        
        switch error.code {
            
            case .notAuthenticated:
                userSettings.set(false, forKey: "iCloudAvailable")
            
            case .changeTokenExpired:
                
                //Remove tokens values from userDefaults
                userSettings.removeObject(forKey: "changeToken")
                userSettings.removeObject(forKey: "changeZoneToken")
                
                //Execute checkUpdates() after 30 seconds
                Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(AppData.checkUpdates(finishClosure:)), userInfo: nil, repeats: false)
            
            case .quotaExceeded:
                ///Warn the user by an Alert
                print("There is no space in your iCloud Account")
            
            /*
             The way errors provide additional information is through a dictionary assigned to
             their userInfo property (an NSDictionary object). To get the records that failed,
             we have to read the value in this dictionary with the key CKPartialErrorsByItemIDKey.
             In turn, this key returns another NSDictionary object with a list of the record IDs of
             the records that failed and the corresponding error each operation returned.
             */
            
            case .partialFailure:
                if let listErrors = error.userInfo[CKPartialErrorsByItemIDKey] as? NSDictionary {
                    var listFailedRecords: [CKRecord] = []
                    for (_, error) in listErrors {
                        if let recordError = error as? CKError {
                            
                            //The process of uploading a record may failed for different reasons.
                            //If we want to get the records that failed because of a tag mismatch,
                            //we have to read the CKRecordChangedErrorServerRecordKey key of the userInfo
                            //dictionary of each error.
                            if let record = recordError.userInfo[CKRecordChangedErrorServerRecordKey] as? CKRecord {
                                listFailedRecords.append(record)
                            }
                        }
                    }
                    AppData.uploadFailedRecords(failedRecords: listFailedRecords)
                }
            case .networkFailure:
                ///Warn the user by an Alert
                print("Network Failure")
            case .networkUnavailable:
                ///Warn the user by an Alert
                print("Network Unavailable")
            default:
                print("Error: \(error.code)")
                break
        }
    }

}
