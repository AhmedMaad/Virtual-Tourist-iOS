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
    var dataController: DataController!
    var map: Map!
    var uiImages: [UIImage?]?
    var isDataLoadedFromDB: Bool!
    var isDeletingImage: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Opened photo album view controller")
        collectionView.delegate = self
        collectionView.dataSource = self
        print(lat)
        print(lon)
        
        //Read data from DB by lat, lon, if the data exists then reload the collection view with the retrieved data
        //if the data doesn't exist, then request new data from the server without user interaction
        //Query: SELECT * FROM Photo WHERE photo.latitude = retrievedLat & photo.longitude = retrievedLon
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "imageData", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let predicate = NSPredicate(format: "pin.latitude == %@ AND pin.longitude == %@", lat, lon)
        fetchRequest.predicate = predicate
        let fetchedResults = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "mapAnnotations")
        fetchedResults.delegate = self
        
        do {
            try fetchedResults.performFetch()
            print("Data is fetched from DB")
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
        if(fetchedResults.fetchedObjects?.count == 0){
            //No previous saved picture, request new one from the server
            loadDataFromServer()
        }
        else{
            isDataLoadedFromDB = true
            for object in fetchedResults.fetchedObjects!{
                print("Picture is found")
                self.numberOfItems = fetchedResults.fetchedObjects?.count ?? 0
                let image: UIImage? = UIImage(data: object.imageData!)
                if(image != nil){
                    uiImages?.append(image)
                }
            }
            collectionView.reloadData()
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //Number of items in the collection view
        return numberOfItems //should be the number from he data source returned from flicker API or read from DB
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath as IndexPath) as! CollectionItem
        
        if(!isDeletingImage){
            //Show placeholder image while the actual image loads in the cell
            cell.myImage.image = UIImage(named: "reload")
            cell.backgroundColor = UIColor.cyan
            
            if (!isDataLoadedFromDB) {
                //Load the data from the retrieved API link
                print("Showing the pictures from the API")
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
                        
                        //Showing downloaded image in cell
                        let downloadedImage = UIImage(data: data!)
                        cell.myImage.image = downloadedImage
                    }
                }
                
            }
            else{
                print("Load the pictures from the DB")
                cell.myImage.image = uiImages?[indexPath.row]
            }
            
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        isDeletingImage = true
        //Handling tap events by deleting pictures
        print("should delete picture from collection view and DB")
        //remove picture from collection view
        images.remove(at: indexPath.row)
        collectionView.reloadData()
        //remove picture from DB
        //dataController.viewContext.delete(images![indexPath.row])
        //try? self.dataController.viewContext.save()
        
    }
    
    @IBAction func loadNewCollection(_ sender: Any) {
        loadDataFromServer()
    }
    
    func loadDataFromServer(){
        isDataLoadedFromDB = false
        isDeletingImage = false
        //Before saving "new" pictures we have to delete "old" pictures if exists in the database
        //Query: DELETE FROM Photo WHERE pin.latitude = retrievedLat AND pin.longitude = retrievedLon
        let photoDB = Photo(context: self.dataController.viewContext)
        photoDB.pin?.latitude = lat
        photoDB.pin?.longitude = lon
        self.dataController.viewContext.delete(photoDB)
        print("Old pictures are deleted")
        
        print("Loading new collection")
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
