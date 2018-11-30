//
//  FireStation.swift
//  VC Fire Stations
//
//  Created by Richard Poutier on 11/29/18.
//  Copyright © 2018 Richard Poutier. All rights reserved.
//

import UIKit
import MapKit
import Contacts

class FireStation: NSObject, MKAnnotation {
    let title: String?
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate
        
        super.init()
    }
    
    init?(JSON: [String: Any]) {
        self.title = JSON["name"] as? String ??  "No Title"
        self.locationName = JSON["locationName"] as? String ?? ""
        if let latitude = Double(JSON["latitude"] as! String),
            let longitude = Double(JSON["longitude"] as! String) {
            self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            self.coordinate = CLLocationCoordinate2D()
        }
    }
    
    var subtitle: String? {
        return locationName
    }
    
    // Annotation right callout accessory opens this mapItem in Maps App
    public func mapItem() -> MKMapItem {
        let addressDict = [CNPostalAddressStreetKey: subtitle!]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        return mapItem
    }
}
