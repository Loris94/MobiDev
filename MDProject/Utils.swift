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
import ARKit

typealias JpegData = Data

@available(iOS 11.3, *)
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
    
    static func magnetometerToProto(elem: CMMagneticField) -> MagnetometerDataProto {
        return MagnetometerDataProto.with {
            $0.x = elem.x
            $0.y = elem.y
            $0.z = elem.z
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
    
    
    static func arFrameToProto(elem: ARFrame, compression: CGFloat, videoFrames: Bool, arKitPoses: Bool, planes: Bool, pointClouds: Bool) -> ImageProto2 {
        
        var jpeg : Data? = nil
        var jpegImg: UIImage?
        
        if videoFrames {
            jpegImg = UIImage(pixelBuffer: elem.capturedImage)
            DispatchQueue.main.sync {
                jpeg = jpegImg?.jpegData(compressionQuality: compression)
            }
        }
        
        
        //jpeg = UIImage(pixelBuffer: elem.capturedImage)?.jpegData(compressionQuality: compression)
        
        
        var pointsCloudProto: [PointCloudDataProto] = []
        
        if elem.rawFeaturePoints != nil && pointClouds {
            for point in elem.rawFeaturePoints!.points {
                pointsCloudProto.append(PointCloudDataProto.with{
                    $0.x = point.x
                    $0.y = point.y
                    $0.z = point.z
                })
            }
        }
        
        var trackingState: String
        switch elem.camera.trackingState {
        case ARCamera.TrackingState.normal:
            trackingState = "Normal"
        case ARCamera.TrackingState.limited:
            trackingState = "Limited"
        case ARCamera.TrackingState.notAvailable:
            trackingState = "NotAvailable"
        }
        
        var arKitPosesProto: ArKit6dPosesDataProto = ArKit6dPosesDataProto()
        if arKitPoses {
            arKitPosesProto = ArKit6dPosesDataProto.with {
                $0.eulerAngles = eulerAnglesToProto(sim3vecctor: elem.camera.eulerAngles)
                $0.transformPoses = transformationMatrixToProto(transformMatrix: elem.camera.transform)
            }
        }
        
        return ImageProto2.with{
            $0.jpegImage = jpeg ?? Data()
            $0.trackingState = trackingState
            $0.pointsCloud = pointsCloudProto
            $0.arKitPoses = arKitPosesProto
        }
    }
    
    static func transformationMatrixToProto(transformMatrix: simd_float4x4) -> TransformationMatrixDataProto {
        return TransformationMatrixDataProto.with {
            $0.firstColumn = transformationVectorToProto(transformationVector: transformMatrix.columns.0)
            $0.secondColumn = transformationVectorToProto(transformationVector: transformMatrix.columns.1)
            $0.thirdColumn = transformationVectorToProto(transformationVector: transformMatrix.columns.2)
            $0.fourthColumn = transformationVectorToProto(transformationVector: transformMatrix.columns.3)
            
        }
    }
    
    static func transformationVectorToProto(transformationVector: simd_float4) -> TransformationVectorDataProto{
        return TransformationVectorDataProto.with {
            $0.x = transformationVector.x
            $0.y = transformationVector.y
            $0.z = transformationVector.z
            $0.w = transformationVector.w
        }
    }
    
    static func eulerAnglesToProto(sim3vecctor: simd_float3) -> EulerAnglesDataProto {
        return EulerAnglesDataProto.with {
            $0.pitch = sim3vecctor.x
            $0.yaw = sim3vecctor.y
            $0.roll = sim3vecctor.z
        }
    }
    
    static func arPlaneToProto(elem: ARPlaneAnchor) -> PlaneDataProto{
        return PlaneDataProto.with {
            $0.width = elem.extent.x
            $0.height = elem.extent.z
            $0.x = elem.center.x
            $0.y = elem.center.y
            $0.z = elem.center.z
        }
    }
    
    
}


