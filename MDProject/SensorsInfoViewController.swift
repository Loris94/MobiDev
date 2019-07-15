//
//  SensorsInfoViewController.swift
//  MDProject
//
//  Created by Loris D'Auria on 21/06/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 11.0, *)
class SensorssInfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    var profile: Profile = Profile()
    var sensorTitle: String = ""
    
    
    @IBOutlet weak var infoTable: UITableView!
    @IBOutlet weak var doneButton: UIButton!
    
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
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SensorInfoCell", for: indexPath) as? SensorInfoTableCell{
            
            if self.sensorTitle == "Server" {
                if indexPath[1] == 0 {
                    cell.infoLabel.text = "Address"
                    cell.infoText.delegate = self
                    cell.infoText.text = self.profile.serverAddress
                    cell.infoText.tag = 0
                    // cell keyb
                } else if indexPath[1] == 1 {
                    cell.infoLabel.text = "Port"
                    cell.infoText.delegate = self
                    cell.infoText.text = String(self.profile.serverPort)
                    cell.infoText.tag = 1

                }
                return cell
            } else if self.sensorTitle == "Session" {
                cell.infoLabel.text = "Session Name"
                cell.infoText.delegate = self
                cell.infoText.text = self.profile.sessionName
                cell.infoText.tag = 0
                return cell
            } else {
                cell.infoText.delegate = self
                // TODO CHANGE KEYBOARD TYPE IF THE TARGET NEEDS A STRING / ENUM
                
                cell.infoLabel.text = Array(self.profile.sensorList.getByName(name: sensorTitle)!.parameters)[indexPath[1]].key
                
                let value = Array(self.profile.sensorList.getByName(name: sensorTitle)!.parameters)[indexPath[1]].value as! Double
                cell.infoText.text = String(value)
                cell.infoText.tag = indexPath[1]
                
                return cell
            }
            
            
        }
        
        return UITableViewCell()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Find out what the text field will be after adding the current edit
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
            // TODO - Fix if the user press ENTER. the session is not saved correctly
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
