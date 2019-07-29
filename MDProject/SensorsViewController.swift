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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ServerCell", for: indexPath) as? ServerParametersInfoTableCell{
            // indexPath[0] is the table section indexPath[1] is the section index
            // if 0 we're in server parameters
            if indexPath[0] == 0{
                if indexPath[1] == 0 {
                    cell.parameterLabel.text = "Server: "
                    cell.valueLabel.text = self.profile.serverAddress + ":" + String(self.profile.serverPort)
                    cell.infoButton.addTarget(self, action: #selector(serverButtonAction), for: .touchUpInside)
                } else if indexPath[1] == 1 {
                    cell.parameterLabel.text = "Session Name: "
                    cell.valueLabel.text = self.profile.sessionName
                    cell.infoButton.addTarget(self, action: #selector(sessionButtonAction), for: .touchUpInside)
                }
                let image = UIImage(named: "forward_icon.png")?.withRenderingMode(.alwaysTemplate)
                let imageHeight = cell.infoButton.bounds.size.width-image!.size.height*0.25
                let imageWidth = cell.infoButton.bounds.size.width-image!.size.width*0.25
                cell.infoButton.imageEdgeInsets = UIEdgeInsets(top: imageHeight, left: imageWidth, bottom: imageHeight, right: imageWidth)
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
                cell.SensorInfoButton.tag = indexPath[1]
                cell.SensorInfoButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
                let image = UIImage(named: "forward_icon.png")?.withRenderingMode(.alwaysTemplate)
                let imageHeight = cell.SensorInfoButton.bounds.size.width-image!.size.height*0.25
                let imageWidth = cell.SensorInfoButton.bounds.size.width-image!.size.width*0.25
                cell.SensorInfoButton.imageEdgeInsets = UIEdgeInsets(top: imageHeight, left: imageWidth, bottom: imageHeight, right: imageWidth)
                if self.profile.sensorList.sensorList[indexPath[1]].parameters.count == 0 {
                    
                    for const in cell.SensorSwitch.constraints {
                        cell.SensorSwitch.removeConstraint(const)
                    }
//                    cell.SensorSwitch.trailingAnchor.constraint(lessThanOrEqualToSystemSpacingAfter: view.trailingAnchor, multiplier: 1)
                    cell.SensorInfoButton.isHidden = true
//                    cell.SensorInfoButton.removeFromSuperview()
                    
                }
                return cell
            }
            
        }
        return UITableViewCell()
        
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
        performSegue(withIdentifier: "goToSensorsInfoViewController", sender: profile.sensorList.sensorList[sender.tag].name)
        print("Button tapped")
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
            if profile.sensorList.sensorList[indexPath[1]].parameters.count > 0 {
                performSegue(withIdentifier: "goToSensorsInfoViewController", sender: profile.sensorList.sensorList[indexPath[1]].name)
            }
        }
        
    }
    
    @objc func switchAction(sender: UISwitch!) {
        let sensorName = self.profile.sensorList.sensorList[sender.tag].name
        let sensorStatus = self.profile.sensorList.sensorList[sender.tag].status
        if sensorName == "Video Frames" && !ARConfiguration.isSupported {
            //sender!.isOn = false
            sender!.setOn(false, animated: true)
            self.arkitNotAvailableAlert()
        } else if (sensorName == "Planes" || sensorName == "Point cloud") && !self.profile.sensorList.getByName(name: "Video Frames")!.status {
            if let cell = self.SensorsTable.cellForRow(at: [1,4]) as? SensorTableCell {
                cell.SensorSwitch.setOn(true, animated: true)
                self.profile.sensorList.getByName(name: "Video Frames")!.status = true
                toggleSwitch(sender: sender)
            }
        } else if sensorName == "Video Frames" && sensorStatus == true {
            if self.profile.sensorList.getByName(name: "Point cloud")!.status {
                if let cell = self.SensorsTable.cellForRow(at: [1,7]) as? SensorTableCell {
                    self.profile.sensorList.getByName(name: "Point cloud")!.status = false
                    cell.SensorSwitch.setOn(false, animated: true)
                }
            }
            
            if self.profile.sensorList.getByName(name: "Planes")!.status {
                if let cell = self.SensorsTable.cellForRow(at: [1,6]) as? SensorTableCell {
                    self.profile.sensorList.getByName(name: "Planes")!.status = false
                    cell.SensorSwitch.setOn(false, animated: true)
                }
            }
            toggleSwitch(sender: sender)
        } else {
            toggleSwitch(sender: sender)
        }
        
    }
    
    func toggleSwitch(sender: UISwitch!) {
        let sensorStatus = self.profile.sensorList.sensorList[sender.tag].status
        if sensorStatus {
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // server parameters and sensors
        return 2
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        self.profile = delegate.profile
        print("Loaded sensorlist in controller. Number of sensors: ",profile.sensorList.sensorList.count )
        self.hideKeyboardWhenTappedAround()
        self.navigationItem.setHidesBackButton(true, animated:true);
        self.SensorsTable.dataSource = self
        self.SensorsTable.delegate = self
        print("Sensors view loaded")
        
    }
    
    @IBAction func startGather(_ sender: Any) {
        self.performSegue(withIdentifier: "goToStart", sender: sender)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToSensorsInfoViewController"{
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
            
            if let destinationVC = segue.destination as? ViewController{
                destinationVC.profile = self.profile
        
            }
            
        }
        
    }
    
    

    
    
}
