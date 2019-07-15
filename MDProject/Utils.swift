//
//  Utils.swift
//  MDProject
//
//  Created by Loris D'Auria on 13/07/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation

class Utils {
    static func accelerometerToProto2(elem: CMAccelerometerData) -> AccelerationDataProto2 {
        return AccelerationDataProto2.with {
            $0.x = elem.acceleration.x
            $0.y = elem.acceleration.y
            $0.z = elem.acceleration.z
        }
    }
    static func accelerometerToProto(elem: CMAccelerometerData) -> AccelerationDataProto {
        return AccelerationDataProto.with {
            $0.x = elem.acceleration.x
            $0.y = elem.acceleration.y
            $0.z = elem.acceleration.z
            $0.timestamp = elem.timestamp
        }
    }
    static func gyroToProto(elem: CMGyroData) -> GyroDataProto {
        return GyroDataProto.with {
            $0.x = elem.rotationRate.x
            $0.y = elem.rotationRate.y
            $0.z = elem.rotationRate.z
            $0.timestamp = elem.timestamp
        }
    }
    static func gyroToProto2(elem: CMGyroData) -> GyroDataProto2 {
        return GyroDataProto2.with {
            $0.x = elem.rotationRate.x
            $0.y = elem.rotationRate.y
            $0.z = elem.rotationRate.z
        }
    }
    
    static func magnetometerToProto(elem: CMCalibratedMagneticField) -> MagnetometerDataProto {
        return MagnetometerDataProto.with {
            $0.x = elem.field.x
            $0.y = elem.field.y
            $0.z = elem.field.z
            $0.accuracy = elem.accuracy.rawValue
        }
    }
    
    static func compassToProto(elem: CLHeading) -> CompassDataProto {
        return CompassDataProto.with {
            $0.x = elem.x
            $0.y = elem.y
            $0.z = elem.z
            $0.magneticHeading = elem.magneticHeading.binade
            $0.trueHeading = elem.trueHeading.binade
        }
    }
    
    
}


