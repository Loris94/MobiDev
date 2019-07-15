//
//  ARVideoFormat.swift
//  MDProject
//
//  Created by Loris D'Auria on 15/07/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import Foundation
import ARKit

@available(iOS 11.3, *)
class ARVideoFormat: ARConfiguration {
    
    var formats: [ARConfiguration.VideoFormat] = ARConfiguration.supportedVideoFormats
    
}
