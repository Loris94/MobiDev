//
//  Buffer.swift
//  MDProject
//
//  Created by Loris D'Auria on 27/06/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation
import ARKit
import Starscream

extension Notification.Name {
    static let sensor_buffer_enoughdata = Notification.Name("sensor_buffer_enoughdata")
    static let image_buffer_enoughdata = Notification.Name("image_buffer_enoughdata")
}

@available(iOS 11.3, *)
class Buffer {

    var maxsize: Int = 1500
    
    var bufferSize = [
        "sensor": 0,
        "image": 0,
    ]
    var buffer = [
        "sensor": [(Data, Double)](),
        "image": [(Data, Double)](),
    ] as [String : [(Data, Double)]]
    
    var enough_data_event = [
        "sensor": Notification.Name.sensor_buffer_enoughdata,
        "image": Notification.Name.image_buffer_enoughdata,
    ]
    
    var shouldEmit = [
        "sensor": false,
        "image": false,
    ]
    
    init(bufferLength: Int) {
        self.maxsize = bufferLength
    }
    
    func addProbe(type: String, elem: Any) {
        var dataProto: SensorUpdate = SensorUpdate()
        
        switch elem {
        case is CMAccelerometerData:
            let data = elem as! CMAccelerometerData
            dataProto.accelerationData = Utils.accelerometerToProto2(elem: data)
            dataProto.timestamp = data.timestamp
        case is CMGyroData:
            let data = elem as! CMGyroData
            dataProto.gyroData = Utils.gyroToProto2(elem: data)
            dataProto.timestamp = data.timestamp
        case is (ARFrame, CGFloat):
            let data = elem as! (ARFrame, CGFloat)
            dataProto.jpegImage = Utils.arFrameToProto(elem: data.0, compression: data.1)
            dataProto.timestamp = data.0.timestamp
        default:
            print("unknown probe type")
        }
        
        do {
            let data = try dataProto.serializedData()
            buffer[type]?.append((data, dataProto.timestamp))
            bufferSize[type]? += data.count
            print("Buffer size ", type, ": " , self.bufferSize[type], " len: ", self.buffer[type]!.count)
        } catch {
            print("Encoding error")
        }
        
        // TODO ELSE IF FOR EVERY TYPE OF SENSOR DATA
        
        if bufferSize[type]! >= self.maxsize && self.shouldEmit[type]! {
            let samples : [Data] = self.getSamples(type: type)
            if samples.count > 0 {
                print("Sending data:", type)
                NotificationCenter.default.post(name: enough_data_event[type]!, object: nil, userInfo: ["payload": samples, "type": type])
                self.shouldEmit[type]? = false
            }
        }
    }
    
    func getSamples(type: String) -> [Data] {
        var result: [Data] = []
        var size: Int = 0
        for elem in self.buffer[type]! {
            if size + elem.0.count > self.maxsize && size != 0 {
                print("returning a buffer, size: ", size, " elements: ", result.count)
                return result
            } else {
                size += elem.0.count
                result.append(elem.0)
            }
        }
        return []
    }
    
    func removeSamplesFromBuffer(type: String, timestamp: Double) {
        var dataSize = 0
        
        for i in 0 ..< self.buffer[type]!.count {
            dataSize += self.buffer[type]![i].0.count
            if self.buffer[type]![i].1 == timestamp {
                self.buffer[type]!.removeSubrange(0 ... i)
                break
            }
        }
        
//        for (index, element) in self.buffer[type]!.enumerated() {
//            dataSize += element.0.count
//            if element.1 == timestamp {
//                self.buffer[type]!.removeSubrange(0 ... index)
//                break
//            }
//        }
        self.bufferSize[type]! -= dataSize
        print("Buffer size ", type, ": " , self.bufferSize[type], " len: ", self.buffer[type]!.count)
    }
    
    func flushBuffer(type: String) -> [Data] {
        var result: [Data] = []
        for sample in self.buffer[type]! {
            result.append(sample.0)
        }
        return result
    }
    
    func flushBufferWithNoAck(type: String) -> [(Data, Double)] {
        var result: [(Data, Double)] = []
        for sample in self.buffer[type]! {
            result.append(sample)
        }
        return result
    }
    
    func setShouldEmit(value: Bool) {
        self.shouldEmit["sensor"] = value
        self.shouldEmit["image"] = value
    }
    
}
