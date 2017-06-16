//
//  MapViewController.swift
//  SoLoMoSample
//
//  Created by Miko Halevi on 3/7/17.
//  Copyright © 2017 Miko Halevi. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: - Properties

    @IBOutlet weak var mapView: MKMapView!
    private var restaurants: [Restaurant]?
    private var isTappable: Bool = true
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeMapView()
    }
    
    // MARK: - Public
    
    func set(title: String ,restaurants: [Restaurant]?, isTappable: Bool){
        self.title = title
        self.restaurants = restaurants
        self.isTappable = isTappable
    }
    
    // MARK: - Actions
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController!.popViewController(animated: true)
    }

    // MARK: - MKMapView
    
    func initializeMapView(){
        if let restaurants = restaurants{
            var annotations: [MKAnnotation] = []
            for restaurant in restaurants {
                let annotation = RestaurantAnnotation(withRestaurant: restaurant)
                annotations.append(annotation)
            }
            mapView.addAnnotations(annotations)
            mapView.showAnnotations(annotations, animated: true)
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "view")
        view.canShowCallout = true
        view.annotation = annotation
        if isTappable {
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let restaurantAnnotation = view.annotation as? RestaurantAnnotation,
            let singleRestaurantController = storyboard?.instantiateViewController(withIdentifier: SingleRestaurantViewController.stringFromClass()) as? SingleRestaurantViewController {
            singleRestaurantController.restaurant = restaurantAnnotation.restaurant
            navigationController?.pushViewController(singleRestaurantController, animated: true)
        }
    }
 
}
