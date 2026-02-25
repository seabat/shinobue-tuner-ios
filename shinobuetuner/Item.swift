//
//  Item.swift
//  shinobuetuner
//
//  Created by ryouta on 2026/02/25.
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
