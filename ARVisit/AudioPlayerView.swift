//
//  AudioPlayerView.swift
//  ARVisit
//
//  Created by Davide Merassi on 22/06/25.
//

import SwiftUI
import AVFoundation
import _AVKit_SwiftUI

struct AudioPlayerView: View {
    let audioURL: URL
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var progress: Double = 0.0
    @State private var timer: Timer?
    
    var body: some View {
        HStack {
            Button(action: {
                togglePlayback()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
            }
            // Slider avanzamento
            if let player = audioPlayer {
                Slider(value: $progress, in: 0...player.duration, onEditingChanged: { editing in
                    if !editing {
                        player.currentTime = progress
                    }
                })
                .accentColor(.blue)
            }
            
        }
        .padding()
        .background(Color(.white))
        .cornerRadius(12)
        .onAppear {
            prepareAudio()
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    private func prepareAudio() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Errore nella preparazione dell'audio:", error)
        }
    }
    
    private func togglePlayback() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            isPlaying = false
            timer?.invalidate()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        timer?.invalidate()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            if let player = audioPlayer {
                progress = player.currentTime
                if !player.isPlaying {
                    isPlaying = false
                    timer?.invalidate()
                }
            }
        }
    }
}
