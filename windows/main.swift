//
//  main.swift
//  windows
//
//  Created by Leonard von Lojewski on 22.11.20.
//

import Foundation
import Cocoa
import CoreData
import CoreGraphics

let args = CommandLine.arguments

func loadScreenConfigurations() -> [ScreenConfiguration] {
    let mainContext = CoreDataManager.shared.mainContext
    let fetchRequest: NSFetchRequest<ScreenConfiguration> = ScreenConfiguration.fetchRequest()
    do {
        let results = try mainContext.fetch(fetchRequest)
        return results
    } catch {
        debugPrint(error)
        return []
    }
}

func deleteScreenConfiguration(name: String) {
    do {
        let config = getScreenConfiguration(name: name)
        if config != nil {
            CoreDataManager.shared.mainContext.delete(config!)
        }
        try? CoreDataManager.shared.mainContext.save()
    }
}

func getScreenConfiguration(name: String) -> ScreenConfiguration? {
    let mainContext = CoreDataManager.shared.mainContext
    let fetchRequest: NSFetchRequest<ScreenConfiguration> = ScreenConfiguration.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "name = %@", name)
    do {
        let results = try mainContext.fetch(fetchRequest)
        if results.count > 0 {
            return results[0]
        }
    } catch {
        debugPrint(error)
    }
    return nil
}

func storeWindowConfiguration(screenConfiguration: ScreenConfiguration, bundleId: String, x: Float, y: Float, width: Float, height: Float) throws {
    let context = CoreDataManager.shared.mainContext
    let entity = WindowConfiguration.entity()
    var wc = WindowConfiguration(entity: entity, insertInto: context)
    
    if let res = screenConfiguration.windowConfigurations?.first(where: { (wc) -> Bool in
        (wc as! WindowConfiguration).bundleId == bundleId
    }) {
        wc = res as! WindowConfiguration 
    }
    wc.bundleId = bundleId
    wc.x = x
    wc.y = y
    wc.width = width
    wc.height = height
    wc.screenConfiguration = screenConfiguration
    try context.save()
}

func storeScreenConfiguration(name: String) throws {
    let context = CoreDataManager.shared.backgroundContext()
    let entity = ScreenConfiguration.entity()
    let sc = ScreenConfiguration(entity: entity, insertInto: context)
    sc.name = name
    sc.windowConfigurations = NSSet.init(array: [])
    try context.save()
}

if args.count < 2 || (args[1] != "list-configs" && args[1] != "create-config" && args[1] != "delete-config" && args[1] != "list-windows" && args[1] != "set" && args[1] != "apply" && args[1] != "get") {
    if args.count > 1 {
        print("Unrecognized command:", args[1])
        print("")
    }
    print("Usage: windows <command> [args]")
    print("")
    print("Commands:")
    print("  list-configs")
    print("  create-config <config>")
    print("  delete-config <config>")
    print("  list-windows")
    print("  set <config> <bundleId>")
    print("  apply <config>")
    print("  get <config> [<bundleId>]")
    
    if args.count > 1 {
        exit(-1)
    }
    exit(0)
}

if args[1] == "create-config" {
    if getScreenConfiguration(name: args[2]) != nil {
        print("Screen config with the same name already exists.")
        exit(-1)
    }
    try storeScreenConfiguration(name: args[2])
    print("Created screen configuration \"", args[2], "\"")
    exit(0)
}
if args[1] == "delete-config" {
    deleteScreenConfiguration(name: args[2])
    print("Deleted screen configuration \"", args[2], "\"")
    exit(0)
}
if args[1] == "list-configs" {
    let configs = loadScreenConfigurations();
    for config in configs {
        print(config.name ?? "no name", "|", config.windowConfigurations?.count ?? "0", "windows configured")
    }
    exit(0)
}
if args[1] == "list-windows" {
    print("Fetching windows...")
    let running = NSWorkspace.shared.runningApplications.filter { app in
        return !app.isHidden && app.bundleIdentifier != nil && !app.isTerminated && (try? app.accessibilityElement.getAttributeCount(for: NSAccessibility.Attribute.windows) > 0) ?? false
    };
    print("")
    print("Applications with open windows:")
    for app in running {
        let windows: [AXUIElement]? = try? app.accessibilityElement.getAttribute(for: NSAccessibility.Attribute.windows)
        print(" -", windows!.count, "windows |", app.bundleIdentifier!)
    }
    exit(0)
}
if args[1] == "apply" {
    let sc = getScreenConfiguration(name: args[2])
    if sc == nil {
        print("Screen configuration not found")
        exit(-1)
    }
    var m = [String: WindowConfiguration]()
    for wc in sc!.windowConfigurations!.allObjects {
        let w = wc as! WindowConfiguration
        m[w.bundleId!] = w
    }
    let running = NSWorkspace.shared.runningApplications;
    for app in running {
        if !m.keys.contains(app.bundleIdentifier ?? "") {
            continue;
        }
        
        let iterm = app.accessibilityElement
        do {
            let val: [AXUIElement] = try iterm.getAttribute(for: NSAccessibility.Attribute.windows)
            
            for window in val {
                let wc = m[app.bundleIdentifier!]!
                
                let pos = CGPoint(x: CGFloat(wc.x), y: CGFloat(wc.y))
                try window.setAttribute(pos, for: NSAccessibility.Attribute.position)
                
                do {
                    let size = CGSize(width: CGFloat(wc.width), height: CGFloat(wc.height))
                    try window.setAttribute(size, for: NSAccessibility.Attribute.size)
                } catch {}
                
            }
        } catch let error {
            print("Could not adjust", app.bundleIdentifier!, "properly:", error.localizedDescription)
        }
    }
    exit(0)
}
if args[1] == "set" {
    let sc = getScreenConfiguration(name: args[2])
    
    if sc == nil {
        print("Screen configuration not found")
        exit(-1)
    }
    
    let running = NSWorkspace.shared.runningApplications;

    if let itermApp = running.first(where: {$0.bundleIdentifier == args[3]}) {
        let iterm = itermApp.accessibilityElement
        do {
            let val: [AXUIElement] = try iterm.getAttribute(for: NSAccessibility.Attribute.windows)
            
            if let window = val.first {
                let pos: CGPoint = try window.getAttribute(for: NSAccessibility.Attribute.position)
                let size: CGSize = try window.getAttribute(for: NSAccessibility.Attribute.size)
                try storeWindowConfiguration(screenConfiguration: sc!, bundleId: args[3], x: Float(pos.x), y: Float(pos.y), width: Float(size.width), height: Float(size.height))
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    exit(0)
}
if args[1] == "get" {
    let sc = getScreenConfiguration(name: args[2])
    if sc == nil {
        print("Screen configuration not found")
        exit(-1)
    }
    
    for wc in sc!.windowConfigurations!.allObjects {
        let w = wc as! WindowConfiguration
        
        if args.count == 4 && args[3] != w.bundleId! {
            continue;
        }
        
        print(w.bundleId!, String(format: "(%.0f, %.0f) [%.0f x %.0f]", w.x, w.y, w.width, w.height))
    }
    exit(0)
}
