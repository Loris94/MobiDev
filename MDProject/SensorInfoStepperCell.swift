//
//  SensorInfoStepperCell.swift
//  MDProject
//
//  Created by Loris D'Auria on 20/07/2019.
//  Copyright © 2019 Loris D'Auria. All rights reserved.
//

import Foundation
import UIKit

class SensorInfoStepperCell: UITableViewCell{
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var valueLabel: UILabel!
    
    @IBOutlet weak var stepper: UIStepper!
    
    
    @IBAction func stepperValueChanged(_ sender: Any) {
    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
