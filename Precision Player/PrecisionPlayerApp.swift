//
//  PrecisionPlayerApp.swift
//  PrecisionPlayer
//
//  Created by David Reese on 6/14/23.
//

import SwiftUI
import AVKit

@main
struct PrecisionPlayerApp: App {
    
//    @FocusState private var isFocused: Bool
    
    var body: some Scene {
        Window(Text("Precision Player"), id: "main") {
            ContentView()
                .background(VisualEffectView().ignoresSafeArea())
        }
    }
}
