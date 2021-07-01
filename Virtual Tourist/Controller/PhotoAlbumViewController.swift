//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Ahmed Maad on 11/22/20.
//  Copyright © 2020 Next Trend. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource
, NSFetchedResultsControllerDelegate{
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    var lat: Double!
    var lon: Double!
    var images: [Imagez]!
    var numberOfItems: Int = 0
    var fetchedResults: NSFetchedResultsController<Photo>!
    var dataController: DataController!
    var map: Map!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Opened photo album view controller")
        collectionView.delegate = self
        collectionView.dataSource = self
        print(lat)
        print(lon)
        //try to fetch from DB, if no data is found so request new data immediately without user interaction
        //setupFetchedResultsController()
        //fetchPicturesFromDB()
        
        //Search for the clicked pin in the database because this will help when we save/retrieve pictures
        /*let fetchRequest:NSFetchRequest<Map> = Map.fetchRequest()
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", NSNumber(value: view.annotation?.coordinate.latitude ?? 0.0)
            , NSNumber(value: view.annotation?.coordinate.longitude ?? 0.0))
        fetchRequest.predicate = predicate
        var result: NSFetchedResultsController<Map> = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "mapAnnotations")
        fetchedResults.delegate = self
        
        do {
            try fetchedResults.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }*/
        
        //This should be deleted
        /*for pin in fetchedResults.fetchedObjects!{
            photoController.map = pin
        }*/
        
        
    }
    
    /*func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", map)
        fetchedResults = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "mapAnnotations")
        fetchedResults.delegate = self
        
        do {
            try fetchedResults.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }*/
    
    /*fileprivate func fetchPicturesFromDB() {
        var pictures = [Photo]()
        for photo in fetchedResults.fetchedObjects!{
            pictures.append(photo)
        }
    }*/
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //Number of items in the collection view
        return numberOfItems //should be the number from he data source returned from flicker API or read from DB
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath) as! CollectionItem
        
        //Show placeholder image while the actual image loads in the cell
        cell.myImage.image = UIImage(named: "reload")
        cell.backgroundColor = UIColor.cyan
        
        //Load the data from the retrieved API link
        let fileUrl = URL(string: images[indexPath.row].url_m)
        FlickerAPI.requestImage(url: fileUrl!) { (data, error) in
            DispatchQueue.main.async {
                
                //Code to save picture data in relation to pin
                //Query: INSERT INTO Photo (imageData) VALUES (data) WHERE pin.latitude = retrievedLat AND pin.longitude = retrievedLon
                let photoDB = Photo(context: self.dataController.viewContext)
                photoDB.imageData = data
                photoDB.pin?.latitude = self.lat
                photoDB.pin?.longitude = self.lon
                try? self.dataController.viewContext.save()
                print("Picture is saved")
                
                //Showing downloaded image in cell
                let downloadedImage = UIImage(data: data!)
                cell.myImage.image = downloadedImage
            }
        }        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Handling tap events by deleting pictures
        print("should delete picture from collection view and DB")
    }
    
    @IBAction func loadNewCollection(_ sender: Any) {
        //Before saving "new" pictures we have to delete "old" pictures if exists in the database
        //Query: DELETE FROM Photo WHERE pin.latitude = retrievedLat AND pin.longitude = retrievedLon
        let photoDB = Photo(context: self.dataController.viewContext)
        photoDB.pin?.latitude = lat
        photoDB.pin?.longitude = lon
        self.dataController.viewContext.delete(photoDB)
        print("Old pictures are deleted")
        
        
        print("Should load new collection")
        FlickerAPI.getPicsEncryptedData(lat: lat, lon: lon, completionHandler: handleEncryptedPictureResponse(encryptedImages:error:))
    }
    
    func handleEncryptedPictureResponse(encryptedImages: [Imagez], error:Error?){
        if encryptedImages.count > 0 {
            print("Handling encrypted images response")
            DispatchQueue.main.async {
                self.images = encryptedImages
                self.numberOfItems = self.images.count
                self.collectionView.reloadData()
            }
        }
        else{
            print("Encrypted Images request Failed...")
        }
    }
    
}
