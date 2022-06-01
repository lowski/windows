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
        
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let url = homeDirectory.appendingPathComponent(".config/windows/storage.sqlite")
        do {
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        
        let description = NSPersistentStoreDescription(url: url);
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions = [description]
        
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
