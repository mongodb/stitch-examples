//
//  LocationManager.swift
//  PlateSpace
//
//  Created by Miko Halevi on 3/7/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import Foundation
import CoreLocation

// MARK: - LocationAuthorizationDelegate (protocol)

protocol LocationAuthorizationDelegate: class {
    func authorizationStatusChanged()
}

// MARK: - LocationUpdateDelegate (protocol)

protocol LocationUpdateDelegate: class {
    func didUpdateLoction()
    func didFailUpdatingWithError(error: Error)
}

// MARK: - LocationManager

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Properties
    
    internal var manager = CLLocationManager()
    weak var authorizationDelegate: LocationAuthorizationDelegate?
    weak var updateDelegate: LocationUpdateDelegate?
    var isUpdating = true
    
    // MARK: - Init
    
    override init() {
        super.init()
        self.manager.delegate = self
    }
    
    // MARK: - Location
    
    func didRequestAuthorization() -> Bool {
        return CLLocationManager.authorizationStatus() != CLAuthorizationStatus.notDetermined
    }
    
    func isAuthorized() -> Bool {
        return CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways
    }
    
    func isAuthorizedAlways() -> Bool {
        return CLLocationManager.authorizationStatus() == .authorizedAlways
    }
    
    func isDenied() -> Bool {
        return CLLocationManager.authorizationStatus() == .denied
    }
    
    func requestAuthorization() {
        self.manager.requestAlwaysAuthorization()
    }
    
    func requestWhenInUseAuthorization() {
        self.manager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        self.manager.startUpdatingLocation()
    }
    
    func stopUpdating() {
        self.manager.stopUpdatingLocation()
    }
    
    func latitude() -> Double {
        if let latitude = self.manager.location?.coordinate.latitude {
            return latitude
        }
        else {
            return 0.0
        }
    }
    
    func longitude() -> Double {
        if let longitude = self.manager.location?.coordinate.longitude {
            return longitude
        }
        else {
            return 0.0
        }
    }
    
    func altitude() -> Double {
        if let altitude = self.manager.location?.altitude {
            return altitude
        }
        else {
            return 0.0
        }
    }
    
    func location() -> CLLocation? {
        if let location = self.manager.location {
            return location
        }
        else {
            return nil
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.isUpdating = true
        self.updateDelegate?.didUpdateLoction()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.isUpdating = false
        self.updateDelegate?.didFailUpdatingWithError(error: error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationDelegate?.authorizationStatusChanged()
    }
    
}
