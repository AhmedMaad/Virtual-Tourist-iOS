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
    var isDataLoadedFromDB: Bool = false
    var isDeletingImage: Bool = false
    
    //Adding new Lines
    var photos: [Photo] = []
    var photoDatas: [Data] = []
    var pin: Map!
    var photosToDelete: [Photo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Opened photo album view controller")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            photos = result
        }
        
        print("All photos in the array count are \(photos.count)")
        for photo in photos{
            if(photo.pin?.latitude == lat && photo.pin?.longitude == lon){
                print("Adding photo from DB in to the array")
                photoDatas.append(photo.imageData!)
                photosToDelete.append(photo)
            }
        }
        
        if (photoDatas.count == 0) {
            print("photo datas is empty, requesting new data from server")
            loadDataFromServer()
        }
        else{
            print(photoDatas.count)
            isDataLoadedFromDB = true
            numberOfItems = photoDatas.count
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
                        photoDB.pin = self.pin
                        self.photos.append(photoDB)
                        self.photoDatas.append(data!)
                        try? self.dataController.viewContext.save()
                        
                        //Showing downloaded image in cell
                        let downloadedImage = UIImage(data: data!)
                        cell.myImage.image = downloadedImage
                    }
                }
                
            }
            else{
                print("Load the pictures from the DB")
                let mImage = UIImage(data: photoDatas[indexPath.row])
                cell.myImage.image = mImage
            }
            
        }
        else{
            print("Refreshing collection view")
            let mImage = UIImage(data: photoDatas[indexPath.row])
            cell.myImage.image = mImage
        }
        
        return cell
    }
    
    //Handling tap events to delete pictures
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("should delete picture from collection view and DB")
        numberOfItems = numberOfItems - 1
        isDeletingImage = true
        //remove picture from collection view from server array or from db array
        if(isDataLoadedFromDB){
            //remove from db array only
            print("Deleting picture from DB array")
            
            dataController.viewContext.delete(photosToDelete[indexPath.row])
            do {
                try dataController.viewContext.save()
                print("Picture is deleted")
            } catch {
                print("Picture is not deleted")
            }
            
            photoDatas.remove(at: indexPath.row)
            
        }
        else{
            //remove from server array and from db array because we save pictures
            print("Deleting picture from DB and Server Arrays")
            
            dataController.viewContext.delete(photos[indexPath.row])
            do {
                try dataController.viewContext.save()
                print("Picture is deleted")
            } catch {
                print("Picture is not deleted")
            }
            
            photoDatas.remove(at: indexPath.row)
            images.remove(at: indexPath.row)
        }
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
        
        print("Old pictures are being deleted")
        for photo in photos{
            if(photo.pin?.latitude == lat && photo.pin?.longitude == lon){
                print("Picture should be deleted")
                dataController.viewContext.delete(photo)
                do {
                    try dataController.viewContext.save()
                    print("Picture is deleted")
                } catch {
                    print("Picture is not deleted")
                }
            }
        }
        
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
