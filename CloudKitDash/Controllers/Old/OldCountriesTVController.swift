//
//  OldCountriesTVController.swift
//  CloudKitDash
//
//  Created by Afonso H Sabino on 25/05/19.
//  Copyright © 2019 Afonso H Sabino. All rights reserved.
//
// All code in this project is come from the book "iOS Apps for Masterminds"
// You can know more about that in http://www.formasterminds.com

//import UIKit
//import CloudKit
//
//class OldCountriesTVController: UITableViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        //Observer to Update Interface to call updateInterface()
//        let notCenter = NotificationCenter.default
//        let name = Notification.Name("Update Interface")
//        notCenter.addObserver(self, selector: #selector(updateInterface(notification:)), name: name, object: nil)
//
//        //Read and show the values when the view is loaded
//        //The method performs a query on the database to get all the countries
//        //available and posts a notification when it is over
//        AppData.readCountries()
//
//        //Note: This is why we register the observer for the notification before calling the method
//
//    }
//
//    @objc func updateInterface(notification: Notification) {
//        tableView.reloadData()
//    }
//
//    //Add new Country
//    @IBAction func addCountry(_ sender: UIBarButtonItem) {
//        present(AppData.setAlert(type: "Country", title: "Insert Country", style: .alert, message: "Add a new country to the list"), animated: true)
//    }
//
//    @IBAction func editCountry(_ sender: UIBarButtonItem) {
//
//    }
//
//
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "showCities" {
//            if let indexPath = self.tableView.indexPathForSelectedRow {
//                let record = AppData.listCountries[indexPath.row]
//                AppData.selectedCountry = record.recordID
//            }
//        }
//    }
//
//
//    // MARK: - Table view data source
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return AppData.listCountries.count
//    }
//
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "countriesCell", for: indexPath)
//
//        let record = AppData.listCountries[indexPath.row]
//
//        if let name = record["countryName"] as? String {
//            cell.textLabel?.text = name
//        }
//
//        return cell
//    }
//
//}
