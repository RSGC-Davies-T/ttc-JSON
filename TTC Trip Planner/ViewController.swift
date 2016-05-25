//
//  ViewController.swift
//  TTC Trip Planner
//
//  Created by Tommy Davies on 2016-05-20.
//  Copyright © 2016 Tommy Davies. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import Foundation


// Allow for degrees <--> radians conversions
extension Double {
    var degreesToRadians: Double { return self * M_PI / 180 }
    var radiansToDegrees: Double { return self * 180 / M_PI }
}

// An extension is a Swift language construct that, as the name implies,
// allows you to extend, or add functionality to, an existing type or class.
// In this case, we are adding functionality to the UIView class.
//
// Note that UIView class is a super-class for all the UI elements we are using
// here (UILabel, UITextField, UIButton).
// So if we write an extension for UIView, all the sub-classes of UIView have this
// new functionality as well.
extension UIView {
    
    // A convenience function that saves us directly invoking the rather verbose
    // NSLayoutConstraint initializer on each and every object in the interface.
    func centerHorizontallyInSuperview(){
        let c: NSLayoutConstraint = NSLayoutConstraint(item: self,
                                                       attribute: NSLayoutAttribute.CenterX,
                                                       relatedBy: NSLayoutRelation.Equal,
                                                       toItem: self.superview,
                                                       attribute: NSLayoutAttribute.CenterX,
                                                       multiplier:1,
                                                       constant: 0)
        
        // Add this constraint to the superview
        self.superview?.addConstraint(c)
        
    }
    
}

 
class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate, MKMapViewDelegate, UITableViewDelegate,UITableViewDataSource {
    let sampleTextField = UITextField(frame: CGRectMake(20, 100, 300, 40))
    // Views that need to be accessible to all methods
    let jsonResult = UILabel()
    var platformCount = 0
    var currentPlatform = 0
    var emptyChecker = 0
    var currentRoute = 0
    var routeCount = 0
    var vehicleCount = 0
    var currentVehicle = 0
    var currentShape = String()
    var currentTrain = String()
    var routeName = String()
    var routeCounter = 0
    var tableView: UITableView  =   UITableView()
    var routes : [String] = [""]
    var stationEntered = false
    var nameOfStation = String()
     // If data is successfully retrieved from the server, we can parse it here
    func parseMyJSON(theData : NSData) {
        print(nameOfStation)
        // Print the provided data
        print("")
        print("====== the data provided to parseMyJSON is as follows ======")
        print(theData)
        
        // De-serializing JSON can throw errors, so should be inside a do-catch structure
        do {
            
            // Do the initial de-serialization
            let json = try NSJSONSerialization.JSONObjectWithData(theData, options: NSJSONReadingOptions.AllowFragments)
            
            // Print retrieved JSON
            print("")
            //            print("====== the retrieved JSON is as follows ======")
            //            print(json)
            
            // Now we can parse this...
            if let stationPlatforms = json as? [String : AnyObject] {
                platformCount = stationPlatforms["stops"]!.count
                repeat {
                    currentRoute = 0
                    if let vehicles = stationPlatforms["stops"]![currentPlatform] as? [String: AnyObject] {
                        emptyChecker = vehicles["routes"]!.count
                        if emptyChecker != 0 {
//                            routeName = vehicles["name"] as! String
//                            routes.append(routeName)
                            repeat {
                                if let departures = vehicles["routes"]![currentRoute] as? [String: AnyObject] {
                                    routeCount = vehicles["routes"]!.count
                                    currentVehicle = 0
                                    repeat {
                                        if let individualVehicles = departures["stop_times"]![currentVehicle] as? [String: AnyObject] {
                                            vehicleCount = departures["stop_times"]!.count
                                            print("**********")
                                            print(individualVehicles["shape"])
                                            currentShape = individualVehicles["shape"] as! String
                                            print(individualVehicles["departure_time"])
                                            currentTrain = individualVehicles["departure_time"] as! String
                                            switch currentShape {
                                            case "Bloor-Danforth Subway To Kipling Station":
                                                currentShape = "Line 2 West"
                                            case "Bloor-Danforth Subway To Kennedy Station":
                                                currentShape = "Line 2 East"
                                            case "Yonge-University-Spadina Subway To Finch Station":
                                                currentShape = "Line 1 to Finch"
                                            case "Yonge-University-Spadina Subway To Downsview Station":
                                                currentShape = "Line 1 to Downsview"
                                                
                                            case "Sheppard Subway To Sheppard-Yonge Station":
                                                currentShape = "Line 4 west"
                                                
                                            case "Sheppard Subway To Don Mills Station":
                                                currentShape = "Line 4 east"
                                                
                                            case "Scarborough RT To Kennedy Station":
                                                currentShape = "Line 3 west"
                                                
                                            case "Scarborough RT To Kennedy Station":
                                                currentShape = "Line 3 east"
                                            default:
                                                currentShape = individualVehicles["shape"] as! String
                                            }
                                            
                                            routeName += currentShape
                                            routeName += " "
                                            routeName += currentTrain
                                            routes.append(routeName)
                                            //reset this variable after it adds it
                                            routeName = ""
                                            routeCounter += 1
                                            currentVehicle += 1
                                         
                                        } else {
                                            print("could not parse individual arrivals")
                                        }
                                        
                                    } while currentVehicle < vehicleCount
                                   
                                    
                                    
                                } else {
                                    print("could not parse expected time")
                                }
                                currentRoute += 1
                            } while currentRoute < routeCount
                            
                        }
                        //                    } else {
                        //                        print("no route on this line")
                        //                    }
                    } else {
                        print("Can't parse individual routes")
                    }
                    currentPlatform += 1
                    
                } while currentPlatform < platformCount
            } else {
                print("Can't parse individual platforms")
            }
                        dispatch_async(dispatch_get_main_queue()) {
                if self.stationEntered == true{
                self.tableView = UITableView(frame: UIScreen.mainScreen().bounds, style: UITableViewStyle.Plain)
                self.tableView.delegate      =   self
                self.tableView.dataSource    =   self
                self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
                self.view.addSubview(self.tableView)
               
            }
            }
        } catch let error as NSError {
            print ("Failed to load: \(error.localizedDescription)")
        }
        
        
    }
    
    // Set up and begin an asynchronous request for JSON data
    func getMyJSON() {

        let myCompletionHandler : (NSData?, NSURLResponse?, NSError?) -> Void = {
            
            (data, response, error) in
            
            if let r = response as? NSHTTPURLResponse {
                
                // If the request was successful, parse the given data
                if r.statusCode == 200 {
                    if let d = data {
                        // Parse the retrieved data
                        self.parseMyJSON(d)
                    }
                }
                
            }
            
        }
        
        // Define a URL to retrieve a JSON file from
        var address : String = "https://myttc.ca/"
        address += nameOfStation
        address += "_station.json"
        
        // Try to make a URL request object
        if let url = NSURL(string: address) {
            
            // We have an valid URL to work with
            print(url)
            
            // Now we create a URL request object
            let urlRequest = NSURLRequest(URL: url)
            
            // Now we need to create an NSURLSession object to send the request to the server
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: config)
            
            // Now we create the data task and specify the completion handler
            let task = session.dataTaskWithRequest(urlRequest, completionHandler: myCompletionHandler)
            
            // Finally, we tell the task to start (despite the fact that the method is named "resume")
            task.resume()
            
        } else {
            
            // The NSURL object could not be created
            print("Error: Cannot create the NSURL object.")
        }
    }

    // This is the method that will run as soon as the view controller is created
    override func viewDidLoad() {

        // Sub-classes of UIViewController must invoke the superclass method viewDidLoad in their
        // own version of viewDidLoad()
        super.viewDidLoad()
       
            sampleTextField.placeholder = "Enter station here"
        sampleTextField.font = UIFont.systemFontOfSize(15)
        sampleTextField.borderStyle = UITextBorderStyle.RoundedRect
        sampleTextField.autocorrectionType = UITextAutocorrectionType.No
        sampleTextField.keyboardType = UIKeyboardType.Default
        sampleTextField.returnKeyType = UIReturnKeyType.Done
        sampleTextField.clearButtonMode = UITextFieldViewMode.WhileEditing;
        sampleTextField.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
        sampleTextField.delegate = self
        self.view.addSubview(sampleTextField)
        // This is required to lay out the interface elements
        view.translatesAutoresizingMaskIntoConstraints = false
        
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
             return routes.count
        
       
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
        let cell:UITableViewCell=UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cell")
    
            cell.textLabel!.text = routes [indexPath.row]
            return cell;

           }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        print(routes[indexPath.row])
        
    
    }
    func textFieldDidBeginEditing(textField: UITextField) {
        print("TextField did begin editing method called")
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        print("TextField did end editing method called")
        
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        print("TextField should begin editing method called")
        return true;
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        print("TextField should clear method called")
        return true;
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        print("TextField should snd editing method called")
        stationEntered = true
        nameOfStation = sampleTextField.text!
        print(nameOfStation)
        getMyJSON()
        return true;
        
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        print("While entering the characters this method gets called")
        return true;
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        print("TextField should return method called")
        textField.resignFirstResponder();
        return true;
    }
}