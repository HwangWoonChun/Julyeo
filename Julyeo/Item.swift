//
//  Item.swift
//  Julyeo
//
//  Created by lotte on 7/2/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
