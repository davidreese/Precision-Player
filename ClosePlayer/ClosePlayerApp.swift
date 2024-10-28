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
    
//    @FocusState private var isFocused: Bool
    
    var body: some Scene {
        WindowGroup {
            let contentViewModel = ContentModel()
            ContentView()
                .background(VisualEffectView().ignoresSafeArea())
        }
    }
}
