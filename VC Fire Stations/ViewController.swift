//
//  ViewController.swift
//  VC Fire Stations
//
//  Created by Richard Poutier on 11/29/18.
//  Copyright © 2018 Richard Poutier. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    // Interface Builder Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // Properties
    
    /// The manager in charge of finding our user
    let locationManager = CLLocationManager()
    
    /// A default Region Radius for our mapView
    let regionRadius: CLLocationDistance = 1000
    
    /// A variable that holds a list of FireStations in Ventura County
    var fireStations: [FireStation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let initialLocation = CLLocation(latitude: 34.2145, longitude: -118.9994)
        centerMapOnLocation(location: initialLocation)
        
        // delegate is a fancy way of "boss". Here, we're telling the app that the boss of the mapView, is equal to 'self'.
        mapView.delegate = self
        
        // Show a VCFD Station on map
        let fireStation = FireStation(title: "Ventura County Station 31", locationName: "", coordinate: CLLocationCoordinate2D(latitude: 34.1710, longitude: -118.8328))
        mapView.addAnnotation(fireStation)
        
        // Loads the stored data from the SampleJSON file
        loadInitialData()
        
        // Adds annotations to the map
        mapView.addAnnotations(fireStations)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // yeah git can be annoying
        startLocationServices()
    }
    
    private func startLocationServices() {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus != .authorizedWhenInUse {
            // user hasn't authorized access to the locationManager yet
            
            // request the user to authorize location services for 'when in use'
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        // Do not start services that aren't available
        if !CLLocationManager.locationServicesEnabled() {
            // Location services is not available
            return
        }
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.desiredAccuracy = 100.0  // In meters
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    
    /// This method centers the map view around the user's current location.
    /// To do this, we need to first make sure that the user has given us
    /// their permission to use their location
    ///
    @IBAction func centerMapOnUser(_ sender: Any) {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus != .authorizedWhenInUse {
            // user hasn't authorized access to the locationManager
            return
        }
        
        // Do not start services that aren't available
        if !CLLocationManager.locationServicesEnabled() {
            // Location services is not available
            return
        }
        
        if let location = locationManager.location {
            centerMapOnLocation(location: location)
            mapView.showsUserLocation = true
        }
    }
    
    private func addAlert(with title: String, message: String) {
        let alertSheet = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertSheet.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alertSheet, animated: true, completion: nil)
    }
    
    
    /// Centers the map on `location`
    ///
    /// - Parameter location: The Location to center the map around
    ///
    ///         // create a location like this:
    ///         let initialLocation = CLLocation(latitude: 34.2145, longitude: -118.9994)
    ///
    ///         // send the location to this method like this:
    ///         centerMapOnLocation(location: initialLocation)
    ///
    private func centerMapOnLocation(location: CLLocation) {
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
        mapView.setRegion(region, animated: true)
    }
    
    private func loadInitialData() {
        guard let fileName = Bundle.main.path(forResource: "SampleJSON", ofType: "json") else { return }
        let optionalData = try? Data(contentsOf: URL(fileURLWithPath: fileName))
        
        guard let data = optionalData, let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments), let dictionary = json as? [String : Any], let works = dictionary["data"] as? [[String:Any]] else { return }
        let validWorks = works.compactMap { FireStation(JSON: $0) }
        fireStations.append(contentsOf: validWorks)
    }

}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let annotation = annotation as? FireStation else { return nil }
        
        let identifier = "marker"
        var view: MKMarkerAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let location = view.annotation as! FireStation
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        location.mapItem().openInMaps(launchOptions: launchOptions)
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationServices()
        case .denied, .restricted:
            addAlert(with: "Error", message: "Location Services have been denied/restricted. Please change in System Settings.")
        case .notDetermined:
            addAlert(with: "Error", message: "Location Services are Not Determined.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            locationManager.stopUpdatingLocation()
            return
        }
        print("Location Manager had an error:")
        print(error.localizedDescription)
    }
}
