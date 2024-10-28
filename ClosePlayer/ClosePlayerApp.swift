//
//  ClosePlayerApp.swift
//  ClosePlayer
//
//  Created by David Reese on 6/14/23.
//

import SwiftUI
import AVKit

@main
struct ClosePlayerApp: App {
    @StateObject var contentViewModel = ContentModel()
    
//    @FocusState private var isFocused: Bool
    
    var body: some Scene {
        WindowGroup {
            let contentViewModel = ContentModel()
            ContentView()
                .background(VisualEffectView().ignoresSafeArea())
                .environmentObject(contentViewModel)
//                .focused($isFocused)
                /*.toolbar {
                    ToolbarItemGroup(placement: .principal) {
                                Button("Hold") {
                                    contentViewModel.hold()
                                }
                                .keyboardShortcut(.init("h"), modifiers: [.command, .shift])
                                
                                Button("Return") {
                                    contentViewModel.returnAndPlay()
                                }
                                .keyboardShortcut(.init("r"), modifiers: [.command, .shift])
                            }
                        }*/
        }
    }
}
