//
//  RoomModel.swift
//  MuseoAccessibile Creator
//
//  Created by Davide Merassi on 18/06/25.
//

import ARKit
import RealityKit
import SwiftUICore

class RoomViewModel: ObservableObject {
    private var storageManager: StorageManager
    var arAnchors: [String: ARAnchor] = [:]
    var pois: [String: Poi] = [:]
    var arView: ARView = ARView(frame: .zero)
    var roomName: String
    let arrow: ModelEntity
    @Published var showingText: String = ""
    var seen: Set<String> = []
    
    init(roomURL: URL) {
        storageManager = StorageManager(roomURL: roomURL)
        pois = storageManager.loadPois()
        roomName = String(roomURL.lastPathComponent.dropFirst(5))
        arrow = try! ModelEntity.loadModel(named: "freccia90")
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
    
    func loadIcon(poi: Poi) -> TextureResource? {
        switch poi.type {
        case .danger:
            return try? TextureResource.load(named: "warning")
        case .interest:
            return try? TextureResource.load(named: "painting")
        case .service:
            switch poi.serviceType {
            case .toilet:
                return try? TextureResource.load(named: "wc")
            case .bench:
                return try? TextureResource.load(named: "chair")
            case .exit:
                return try? TextureResource.load(named: "exit")
            case .info:
                return try? TextureResource.load(named: "info")
            case .lift:
                return try? TextureResource.load(named: "lift")
            case .none:
                return nil
            }
            
        }
    }
    
    func textGen(textString: String) -> ModelEntity {
        let material = UnlitMaterial(color: .white)
        let depth: Float = 0.002
        let font = UIFont.boldSystemFont(ofSize: 0.06)
        let lineBreakMode : CTLineBreakMode = .byWordWrapping
        
        let textMeshResource : MeshResource = .generateText(textString,
                                                            extrusionDepth: depth,
                                                            font: font,
                                                            containerFrame: .zero,
                                                            alignment: .center,
                                                            lineBreakMode: lineBreakMode)
        
        let textEntity = ModelEntity(mesh: textMeshResource, materials: [material])
        textEntity.scale.x *= -1
        
        /*
         let bounds = textEntity.visualBounds(relativeTo: nil)
         textEntity.position -= bounds.center
         */
        
        return textEntity
    }
}
