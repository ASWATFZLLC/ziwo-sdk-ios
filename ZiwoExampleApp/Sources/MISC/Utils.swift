//
//  Utils.swift
//  ZiwoExampleApp
//
//  Created by Emilien ROUSSEL on 24/04/2020.
//  Copyright © 2020 ASWAT. All rights reserved.
//

import Foundation
import UIKit

enum Dimension: String {
    case Width = "Width"
    case Height = "Height"
}

struct Frame {
    
    static func at(percent: CGFloat, of dimension: Dimension, ofView view: UIView?) -> CGFloat {
        guard let target = view else {
            return 0.0
        }
        
        switch dimension {
        case .Width:
            return (target.frame.width / 100) * percent
        case .Height:
            return (target.frame.height / 100) * percent
        }
    }
    
    static func below(view: UIView?, withOffset offset: CGFloat) -> CGFloat {
        guard let target = view else {
            return 0.0
        }
        
        return target.frame.maxY + offset
    }
    
}
