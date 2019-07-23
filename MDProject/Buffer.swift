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
    var dispatchQueue: DispatchQueue
    var autoFlushTimer: Timer = Timer()
    
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
    
    init(bufferLength: Int, bufferDispatchQueue: DispatchQueue) {
        self.maxsize = bufferLength
        self.dispatchQueue = bufferDispatchQueue
        // TODO set the autoflush time from  the profile
        self.autoFlushTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(autoFlushSensorBuffer), userInfo: nil, repeats: true)
        //self.autoFlushTimer.fire()
    }
    
    @objc func autoFlushSensorBuffer() {
        let type = "sensor"
        if self.shouldEmit[type]! {
            let samples : [Data] = self.flushBuffer(type: type)
            if samples.count > 0 {
                NotificationCenter.default.post(name: self.enough_data_event[type]!, object: nil, userInfo: ["payload": samples, "type": type])
                self.shouldEmit[type]? = false
            }
        }
    }
    
    func addProbe(type: String, elem: Any) {
        if ViewController.isClosing {
            return
        }
        var dataProto: SensorUpdate = SensorUpdate()
        
        switch elem {
            case is CMAccelerometerData:
                let data = elem as! CMAccelerometerData
                dataProto.accelerationData = Utils.accelerometerToProto2(elem: data)
                dataProto.timestamp = NSDate().timeIntervalSince1970
            case is CMGyroData:
                let data = elem as! CMGyroData
                dataProto.gyroData = Utils.gyroToProto2(elem: data)
                dataProto.timestamp = NSDate().timeIntervalSince1970
            case is CMMagneticField:
                let data = elem as! CMMagneticField
                dataProto.magnetometerData = Utils.magnetometerToProto(elem: data)
                dataProto.timestamp = NSDate().timeIntervalSince1970
            case is CLHeading:
                let data = elem as! CLHeading
                dataProto.compassData = Utils.compassToProto(elem: data)
                dataProto.timestamp = NSDate().timeIntervalSince1970
            // Frame, Compression, 6dposes, planes, pointcloud
            case is (ARFrame, CGFloat, Bool, Bool, Bool):
                let data = elem as! (ARFrame, CGFloat, Bool, Bool, Bool)
                dataProto.jpegImage = Utils.arFrameToProto(elem: data.0, compression: data.1, arKitPoses: data.2, planes: data.3, pointClouds: data.4)
                dataProto.timestamp = NSDate().timeIntervalSince1970
            case is ARPlaneAnchor:
                let data = elem as! ARPlaneAnchor
                dataProto.planeData = Utils.arPlaneToProto(elem: data)
                dataProto.timestamp = NSDate().timeIntervalSince1970
            default:
                print("unknown probe type")
                return
        }
        do {
            let data = try dataProto.serializedData()
//            self.dispatchQueue.async {
//                DispatchQueue.global().sync {
            self.buffer[type]?.append((data, dataProto.timestamp))
            self.bufferSize[type]? += data.count
            print("Buffer size ",type," add: " , self.bufferSize[type], " len: ", self.buffer[type]!.count)
            if self.bufferSize[type]! >= self.maxsize && self.shouldEmit[type]! {
                let samples : [Data] = self.getSamples(type: type)
                if samples.count > 0 {
                    print("Sending data:", type)
                    NotificationCenter.default.post(name: self.enough_data_event[type]!, object: nil, userInfo: ["payload": samples, "type": type])
                    self.shouldEmit[type]? = false
                }
            }
//               }
//            }
        } catch {
            print("Encoding error")
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
        self.dispatchQueue.async {
            DispatchQueue.global().sync {
                var dataSize = 0
                
                for i in 0 ..< self.buffer[type]!.count {
                    dataSize += self.buffer[type]![i].0.count
                    if self.buffer[type]![i].1 == timestamp {
                        self.buffer[type]!.removeSubrange(0 ... i)
                        self.bufferSize[type]! -= dataSize
                        break
                    }
                }
                
                
                print("Buffer size ",type," remove: " , self.bufferSize[type], " len: ", self.buffer[type]!.count)
            }
        }
    }
    
    func flushBuffer(type: String) -> [Data] {
        var result: [Data] = []
        for sample in self.buffer[type]! {
            result.append(sample.0)
        }
        return result
    }
    
    func flushBufferWithNoAck(type: String) -> [(Data, Double)] {
        self.bufferSize[type] = 0
        let result = self.buffer[type]
        self.buffer[type] = []
        return result!
    }
    
    func setShouldEmit(value: Bool) {
        self.dispatchQueue.async {
            DispatchQueue.global().sync {
                self.shouldEmit["sensor"] = value
                self.shouldEmit["image"] = value
            }
        }
    }
    
    func calculateSize(type: String) {
        var size: Int = 0
        for elem in self.buffer[type]! {
            size = size + elem.0.count
        }
        self.bufferSize[type] = size
    }
    
}
