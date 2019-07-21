//
//  SensorsViewController.swift
//  MDProject
//
//  Created by Loris D'Auria on 20/06/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import Foundation
import UIKit
import ARKit


extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}


@available(iOS 11.3, *)
class SensorsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var SensorsTable: UITableView!
    
    @IBOutlet weak var startButton: UIButton!
    
    var profile: Profile = Profile()
    
    var sessionName: String = ""
    
    var serverAddress: String = ""
    
    var serverPort: Int = 0

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ServerCell", for: indexPath) as? ServerParametersInfoTableCell{
            // indexPath[0] is the table section indexPath[1] is the section index
            // if 0 we're in server parameters
            if indexPath[0] == 0{
                if indexPath[1] == 0 {
                    cell.parameterLabel.text = "Server: "
                    cell.valueLabel.text = self.profile.serverAddress + ":" + String(self.profile.serverPort)
                } else if indexPath[1] == 1 {
                    cell.parameterLabel.text = "Session Name: "
                    cell.valueLabel.text = self.profile.sessionName
                }
                return cell
            }
            
        }
        
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SensorCell", for: indexPath) as? SensorTableCell{
            // indexPath[0] is the table section indexPath[1] is the section index
            // if 1 we're in sensors parameters
            if indexPath[0] == 1{
                cell.SensorLabel.text = self.profile.sensorList.sensorList[indexPath[1]].name
                cell.SensorSwitch.setOn(self.profile.sensorList.sensorList[indexPath[1]].status, animated: true)
                cell.SensorSwitch.addTarget(self, action: #selector(switchAction), for: .touchUpInside)
                cell.SensorSwitch.tag = indexPath[1]
                return cell
            }
            
        }
        return UITableViewCell()
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Selected sensor ", self.profile.sensorList.sensorList[indexPath[1]].name, ". Status: ", self.profile.sensorList.sensorList[indexPath[1]].status)
        if indexPath[0] == 0 {
            switch indexPath[1] {
            case 0:
                performSegue(withIdentifier: "goToSensorsInfoViewController", sender: "Server")
            case 1:
                performSegue(withIdentifier: "goToSensorsInfoViewController", sender: "Session")
            default:
                return
            }
        } else {
            performSegue(withIdentifier: "goToSensorsInfoViewController", sender: profile.sensorList.sensorList[indexPath[1]].name)
        }
        
    }
    
    @objc func serverButtonAction(sender: UIButton!) {
        performSegue(withIdentifier: "goToSensorsInfoViewController", sender: "Server")
        print("Button tapped")
    }
    
    @objc func sessionButtonAction(sender: UIButton!) {
        performSegue(withIdentifier: "goToSensorsInfoViewController", sender: "Session")
        print("Button tapped")
    }
    
    @objc func buttonAction(sender: UIButton!) {
        
        print("Button tapped")
    }
    
    @objc func switchAction(sender: UISwitch!) {
        let sensorName = self.profile.sensorList.sensorList[sender.tag].name
        let sensorStatus = self.profile.sensorList.sensorList[sender.tag].status
        if sensorName == "Video Frames" && !ARConfiguration.isSupported {
            //sender!.isOn = false
            sender!.setOn(false, animated: true)
            self.arkitNotAvailableAlert()
        }
        else if sensorStatus {
            self.profile.sensorList.sensorList[sender.tag].status = false
        } else {
            self.profile.sensorList.sensorList[sender.tag].status = true
        }
    }
    
    func arkitNotAvailableAlert() {
        let alert = UIAlertController(title: "ArKit alert", message: "ArKit not available, ios 11.0+ required", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (action) -> Void in
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        } else if section == 1 {
            return profile.sensorList.sensorList.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String!{
        if (section == 0){
            return "Server & UI"
        }
        if (section == 1){
            return "Sensors"
        }
        return ""
    }
    
    func tableView (tableView:UITableView , heightForHeaderInSection section:Int)->Float
    {
        
        var title = self.tableView(tableView: tableView, titleForHeaderInSection: section)
        if (title == "") {
            return 0.0
        }
        return 20.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.profile = delegate.profile
        self.profile.sensorList = self.profile.sensorList //delegate.sensorList
        self.serverAddress = self.profile.serverAddress  //delegate.serverAddress
        self.serverPort = self.profile.serverPort //delegate.serverPort
        self.sessionName = self.profile.sessionName //delegate.sessionName
        print("Loaded sensorlist in controller. Number of sensors: ",profile.sensorList.sensorList.count )
        self.hideKeyboardWhenTappedAround()
        self.navigationItem.setHidesBackButton(true, animated:true);
        self.SensorsTable.dataSource = self
        self.SensorsTable.delegate = self
        print("Sensors view loaded")
        
    }
    
    @IBAction func saveProfile(_ sender: Any) {
        //1. Create the alert controller.
        var alert = UIAlertController(title: "Save Profile", message: "Enter profile name", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.text = ""
        })
        
        //3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (action) -> Void in
            let textField = alert!.textFields![0] as UITextField
            print("Text field: \(textField.text)")
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { [weak alert] (action) -> Void in
            let textField = alert!.textFields![0] as UITextField
            print("Text field: \(textField.text)")
        }))
        
        //4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func writeProfile(profileName: String) {
        
    }
    
    //TODO REPLACE WITH A SEGUE IN THE STORYBOARD
    @IBAction func startGather(_ sender: Any) {
        self.performSegue(withIdentifier: "goToStart", sender: sender)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToSensorsInfoViewController"{
            // TODO AS? STRING WILL HAVE TO BE CHANGED WITH AS? [CLASS FOR THE BUTTONS STRUCTURE]
            if let sensorTapped = sender as? String{
                if let destinationVC = segue.destination as? SensorssInfoViewController{
                        print("Sensor Tapped: ", sensorTapped)
                        destinationVC.profile = self.profile
                        destinationVC.sensorTitle = sensorTapped
                        destinationVC.navigationItem.title = sensorTapped
                    }
                }
            }
        
            
        else if segue.identifier == "goToStart"{
            if #available(iOS 11.3, *) {
                if let destinationVC = segue.destination as? ViewController{
                    destinationVC.profile = self.profile
                    //                destinationVC.sensorList = profile.sensorList
                    //                destinationVC.sessionName = self.sessionName
                }
            } else {
                // Fallback on earlier versions
            }
        }
        
    }
    
    

    
    
}
