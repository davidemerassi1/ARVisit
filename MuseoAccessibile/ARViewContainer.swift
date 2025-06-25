//
//  ARViewContainer.swift
//  MuseoAccessibile Creator
//
//  Created by Davide Merassi on 15/06/25.
//

import SwiftUI
import ARKit
import RealityKit
import Combine

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
        var arrowAnchor: AnchorEntity?
        
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
                    let poi = viewModel.pois[anchorEntity.name]
                    if let poi {
                        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.05))
                        let texture = viewModel.loadIcon(poi: poi)
                        var material = SimpleMaterial()
                        if let texture {
                            material.color = SimpleMaterial.BaseColor(texture: MaterialParameters.Texture(texture))
                        } else {
                            material.color = SimpleMaterial.BaseColor(tint: poi.type == .danger ? .red : poi.type == .service ? .green : .blue)
                        }
                        sphere.model?.materials = [material]
                        sphere.generateCollisionShapes(recursive: true)
                        
                        let textEntity = viewModel.textGen(textString: poi.name)
                        let bounds = textEntity.visualBounds(relativeTo: nil)
                        let textWidth = bounds.extents.x
                        textEntity.position = [textWidth / 2, 0.06, 0]
                        
                        anchorEntity.addChild(sphere)
                        sphere.addChild(textEntity)
                        
                        viewModel.arView.scene.anchors.append(anchorEntity)
                        viewModel.arAnchors[anchor.name!] = anchor
                        
                        //permette di ruotare la sfera in modo che guardi sempre verso l'utente
                        startBillboard(for: sphere, in: viewModel.arView)
                        //startBillboard(for: textEntity,  in: viewModel.arView)
                    }
                }
            }
            
            if (arrowAnchor == nil) {
                startArrow()
            }
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = sender.view as? ARView else { return }
            let location = sender.location(in: arView)
            
            if let entity = arView.entity(at: location), let anchor = entity.anchor {
                let poiId = anchor.name
                print("Toccato poi con id \(poiId)")
                if let tapped = viewModel.pois[poiId], tapped.type == .interest {
                    selectedPOI = tapped
                    print("Il poi ha nome \(tapped.name)")
                }
            }
        }
        
        func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
            print("ARCoachingOverlayView completato. Tracciamento stabile.")
            // Qui potresti abilitare il pulsante "Salva", ecc.
        }
        
        var subscriptions = Set<AnyCancellable>()
        
        func startBillboard(for entity: Entity,in arView: ARView) {
            let position = entity.convert(position: .zero, to: nil)
            arView.scene.subscribe(to: SceneEvents.Update.self) { event in
                guard let cameraTransform = arView.session.currentFrame?.camera.transform else { return }
                
                let cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x,
                                                  cameraTransform.columns.3.y,
                                                  cameraTransform.columns.3.z)
                
                entity.look(at: cameraPosition, from: position, relativeTo: nil)
            }
            .store(in: &subscriptions)
        }
        
        func startArrow() {
            let arrow = try! ModelEntity.loadModel(named: "freccia90")
            let arrowContainer = Entity()
            arrowContainer.scale = SIMD3<Float>(repeating: 0.1) // Scala uniforme del contenitore
            arrowContainer.addChild(arrow)
            arrowAnchor = AnchorEntity(world: [0, 0, 0])
            arrowAnchor!.addChild(arrowContainer)
            viewModel.arView.scene.anchors.append(arrowAnchor!)
            
            viewModel.arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
                guard let arView = self?.viewModel.arView else { return }
                guard let cameraTransform = arView.session.currentFrame?.camera.transform else { return }
                let viewModel = self!.viewModel
                
                let cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x,
                                                  cameraTransform.columns.3.y,
                                                  cameraTransform.columns.3.z)
                
                var nearestPoi: (Poi, Float)?
                for (poiname, poi) in viewModel.pois {
                    guard let anchor = viewModel.arView.scene.findEntity(named: poiname),
                          let max_d = poi.distance else { continue }
                    
                    let poi_d = simd_distance(anchor.position(relativeTo: nil), cameraPosition)
                    print("Distanza da \(poiname) \(poi_d)")
                    if poi_d <= (Float(max_d) / 100.0) {
                        if let np = nearestPoi {
                            if poi.type == np.0.type && poi_d > np.1 {
                                nearestPoi = (poi, poi_d)
                            } else if poi.type == .danger {
                                nearestPoi = (poi, poi_d)
                            }
                        } else {
                            nearestPoi = (poi, poi_d)
                        }
                    }
                }
                
                if (nearestPoi != nil) {
                    arrow.isEnabled = true
                    print("Sei vicino al poi \(nearestPoi!.0.name)")
                    // Posiziona la freccia a 0.5 metri davanti alla camera
                    let cameraForward = normalize(-SIMD3<Float>(cameraTransform.columns.2.x,
                                                                cameraTransform.columns.2.y,
                                                                cameraTransform.columns.2.z))
                    
                    let arrowPosition = cameraPosition + cameraForward * 0.5
                    self!.arrowAnchor!.position = arrowPosition
                    
                    // Calcola la direzione verso il target
                    if let targetAnchor = arView.scene.findEntity(named: nearestPoi!.0.id.uuidString) {
                        let targetPosition: SIMD3<Float> = targetAnchor.position(relativeTo: nil)
                        
                        arrow.look(at: targetPosition, from: arrow.position(relativeTo: nil), relativeTo: nil)
                    }
                } else {
                    arrow.isEnabled = false
                }
            }
            .store(in: &subscriptions)
        }
    }
}
