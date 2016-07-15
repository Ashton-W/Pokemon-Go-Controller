//
//  ViewController.swift
//  PokemonController-Mac
//
//  Created by Ashton Williams on 11/07/2016.
//  Copyright © 2016 Ka Ho. All rights reserved.
//

import Cocoa
import MapKit
import GCDWebServer

class MacViewController: NSViewController, MKMapViewDelegate {

    @IBOutlet var mapView: MKMapView!
    var currentLocation:CLLocationCoordinate2D!
    //let moveInterval = 0.00005
    var webServer:GCDWebServer = GCDWebServer()
    
    func moveInterval() -> Double {
        return Double("0.0000\(40 + (rand() % 20))")!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getSavedLocation() ? showMapOnLocation() : ()
    
        startWebServer()
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        currentLocation = mapView.centerCoordinate
        saveLocation()
    }
    
    func changeCurrentLocation(direction:String) {
        
        direction == "left" ? currentLocation = CLLocationCoordinate2D(latitude: currentLocation.latitude, longitude: currentLocation.longitude - moveInterval()) : ()
        direction == "right" ? currentLocation = CLLocationCoordinate2D(latitude: currentLocation.latitude, longitude: currentLocation.longitude + moveInterval()) : ()
        direction == "up" ? currentLocation = CLLocationCoordinate2D(latitude: currentLocation.latitude + moveInterval(), longitude: currentLocation.longitude) : ()
        direction == "down" ? currentLocation = CLLocationCoordinate2D(latitude: currentLocation.latitude - moveInterval(), longitude: currentLocation.longitude) : ()
        
        saveLocation()
        showMapOnLocation()
    }
    
    func showMapOnLocation() {
        mapView.setCamera(MKMapCamera(lookingAtCenterCoordinate: currentLocation, fromEyeCoordinate: currentLocation, eyeAltitude: 500.0), animated: false)
    }
    
    func saveLocation() {
        NSUserDefaults.standardUserDefaults().setObject(getCurrentLocationDict(), forKey: "savedLocation")
        NSUserDefaults.standardUserDefaults().synchronize()
        print("saved location")
        
        generateGPX()
        runXcodeAppleScript()
    }
    
    func getSavedLocation() -> Bool {
        guard let savedLocation = NSUserDefaults.standardUserDefaults().objectForKey("savedLocation") else {
            return false
        }
        return putCurrentLocationFromDict(savedLocation as! [String : String])
    }
    
    func getCurrentLocationDict() -> [String:String] {
        return ["lat":"\(currentLocation.latitude)", "lng":"\(currentLocation.longitude)"]
    }
    
    func putCurrentLocationFromDict(dict: [String:String]) -> Bool {
        currentLocation = CLLocationCoordinate2D(latitude: Double(dict["lat"]!)!, longitude: Double(dict["lng"]!)!)
        return true
    }
    
    @IBAction override func moveUp(sender: AnyObject?) {
        changeCurrentLocation("up")
    }
    
    @IBAction override func moveDown(sender: AnyObject?) {
        changeCurrentLocation("down")
    }
    
    @IBAction override func moveLeft(sender: AnyObject?) {
        changeCurrentLocation("left")
    }
    
    @IBAction override func moveRight(sender: AnyObject?) {
        changeCurrentLocation("right")
    }
    
    func startWebServer(){
        webServer.addDefaultHandlerForMethod("GET", requestClass: GCDWebServerRequest.self, processBlock: {request in
            return GCDWebServerDataResponse.init(JSONObject: self.getCurrentLocationDict())
        })
        webServer.startWithPort(8081, bonjourName: "pokemonController")
    }
    
    func runXcodeAppleScript() {
        let script = NSAppleScript(contentsOfURL: NSBundle.mainBundle().URLForResource("XcodeSimulateLocation", withExtension: "applescript")!, error: nil)
        script?.executeAndReturnError(nil)
    }
    
    func generateGPX() {
        let string = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>\n<gpx>\n    \n    <wpt lat=\"\(currentLocation.latitude)\" lon=\"\(currentLocation.longitude)\">\n        <name>Pokemon</name>\n    </wpt>\n    \n</gpx>\n"
        
        try! string.writeToFile("/Users/AshtonWilliams/Desktop/pokemon.gpx", atomically: true, encoding: NSUTF8StringEncoding)
    }
    
}

