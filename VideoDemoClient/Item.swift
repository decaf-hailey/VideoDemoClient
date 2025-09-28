//
//  Item.swift
//  VideoDemoClient
//
//  Created by hailey on 9/27/25.
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
