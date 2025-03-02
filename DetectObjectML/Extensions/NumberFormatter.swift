//
//  NumberFormatter.swift
//  DetectObjectML
//
//  Created by Petar  on 2.3.25..
//

import Foundation

extension NumberFormatter {
    
    static var percentage: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter
    }
}
