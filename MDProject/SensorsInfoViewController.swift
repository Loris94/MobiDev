//
//  SensorsInfoViewController.swift
//  MDProject
//
//  Created by Loris D'Auria on 21/06/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import Foundation
import UIKit
import ARKit

@available(iOS 11.3, *)
class SensorssInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate  {
    
    var profile: Profile = Profile()
    var sensorTitle: String = ""
    
    
    @IBOutlet weak var infoTable: UITableView!

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.sensorTitle == "Server" {
            return 2
        } else if self.sensorTitle == "Session" {
            return 1
        } else {
            return self.profile.sensorList.getByName(name: self.sensorTitle)!.parameters.count
        }

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        if self.sensorTitle == "Server" {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SensorInfoCell", for: indexPath) as? SensorInfoTableCell{
                cell.infoText.delegate = self
                if indexPath[1] == 0 {
                    cell.infoLabel.text = "Address"
                    cell.infoText.text = self.profile.serverAddress
                    cell.infoText.tag = 0
                    // cell keyb
                } else if indexPath[1] == 1 {
                    cell.infoLabel.text = "Port"
                    cell.infoText.text = String(self.profile.serverPort)
                    cell.infoText.tag = 1

                }
                return cell
                
            }
        } else if self.sensorTitle == "Session" {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SensorInfoCell", for: indexPath) as? SensorInfoTableCell{
                cell.infoText.delegate = self
                cell.infoLabel.text = "Session Name"
                cell.infoText.text = self.profile.sessionName
                cell.infoText.tag = 0
                return cell
                
            }
        } else if self.sensorTitle == "Video Frames" {
            let sortedDictionary = Array(self.profile.sensorList.getByName(name: sensorTitle)!.parameters.keys).sorted()
            let key = sortedDictionary[indexPath[1]]
            if key == "FPS"{
                if let cell = tableView.dequeueReusableCell(withIdentifier: "SensorInfoSliderCell", for: indexPath) as? SensorInfoWithSliderCell{
                    cell.infoLabel.text = "FPS"
                    cell.valueLabel.text = String( Int (self.profile.sensorList.getByName(name: sensorTitle)!.parameters[key] as! Double ) )
                    cell.slider.maximumValue = 60
                    cell.slider.minimumValue = 1
                    cell.slider.setValue(Float( Int (self.profile.sensorList.getByName(name: sensorTitle)!.parameters[key] as! Double) ), animated: true)
                    cell.slider.tag = indexPath[1]
                    return cell
                }
            } else if key == "Resolution" {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "SensorInfoStepperCell", for: indexPath) as? SensorInfoStepperCell{
                    
                    var resolutionsArray = ARWorldTrackingConfiguration.supportedVideoFormats
                    resolutionsArray.reverse()
                    
                    cell.infoLabel.text = "Resolution"
                    let value = Int(self.profile.sensorList.getByName(name: "Video Frames")?.parameters["Resolution"] as! Double)
                    
                    let h = Int(resolutionsArray[value].imageResolution.height)
                    let w = Int(resolutionsArray[value].imageResolution.width)
                    cell.valueLabel.text = String(w) + "x" + String(h)
                    cell.stepper.tag = indexPath[1]
                    cell.stepper.minimumValue = 0
                    cell.stepper.maximumValue = Double(resolutionsArray.count-1)
                    cell.stepper.value = Double(value)
                    return cell
                }
            } else if key == "Compression" {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "SensorInfoSliderCell", for: indexPath) as? SensorInfoWithSliderCell{
                    
                    cell.infoLabel.text = "Compression"
                    let value = self.profile.sensorList.getByName(name: "Video Frames")?.parameters["Compression"] as! Double
                    cell.valueLabel.text = String(round(value*10)/10)
                    cell.slider.tag = indexPath[1]
                    cell.slider.minimumValue = 0
                    cell.slider.maximumValue = 1
                    cell.slider.setValue(Float( value ), animated: true)
                    return cell
                }
            }
            
            
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "SensorInfoCell", for: indexPath) as? SensorInfoTableCell{
                cell.infoText.keyboardType = UIKeyboardType.numbersAndPunctuation
                cell.infoText.delegate = self
                // TODO CHANGE KEYBOARD TYPE IF THE TARGET NEEDS A STRING / ENUM
                let sortedDictionary = Array(self.profile.sensorList.getByName(name: sensorTitle)!.parameters.keys).sorted()
                //cell.infoLabel.text = Array(self.profile.sensorList.getByName(name: sensorTitle)!.parameters)[indexPath[1]].key
                cell.infoLabel.text = sortedDictionary[indexPath[1]]
                let value = self.profile.sensorList.getByName(name: sensorTitle)!.parameters[sortedDictionary[indexPath[1]]] as! Double
                cell.infoText.text = String(value)
                cell.infoText.tag = indexPath[1]
            
                return cell
            }
        }
        return UITableViewCell()
    }
    
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        let slider = sender as! UISlider
        print(slider.value)
        let sortedDictionary = Array(self.profile.sensorList.getByName(name: sensorTitle)!.parameters.keys).sorted()
        let arrayindex = sortedDictionary[slider.tag]
        
        let cell = self.infoTable.cellForRow(at: [0,slider.tag]) as? SensorInfoWithSliderCell
        if cell?.infoLabel.text == "Compression"{
            self.profile.sensorList.getByName(name: self.sensorTitle)?.parameters[arrayindex] = Double( round(slider.value*10)/10 )
        } else if cell?.infoLabel.text == "FPS" {
            self.profile.sensorList.getByName(name: self.sensorTitle)?.parameters[arrayindex] = Double(slider.value)
        }
    }
    
    
    @IBAction func stepperValueChanged(_ sender: Any) {
        let stepper = sender as! UIStepper
        print(stepper.value)
        let sortedDictionary = Array(self.profile.sensorList.getByName(name: sensorTitle)!.parameters.keys).sorted()
        let arrayindex = sortedDictionary[stepper.tag]
        
        self.profile.sensorList.getByName(name: self.sensorTitle)?.parameters[arrayindex] = Double(stepper.value)
        
        let cell = self.infoTable.cellForRow(at: [0,stepper.tag]) as? SensorInfoStepperCell
        if cell?.infoLabel.text == "Resolution"{
            var resolutionsArray = ARWorldTrackingConfiguration.supportedVideoFormats
            resolutionsArray.reverse()
            let h = Int(resolutionsArray[Int(stepper.value)].imageResolution.height)
            let w = Int(resolutionsArray[Int(stepper.value)].imageResolution.width)
            cell?.valueLabel.text = String(w) + "x" + String(h)
        }
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if self.sensorTitle == "Server" {
            // TODO add constraints for differents type of data
            if textField.tag == 0 {
                self.profile.serverAddress = text
            } else if textField.tag == 1 {
                if Int(text) == nil {
                    return false
                }
                self.profile.serverPort = Int(text)!
            }
            return true
        } else if self.sensorTitle == "Session" {
            self.profile.sessionName = text
            return true
        } else {
            let infoName = Array(self.profile.sensorList.getByName(name: sensorTitle)!.parameters)[textField.tag].key
            if let doubleVal = Double(text) {
                
                self.profile.sensorList.getByName(name: sensorTitle)!.parameters.updateValue(doubleVal, forKey: infoName)
                
            } else if string == "" {
                
                self.profile.sensorList.getByName(name: sensorTitle)!.parameters.updateValue(0.1, forKey: infoName)
                return true
            } else {
                
                let value = self.profile.sensorList.getByName(name: sensorTitle)!.parameters[infoName] as? Double
                textField.text = String(value!)
                return false
            }
            
            return true
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        self.infoTable.dataSource = self
        self.infoTable.delegate = self
        print("SensorsInfo view loaded: ", self.sensorTitle)
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "goToSensorsViewController"{
            if let destinationVC = segue.destination as? SensorsViewController{
                //destinationVC.self.profile.sensorList = self.self.profile.sensorList
                print("sending server port: ", self.self.profile.serverPort)
                destinationVC.profile = self.profile
            }
        }
    }
    
    
    
    
    
}
