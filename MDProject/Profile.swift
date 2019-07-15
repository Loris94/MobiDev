//
//  Profile.swift
//  MDProject
//
//  Created by Loris D'Auria on 07/07/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import Foundation

class Profile {
    
    var serverAddress: String = ""
    var serverPort: Int = 0
    var sessionName: String = ""
    var sensorList: SensorList = SensorList()
    
    init(serverAddress: String, serverPort: Int, sessionName: String, sensorList: SensorList) {
        self.serverAddress = serverAddress
        self.serverPort = serverPort
        self.sessionName = sessionName
        self.sensorList = sensorList
    }
    
    init(){

    }
    
    func getNumberOfActiveSensors() -> Int {
        var result = 0
        for elem in sensorList.sensorList {
            if elem.status {
                result += 1
            }
        }
        return result
    }
    
    
}
