//
//  RoomModel.swift
//  MuseoAccessibile Creator
//
//  Created by Davide Merassi on 18/06/25.
//

import ARKit
import RealityKit

class RoomViewModel: ObservableObject {
    private var storageManager: StorageManager
    var arAnchors: [String: ARAnchor] = [:]
    var pois: [String: Poi] = [:]
    var arView: ARView = ARView(frame: .zero)
    var roomName: String
    
    init(roomURL: URL) {
        storageManager = StorageManager(roomURL: roomURL)
        pois = storageManager.loadPois()
        roomName = String(roomURL.lastPathComponent.dropFirst(5))
    }
    
    func getWorldMap() -> ARWorldMap? {
        storageManager.loadWorldMap()
    }
    
    func getImage(url: URL) -> UIImage? {
        do {
            let data = try Data(contentsOf: url)
            print(data)
            return UIImage(data: data)
        } catch {
            print(error)
        }
        return nil
    }
}
