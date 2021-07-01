
import UIKit
import MapKit
import CoreData


class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var fetchedResults: NSFetchedResultsController<Map>!
    
    var maps: [Map] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        getAllLocations()
        
        // Generate long-press
        let myLongPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
        myLongPress.addTarget(self, action: #selector(recognizeLongPress(_:)))
        mapView.addGestureRecognizer(myLongPress)
    }
    
    func getAllLocations() {
        
        let fetchRequest:NSFetchRequest<Map> = Map.fetchRequest()
        if let result = try? dataController.viewContext.fetch(fetchRequest){
            maps = result
        }
        
        var annotations = [MKPointAnnotation]()
        for location in maps{
            let lat = location.latitude
            let lng = location.longitude
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        mapView.addAnnotations(annotations)
        
    }
    
    
    // A method called when long press is detected.
    @objc private func recognizeLongPress(_ sender: UILongPressGestureRecognizer) {
        // Do not generate pins many times during long press.
        if sender.state != UIGestureRecognizer.State.began {
            return
        }
        
        let location = sender.location(in: mapView)
        let coordinate: CLLocationCoordinate2D = mapView.convert(location, toCoordinateFrom: mapView)
        let pin: MKPointAnnotation = MKPointAnnotation()
        pin.coordinate = coordinate
        mapView.addAnnotation(pin)
        addNewLocation(lat: coordinate.latitude, lng: coordinate.longitude)
    }
    
    func addNewLocation(lat: Double, lng: Double) {
        print("Should save lng and lat")
        let mapDB = Map(context: dataController.viewContext)
        mapDB.latitude = lat
        mapDB.longitude = lng
        maps.append(mapDB)
        try? dataController.viewContext.save()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Should show album view")
        
        mapView.deselectAnnotation(view.annotation, animated: true)
        let photoController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Photo") as! PhotoAlbumViewController
        photoController.lat = view.annotation?.coordinate.latitude
        photoController.lon = view.annotation?.coordinate.longitude
        photoController.dataController = self.dataController
        
        print("pins size are \(maps.count)")
        for pin in maps{
            if (view.annotation?.coordinate.latitude == pin.latitude && view.annotation?.coordinate.longitude == pin.longitude){
                print("Sending pin object to photo album")
                photoController.pin = pin
            }
        }
        //Open PhotoAlbumViewController to request pictures related to lat, lng of the selected  pin
        present(photoController, animated: true, completion: nil)
    }
    
    
}
