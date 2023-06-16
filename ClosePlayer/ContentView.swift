//
//  ContentView.swift
//  ClosePlayer
//
//  Created by David Reese on 6/14/23.
//

import SwiftUI
import AVKit
import Combine
//import Foundation


struct ContentView: View {
    @StateObject private var model: ContentModel = ContentModel()
    @StateObject private var player: Player = Player()
    
    @State private var isPresentingFileImporter = false
    
    @State private var savedTime: CMTime?
    
    @State private var seekValue = ""
    
    var body: some View {
        VStack {
            VideoPlayer(player: player.avPlayer)
                .cornerRadius(5)
                Group {
                    Button("Import") {
                        isPresentingFileImporter = true
                    }
                    
                    Spacer()
                }
                
                    
                Group {
                    if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                        HStack {
                            ProgressView()
                            Spacer()
                        }
                    }
                    
                    HStack {
                        Button("Hold") {
                            self.savedTime = player.avPlayer?.currentTime()
                        }
                        Button("Revert") {
                            guard let savedTime = savedTime else {
                                return
                            }
                            player.scrub(to: savedTime.timeWithOffset(offset: -2))
                            play()
                        }
                    }
                    
                }
                
                Spacer()
                    
                    HStack {
                        TextField("Seek", text: self.$seekValue)
                        //                        .keyboardType(.numberPad)
                            .onReceive(Just(seekValue)) { newValue in
                                let filtered = newValue.filter { "–-0123456789".contains($0) }
                                if filtered != newValue {
                                    self.seekValue = filtered
                                }
                            }
                            .onSubmit {
                                print("Seeking...")
                                
                                guard let diff = Double(seekValue.replacingOccurrences(of: "–", with: "-")) else {
                                    print("Invalid seek input")
                                    return
                                }
                                
                                player.scrub(seconds: diff)
                                seekValue = "-"
                                player.play()
                            }
                    }
                
                Spacer()
                    
                    HStack {
                        Menu {
                            Button(action: {
                                //                                            Haptics.shared.play(.rigid)
                                player.setRate(0.5)
                            }) {
                                Label("0.5x", systemImage: (player.setRate == 0.5) ? "checkmark" : "tortoise")
                            }
                            Button(action: {
                                //                                            Haptics.shared.play(.rigid)
                                player.setRate(0.75)
                            }) {
                                Label("0.75x", systemImage: (player.setRate == 0.75) ? "checkmark" : "")
                            }
                            Button(action: {
                                //                                            Haptics.shared.play(.rigid)
                                player.setRate(1)
                            }) {
                                Label("1x", systemImage: (player.setRate == 1) ? "checkmark" : "figure.walk")
                            }
                            Button(action: {
                                //                                            Haptics.shared.play(.rigid)
                                player.setRate(1.5)
                            }) {
                                Label("1.5x", systemImage: (player.setRate == 1.5) ? "checkmark" : "")
                            }
                            Button(action: {
                                //                                            Haptics.shared.play(.rigid)
                                player.setRate(2)
                            }) {
                                Label("2x", systemImage: (player.setRate == 2) ? "checkmark" : "hare")
                            }
                        } label: {
                            Image(systemName: "speedometer")
                                .resizable()
                                .foregroundColor(.gray)
                                .frame(width: 20, height: 20)
                        }
                    }
                
                
                Spacer()
            
            Group {
                
                
                Text("TIME: \(player.displayTime.rounded().formatted())")
                
                Spacer()
                
                Text("HELD: \(savedTime?.seconds.rounded().formatted() ?? "nil")")
                
                Spacer()
                
                Text("DURATION: \(player.itemDuration.rounded().formatted())")
                
                Spacer()
            }
            }
            .padding()
            .fileImporter(isPresented: $isPresentingFileImporter, allowedContentTypes: [.audio, .mpeg4Movie], onCompletion: { result in
                
                do {
                    let url = try result.get()
                    let ap = AVPlayer(url: url)
                    self.player.set(avPlayer: ap)
                } catch {
                    print("Error importing audio file: \(error)")
                }
        })
        }
    
    
    func play() {
        player.play()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
