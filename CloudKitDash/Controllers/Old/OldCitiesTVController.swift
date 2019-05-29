//
//  OldCitiesTVController.swift
//  CloudKitDash
//
//  Created by Afonso H Sabino on 25/05/19.
//  Copyright © 2019 Afonso H Sabino. All rights reserved.
//
// All code in this project is come from the book "iOS Apps for Masterminds"
// You can know more about that in http://www.formasterminds.com

import UIKit

class OldCitiesTVController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Observer to Update Interface to call updateInterface()
        let notCenter = NotificationCenter.default
        let name = Notification.Name("Update Interface")
        notCenter.addObserver(self, selector: #selector(updateInterface(notification:)), name: name, object: nil)
        
        //Read and show the values when the view is loaded
        //The method performs a query on the database to get all the countries
        //available and posts a notification when it is over
        AppData.readCities()
        
        //Note: This is why we register the observer for the notification before calling the method
        
    }
    
    @objc func updateInterface(notification: Notification) {
        tableView.reloadData()
    }
    
    @IBAction func addCity(_ sender: UIBarButtonItem) {
        present(AppData.setAlert(type: "City", title: "Insert City", style: .alert, message: "Add a new city to the list"), animated: true)
    }
    
    @IBAction func editCity(_ sender: UIBarButtonItem) {
        
    }
    
    
    //Method Prepare to go to PictureVC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPicture" {
            if let indexParth = self.tableView.indexPathForSelectedRow {
                let vc = segue.destination as! PictureViewController
                vc.selectedCity = AppData.listCities[indexParth.row]
            }
        }
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return AppData.listCities.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "citiesCell", for: indexPath)
        
        let record = AppData.listCities[indexPath.row]
        
        if let name = record["cityName"] as? String {
            cell.textLabel?.text = name
        }
        
        return cell
    }
    
}
