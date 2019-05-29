//
//  CitiesTVController.swift
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

class CitiesTVController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var context: NSManagedObjectContext!
    
    //The viewControllers defines this fetch object to get the objects from the
    //persistent store and feed the table view
    var fetchedController: NSFetchedResultsController<Cities>!
    
    var selectedCountry: Countries!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///NÃO ESQUECER DE BUSCAR ALTERNATIVA MELHOR PARA ISSO
        let app = UIApplication.shared
        let appDelegate = app.delegate as! AppDelegate
        context = appDelegate.context
        
        if selectedCountry != nil {
            let request: NSFetchRequest<Cities> = Cities.fetchRequest()
            request.predicate = NSPredicate(format: "country = %@", selectedCountry)
            let sort = NSSortDescriptor(key: "name", ascending: true)
            request.sortDescriptors = [sort]
            
            fetchedController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchedController.delegate = self
            
            do {
                try fetchedController.performFetch()
            } catch {
                print("Error Fetching Data in CitiesTVController viewDidLoad()")
            }
        }
    }
    
    @IBAction func addCity(_ sender: UIBarButtonItem) {
        present(AppData.setAlert(type: "Cities", title: "Insert City", style: .alert, message: "Add a new city to the list", selectedCountry: self.selectedCountry), animated: true)
    }
    
    @IBAction func editCity(_ sender: UIBarButtonItem) {
        
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
        } else {
            tableView.setEditing(true, animated: true)
        }
    }
    
    
    //Method Prepare to go to PictureVC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPicture" {
            let vc = segue.destination as! PictureViewController
            if let indexParth = self.tableView.indexPathForSelectedRow {
                let city = fetchedController.object(at: indexParth)
                vc.selectedCity = city
            }
        }
    }
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let sections = fetchedController.sections {
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
        }
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "citiesCell", for: indexPath)
        
        let city = fetchedController.object(at: indexPath)
        cell.textLabel?.text = city.name

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
                    let city = fetchedController.object(at: path)
                    cell?.textLabel?.text = city.name
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
            let city = fetchedController.object(at: indexPath)
            
            //Add a CKDelete object to the persistent store with the information about the record
            //we have to delete from CloudKit, and then delete the Countries object from Core Data
            let newItem = CKDelete(context: context)
            newItem.zoneName = "listPlaces"
            newItem.recordName = city.ckRecordName
            context.delete(city)
            
            do {
                try self.context.save()
                AppData.removeRecords()
            } catch {
                print("Error Deleting City")
            }
            tableView.setEditing(false, animated: true)
        }
    }

  

}
