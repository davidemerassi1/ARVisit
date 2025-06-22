//
//  ArMapManager.swift
//  MuseoAccessibile Creator
//
//  Created by Davide Merassi on 15/06/25.
//

import RealityKit
import ARKit
import SwiftUICore

struct StorageManager {
    var roomURL: URL
    
    func loadWorldMap() -> ARWorldMap? {
        let url = roomURL.appendingPathComponent("worldMap")
        do {
            let data = try Data(contentsOf: url)
            guard let map = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) else {
                print("WorldMap non valida")
                return nil
            }
            return map
        } catch {
            print("Errore nel caricamento della mappa: \(error)")
            return nil
        }
    }
    
    func loadPois() -> [String : Poi] {
        let decoder = JSONDecoder()
        let url = roomURL.appendingPathComponent("pois.json")
        do {
            
            let contents = try FileManager.default.contentsOfDirectory(at: roomURL, includingPropertiesForKeys: nil, options: [])
            for content in contents {
                print(content)
            }
            
            
            
            
            let data = try Data(contentsOf: url)
            let pois = try decoder.decode([Poi].self, from: data)
            let poiDict = Dictionary(uniqueKeysWithValues: pois.map { ($0.id.uuidString, $0) })
            print("Caricati \(poiDict.count) POI")
            print(poiDict)
            return poiDict
        } catch {
            print("Errore nel caricamento dei POI: \(error)")
            return [:]
        }
    }
    
    private static func getSharedContainerURL() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.MuseoAccessibile")
    }
    
    static func getRoomUrls() -> [URL] {
        do {
            if let groupURL = getSharedContainerURL() {
                let contents = try FileManager.default.contentsOfDirectory(at: groupURL, includingPropertiesForKeys: nil, options: [])
                
                let folders = contents.filter { url in
                    var isDirectory: ObjCBool = false
                    FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                    return isDirectory.boolValue && url.lastPathComponent.starts(with: "Room-")
                }
                
                print("Sottocartelle trovate:")
                folders.forEach { print($0.lastPathComponent) }
                return folders
            } else {
                print("Errore nel trovare la directory condivisa")
            }
            
        } catch {
            print("Errore nel leggere la directory: \(error)")
        }
        return []
    }
}
