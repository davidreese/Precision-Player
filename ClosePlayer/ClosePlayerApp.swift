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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(VisualEffectView().ignoresSafeArea())
        }
    }
}
