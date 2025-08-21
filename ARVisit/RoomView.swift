//
//  ContentView.swift
//  ARVisit
//
//  Created by Davide Merassi on 15/06/25.
//

import SwiftUI
import RealityKit
import ARKit

struct RoomView : View {
    @State private var selectedPOI: Poi? = nil
    @StateObject private var viewModel: RoomViewModel
    
    init(roomURL: URL) {
        _viewModel = StateObject(wrappedValue: RoomViewModel(roomURL: roomURL))
    }
    
    var body: some View {
        ZStack {
            ARViewContainer(selectedPOI: $selectedPOI, viewModel: viewModel)
                .ignoresSafeArea(edges: .bottom)
            
            GeometryReader { geometry in
                Text(viewModel.showingText)
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .padding(18)
                    .cornerRadius(8)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2 + 150
                    )
            }
        }
        .sheet(item: $selectedPOI) { poi in
            PoiDetailView(
                poi: $selectedPOI,
                viewModel: viewModel
            )
        }
        .navigationTitle(viewModel.roomName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
