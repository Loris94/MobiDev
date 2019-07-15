//
//  Sensor.swift
//  MDProject
//
//  Created by Loris D'Auria on 01/07/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import Foundation

class Sensor {
    
    var name: String = ""
    var status: Bool = false
    var parameters: [String:Any] = [:]
    
    init(name: String, status: Bool, parameters: [String:Any]){
        self.name = name
        self.status = status
        self.parameters = parameters
    }
    
    init(name: String, status: Bool){
        self.name = name
        self.status = status
    }
    
    static func fromProto(sensorProto: SensorProto) -> Sensor {
        var resultDictionary: [String:Any] = [:]
        for elem in sensorProto.parameter {
            var value: Any
            if elem.value.doubleValue != nil {
                value = elem.value.doubleValue
            } else {
                value = elem.value.strValue
            }
            resultDictionary.updateValue(value, forKey: elem.key)
        }
        return Sensor(name: sensorProto.name, status: sensorProto.status, parameters: resultDictionary)
    }
    
}
