//
//  CoreDataManager.swift
//  windows
//
//  Created by Leonard von Lojewski on 22.11.20.
//

import Foundation
import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "windows")
        container.loadPersistentStores {(_, error) in
            _ = error.map{ fatalError("Unresolved error \($0)") }
        }
        return container
    }()
    
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func backgroundContext() -> NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
}
