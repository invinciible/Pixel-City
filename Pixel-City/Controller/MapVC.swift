//
//  ViewController.swift
//  Pixel-City
//
//  Created by Tushar Katyal on 23/08/17.
//  Copyright © 2017 Tushar Katyal. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController , UIGestureRecognizerDelegate{
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpViewHeight: NSLayoutConstraint!
    @IBOutlet weak var pullUpView: UIView!
    
    var spinner : UIActivityIndicatorView?
    var progressLabel : UILabel?
    var collectionView : UICollectionView?
    var flowLayout = UICollectionViewFlowLayout()
    
    var imgUrlArray = [String]()
    var imageArray = [UIImage]()
    var screenSize = UIScreen.main.bounds
    var locationManager = CLLocationManager()
    let authStatus = CLLocationManager.authorizationStatus()
    let regionRadius : Double = 1000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        configureLocationServices()
        addDoubleTap()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotosCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.backgroundColor = #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        pullUpView.addSubview(collectionView!)
    }

    func addDoubleTap() {
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
    }
    
    func addSwipe(){
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
    func animatedViewUp() {
        pullUpViewHeight.constant = 300
        UIView.animate(withDuration: 0.3) {
           self.view.layoutIfNeeded()
        }
    }
    @objc func animateViewDown(){
        cancelAllSessions() // to cancel the images downloading
        
        pullUpViewHeight.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner(){
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width / 2) - ((spinner?.frame.width)! / 2), y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
        
    }

    func removeSpinner(){
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLabel(){
        progressLabel = UILabel()
        progressLabel?.frame = CGRect(x: ((screenSize.width / 2) - 120), y: 175, width: 240, height: 40)
        progressLabel?.font = UIFont(name: "Avenir Next", size: 16)
        progressLabel?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLabel?.textAlignment = .center
//        progressLabel?.text = "downloaded 12/14"
        collectionView?.addSubview(progressLabel!)
    }
    func removeProgressLabel(){
        if progressLabel != nil {
            progressLabel?.removeFromSuperview()
        }
    }
    
    @IBAction func centerMapBtnPressed(_ sender: Any) {
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            
            centerMapOnLocation()
        }
    }
    
}

extension MapVC : MKMapViewDelegate {
    
    // to center the user location 
    func centerMapOnLocation() {
        guard let coordinate = locationManager.location?.coordinate else {return}
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadius*2.0, regionRadius*2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func dropPin(sender : UITapGestureRecognizer) {
        removePin()
        removeSpinner()
        removeProgressLabel()
        cancelAllSessions() // if user drop the pin again
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadius*2, regionRadius*2)
        mapView.setRegion(coordinateRegion, animated: true)
        
        recieveUrls(forAnnotation: annotation) { (success) in
            
            if success {
                self.retrieveImages(handler: { (success) in
                    
                    if success {
                        self.removeSpinner()
                        self.removeProgressLabel()
                        self.collectionView?.reloadData()
                    }
                })
            }
        }
        
        animatedViewUp()
        addSwipe()
        addSpinner()
        addProgressLabel()
    }
    
    // for orange pin (custom pin)
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func removePin() {
        for annonation in mapView.annotations {
            mapView.removeAnnotation(annonation)
        }
    }
    
    func recieveUrls(forAnnotation annotation :DroppablePin, handler: @escaping (_ status :Bool) ->()) {
        imgUrlArray.removeAll()
        
        Alamofire.request(flickrURL(forApiKey: API_KEY, withAnnotation: annotation, andNumberOfPhotos: 40)).responseJSON { (response) in
            if response.result.error == nil {
                
                guard let json = response.result.value as? Dictionary<String,AnyObject> else {return}
                
                let photosDict = json["photos"] as! Dictionary<String,AnyObject>
                let photoArray = photosDict["photo"] as! [Dictionary<String,AnyObject>]
                
                    for photo in photoArray {
                    
                        let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                        self.imgUrlArray.append(postUrl)
                    }
            handler(true)
            } else {
                handler(false)
                debugPrint(response.result.error as Any)
            }
        }
        }
    func retrieveImages(handler : @escaping (_ status : Bool) -> ())
    {
        imageArray.removeAll()
        for url in imgUrlArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                if response.result.error == nil {
                    guard let image = response.result.value else {return}
                    self.imageArray.append(image)
                    self.progressLabel?.text = "\(self.imageArray.count)/40 IMAGES DOWNLOADED"
                    if self.imageArray.count == self.imgUrlArray.count{
                        handler(true)
                    }
                } else {
                    debugPrint(response.result.error as Any)
                    handler(false)
                }
            })
        }
    }
    
    func cancelAllSessions(){
        
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadTask, downloadData) in
            sessionDataTask.forEach({$0.cancel()})
            downloadData.forEach({$0.cancel()})
        }
    }
}

extension MapVC : CLLocationManagerDelegate {
    
    func configureLocationServices() {
        if authStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
        
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        centerMapOnLocation()
    }
}

extension MapVC : UICollectionViewDelegate,UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotosCell{
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
}
