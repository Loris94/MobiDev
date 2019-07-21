//
//  SensorInfoWithSliderCell.swift
//  MDProject
//
//  Created by Loris D'Auria on 20/07/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import Foundation
import UIKit

class SensorInfoWithSliderCell: UITableViewCell{
    
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        if infoLabel.text == "FPS" {
            valueLabel.text = String(Int(slider.value))
        } else if infoLabel.text == "Compression" {
            
            valueLabel.text = String( round(slider.value*10)/10  )
        }
        
    }
    
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var valueLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
