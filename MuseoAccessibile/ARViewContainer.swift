//
//  ARViewContainer.swift
//  MuseoAccessibile Creator
//
//  Created by Davide Merassi on 15/06/25.
//

import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer : UIViewRepresentable {
    @Binding var selectedPOI: Poi?
    var viewModel: RoomViewModel
    
    func makeUIView(context: Context) -> ARView {
        //arView.debugOptions = [.showFeaturePoints, .showAnchorOrigins, .showSceneUnderstanding]
        let arView = viewModel.arView
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            print("lidar disponibile")
            config.sceneReconstruction = .mesh
            arView.environment.sceneUnderstanding.options.insert(.occlusion)
            arView.environment.sceneUnderstanding.options.insert(.collision)
        } else {
            print("lidar non disponibile")
        }
        
        if let loadedMap = viewModel.getWorldMap() {
            print("Caricata ARWorldMap salvata. Sono stati caricati \(loadedMap.anchors.count) ancore")
            config.initialWorldMap = loadedMap
        } else {
            print("WorldMap non trovata: avvio nuovo tracciamento")
        }
        
        arView.session.delegate = context.coordinator
        
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.delegate = context.coordinator
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        coachingOverlay.goal = .anyPlane  // oppure .tracking o .anyPlane
        arView.addSubview(coachingOverlay)
        NSLayoutConstraint.activate([
            coachingOverlay.topAnchor.constraint(equalTo: arView.topAnchor),
            coachingOverlay.bottomAnchor.constraint(equalTo: arView.bottomAnchor),
            coachingOverlay.leadingAnchor.constraint(equalTo: arView.leadingAnchor),
            coachingOverlay.trailingAnchor.constraint(equalTo: arView.trailingAnchor)
        ])
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        //context.coordinator.updateScene(arView: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(selectedPOI: $selectedPOI, viewModel: viewModel)
    }
    
    class Coordinator: NSObject, ARSessionDelegate, ARCoachingOverlayViewDelegate {
        @Binding var selectedPOI: Poi?
        var viewModel: RoomViewModel
        
        init(selectedPOI: Binding<Poi?>, viewModel: RoomViewModel) {
            self.viewModel = viewModel
            _selectedPOI = selectedPOI
            super.init()
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if let name = anchor.name {
                    let anchorEntity = AnchorEntity(anchor: anchor)
                    anchorEntity.name = name
                    let sphere = ModelEntity(mesh: .generateSphere(radius: 0.03))
                    let poi = viewModel.pois[anchorEntity.name]
                    if let poi {
                        switch poi.type {
                        case .interest:
                            sphere.model?.materials = [SimpleMaterial(color: .blue, isMetallic: false)]
                        case .service:
                            sphere.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
                        case .danger:
                            sphere.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
                        }
                        sphere.generateCollisionShapes(recursive: true)
                        anchorEntity.addChild(sphere)
                        viewModel.arView.scene.anchors.append(anchorEntity)
                        viewModel.arAnchors[anchor.name!] = anchor
                    }
                }
            }
        }
        
        /*
        func updateScene(arView: ARView) {
            // 1. Rimuovi anchor non più presenti
            for anchor in arView.scene.anchors {
                if parent.arMapManager.pois[anchor.name] == nil {
                    anchor.removeFromParent()
                }
            }
            
            // 2. Aggiungi anchor nuovi o aggiorna esistenti
        }
         */
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = sender.view as? ARView else { return }
            let location = sender.location(in: arView)
            
            if let entity = arView.entity(at: location), let anchor = entity.anchor {
                let poiId = anchor.name
                print("Toccato poi con id \(poiId)")
                if let tapped = viewModel.pois[poiId] {
                    selectedPOI = tapped
                    print("Il poi ha nome \(tapped.name)")
                }
            }
        }
        
        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            print("ARCoachingOverlayView completato. Tracciamento stabile.")
            // Qui potresti abilitare il pulsante "Salva", ecc.
        }
    }
}
