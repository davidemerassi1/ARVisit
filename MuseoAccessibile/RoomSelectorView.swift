//
//  RoomSelectorView.swift
//  MuseoAccessibile Creator
//
//  Created by Davide Merassi on 18/06/25.
//

import SwiftUI

struct RoomSelectorView : View {
    @State var rooms = StorageManager.getRoomUrls()
    
    var body : some View {
        NavigationStack {
            List {
                ForEach(rooms, id: \.self) { roomURL in
                    NavigationLink(String(roomURL.lastPathComponent.dropFirst(5))) {
                        RoomView(roomURL: roomURL)
                    }
                }
            }
            .overlay {
                    if rooms.isEmpty {
                        Text("Nessun ambiente presente")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                    }
                }
            .navigationTitle("Ambienti")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    
}
