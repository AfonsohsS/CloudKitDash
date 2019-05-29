//
//  CountriesTVController.swift
//  CloudKitDash
//
//  Created by Afonso H Sabino on 29/05/19.
//  Copyright © 2019 Afonso H Sabino. All rights reserved.
//
// All code in this project is come from the book "iOS Apps for Masterminds"
// You can know more about that in http://www.formasterminds.com

import UIKit
import CloudKit
import CoreData

class CountriesTVController: UITableViewController, NSFetchedResultsControllerDelegate {

    var context: NSManagedObjectContext!
    
    //The viewControllers defines this fetch object to get the objects from the
    //persistent store and feed the table view
    var fetchedController: NSFetchedResultsController<Countries>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///NÃO ESQUECER DE BUSCAR ALTERNATIVA MELHOR PARA ISSO
        let app = UIApplication.shared
        let appDelegate = app.delegate as! AppDelegate
        context = appDelegate.context
        
        let request: NSFetchRequest<Countries> = Countries.fetchRequest()
        let sort = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [sort]
        
        fetchedController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedController.delegate = self
        
        do {
            try fetchedController.performFetch()
        } catch {
            print("Error Fetching Data in CountriesTVController viewDidLoad()")
        }
        
    }
    
    //Add new Country
    @IBAction func addCountry(_ sender: UIBarButtonItem) {
        present(AppData.setAlert(type: "Country", title: "Insert Country", style: .alert, message: "Add a new country to the list", selectedCountry: nil), animated: true)
    }
    
    @IBAction func editCountry(_ sender: UIBarButtonItem) {
        
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
        } else {
            tableView.setEditing(true, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCities" {
            
            let vc = segue.destination as! CitiesTVController
            
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let country = fetchedController.object(at: indexPath)
                vc.selectedCountry = country
            }
        }
    }
    
    // MARK: - Table view data source and delegate
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let sections = fetchedController.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "countriesCell", for: indexPath)
        
        let country = fetchedController.object(at: indexPath)
        cell.textLabel?.text = country.name
        
        return cell
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            case .delete:
                if let path = indexPath {
                    tableView.deleteRows(at: [path], with: .fade)
                }
            case .insert:
                if let path = newIndexPath {
                    tableView.insertRows(at: [path], with: .fade)
                }
            case .update:
                if let path = indexPath {
                    let cell = tableView.cellForRow(at: path)
                    let country = fetchedController.object(at: path)
                    cell?.textLabel?.text = country.name
                }
            default:
                break
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let country = fetchedController.object(at: indexPath)
            
            //Add a CKDelete object to the persistent store with the information about the record
            //we have to delete from CloudKit, and then delete the Countries object from Core Data
            let newItem = CKDelete(context: context)
            newItem.zoneName = "listPlaces"
            newItem.recordName = country.ckRecordName
            context.delete(country)
            
            do {
                try self.context.save()
                AppData.removeRecords()
            } catch {
                print("Error Deleting Country")
            }
            tableView.setEditing(false, animated: true)
        }
    }

}
