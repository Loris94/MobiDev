//
//  SensorList.swift
//  MDProject
//
//  Created by Loris D'Auria on 01/07/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import Foundation

class SensorList {
    
    var sensorList: [Sensor] = []
    
    init(sensorList: [Sensor]) {
        self.sensorList = sensorList
    }
    
    init() {
        //
    }
    
    static func fromProto(profileProto: ProfileProto) -> SensorList {
        var sensorList: [Sensor] = []
        for elem in profileProto.sensor {
            sensorList.append(Sensor.fromProto(sensorProto: elem))
        }
        return SensorList(sensorList: sensorList)
    }
    
    func getByName(name: String) -> Sensor?{
        for elem in sensorList {
            if elem.name == name {
                return elem
            }
        }
        return nil
    }
    
    
}
