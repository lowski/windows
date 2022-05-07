//
//  Models.swift
//  windows
//
//  Created by Leonard von Lojewski on 22.11.20.
//

import Foundation
import CoreData

class ScreenConfiguration : NSManagedObject {
    @NSManaged var name: String?
    @NSManaged var windowConfigurations: WindowConfiguration[]
}
