//
//  CountriesTVController.swift
//  CloudKitDash
//
//  Created by Afonso H Sabino on 25/05/19.
//  Copyright © 2019 Afonso H Sabino. All rights reserved.
//

import UIKit
import CloudKit

class CountriesTVController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Observer to Update Interface to call updateInterface()
        let notCenter = NotificationCenter.default
        let name = Notification.Name("Update Interface")
        notCenter.addObserver(self, selector: #selector(updateInterface(notification:)), name: name, object: nil)
        
        //Read and show the values when the view is loaded
        //The method performs a query on the database to get all the countries
        //available and posts a notification when it is over
        AppData.readCountries()
        
        //Note: This is why we register the observer for the notification before calling the method

    }
    
    @objc func updateInterface(notification: Notification) {
        tableView.reloadData()
    }
    
    //Add new Country
    @IBAction func addCountry(_ sender: UIBarButtonItem) {
        present(AppData.setAlert(type: "Country", title: "Insert Country", style: .alert, message: "Add a new country to the list"), animated: true)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCities" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let record = AppData.listCountries[indexPath.row]
                AppData.selectedCountry = record.recordID
            }
        }
    }
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return AppData.listCountries.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "countriesCell", for: indexPath)

        let record = AppData.listCountries[indexPath.row]
        
        if let name = record["countryName"] as? String {
            cell.textLabel?.text = name
        }

        return cell
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
