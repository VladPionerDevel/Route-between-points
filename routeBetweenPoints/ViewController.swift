//
//  ViewController.swift
//  routeBetweenPoints
//
//  Created by pioner on 17.01.2022.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    var mapView: MKMapView = {
        var mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        return mapView
    }()
    
    var addAddresButton: UIButton = {
        var button = UIButton()
        button.setTitle("Add addres", for: .normal)
        button.backgroundColor = .red
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 10
        return button
    }()
    
    var routeButton: UIButton = {
        var button = UIButton()
        button.setTitle("Route", for: .normal)
        button.backgroundColor = .red
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 10
        button.isHidden = true
        return button
    }()
    
    var resetButton: UIButton = {
        var button = UIButton()
        button.setTitle("Reset", for: .normal)
        button.backgroundColor = .red
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 10
        button.isHidden = true
        return button
    }()
    
    private var anotationsArray = [MKPointAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        setConstraints()
        
        addAddresButton.addTarget(self, action: #selector(addAddresButtonTapped), for: .touchUpInside)
        routeButton.addTarget(self, action: #selector(routeButtonTapped), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        
        let gesterTapMap = UITapGestureRecognizer(target: self, action: #selector(mapTapped(gestureRecognize:)))
        self.mapView.addGestureRecognizer(gesterTapMap)
        
    }
    
    @objc func mapTapped(gestureRecognize: UITapGestureRecognizer){
        let touchPoint = gestureRecognize.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        let location = CLLocation(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude)
        
        setupPlacemark(location: location)
    }
    
    @objc func addAddresButtonTapped() {
        alertAddAddres(title: "Добавить", placeholder: "Введите адрес") { [self] (text) in
            setupPlacemark(addresPlace: text)
            serchAddress(addresPlace: text)
        }
    }
    
    @objc func routeButtonTapped() {
        
        for index in 0...anotationsArray.count - 2 {
            createDirectionRequest(startCoordinate: anotationsArray[index].coordinate, desdinationCoordinate: anotationsArray[index + 1].coordinate)
        }
        
        mapView.showAnnotations(anotationsArray, animated: true)
    }
    
    @objc func resetButtonTapped() {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        anotationsArray = [MKPointAnnotation]()
        routeButton.isHidden = true
        resetButton.isHidden = true
    }
    
    private func serchAddress(addresPlace: String){
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = addresPlace
        searchRequest.region = mapView.region
        
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unknown error").")
                return
            }

            print(response.mapItems)
            for item in response.mapItems {
                
                print(item.name ?? "No name.")
            }
        }
    }
    
    private func setupPlacemark(addresPlace: String){
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(addresPlace) { [weak self] (placemarks, error) in
            
            guard let self = self else {return}
            
            if let error = error {
                print(error)
                self.alertError(title: "Ошибка", message: "Сервер недоступен. Попробуйте ввести адрес еще раз")
                return
            }
            
            guard let placemarks = placemarks else {
                return
            }
            let placemark = placemarks.first
            
            let anotation = MKPointAnnotation()
            anotation.title = "\(addresPlace)"
            guard let placemarkLocation = placemark?.location else {
                return
            }
            anotation.coordinate = placemarkLocation.coordinate
            
            self.anotationAppend(anotation: anotation)
        }
    }
    
    private func setupPlacemark(location: CLLocation){
        let anotation = MKPointAnnotation()
        anotation.coordinate = location.coordinate
        anotation.title = ""
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self,weak anotation] (placemarks, error) in
            
            if let error = error {
                print(error)
                guard let self = self else {return}
                self.alertError(title: "Ошибка", message: "Сервер недоступен. Попробуйте ввести адрес еще раз")
                return
            }
            
            guard let placeMark = placemarks?.first else {return}
            
            if let name = placeMark.name {
                if let anotation = anotation {
                    anotation.title = name
                }
            }
        }
        
        anotationAppend(anotation: anotation)
    }
    
    private func anotationAppend(anotation: MKPointAnnotation){
        anotationsArray.append(anotation)
        
        if anotationsArray.count >= 2 {
            routeButton.isHidden = false
            resetButton.isHidden = false
        }
        
        mapView.showAnnotations(anotationsArray, animated: true)
    }
    
    private func createDirectionRequest(startCoordinate: CLLocationCoordinate2D, desdinationCoordinate: CLLocationCoordinate2D){
        
        let startLocation = MKPlacemark(coordinate: startCoordinate)
        let destinationLocation = MKPlacemark(coordinate: desdinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startLocation)
        request.destination = MKMapItem(placemark: destinationLocation)
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        
        let direction = MKDirections(request: request)
        direction.calculate { (response, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let response = response else {
                self.alertError(title: "Ошибка", message: "Маршрут не доступен")
                return
            }
            
            var minRoute = response.routes[0]
            for route in response.routes {
                minRoute = (route.distance < minRoute.distance) ? route : minRoute
            }
            
            self.mapView.addOverlay(minRoute.polyline)
        }
        
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .red
        return renderer
    }
}

extension ViewController {
    
    func setConstraints() {
        
        view.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
            mapView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
            mapView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
            mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
        ])
        
        mapView.addSubview(addAddresButton)
        NSLayoutConstraint.activate([
            addAddresButton.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 50),
            addAddresButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -40),
            addAddresButton.widthAnchor.constraint(equalToConstant: 110),
            addAddresButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        mapView.addSubview(routeButton)
        NSLayoutConstraint.activate([
            routeButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -50),
            routeButton.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 20),
            routeButton.widthAnchor.constraint(equalToConstant: 100),
            routeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        mapView.addSubview(resetButton)
        NSLayoutConstraint.activate([
            resetButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -50),
            resetButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
            resetButton.widthAnchor.constraint(equalToConstant: 100),
            resetButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
}

