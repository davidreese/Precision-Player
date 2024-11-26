//
//  Untitled.swift
//  ClosePlayer
//
//  Created by David Reese on 10/16/24.
//
import SwiftUI
import Cocoa

/// Source: https://zachwaugh.com/posts/swiftui-blurred-window-background-macos
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let effectView = NSVisualEffectView()
        effectView.state = .active
        //        effectView.material = .contentBackground
        return effectView
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    }
}


struct FocusedLinearProgressViewStyle: ProgressViewStyle {
    private var tint: Color
    
    init(tint: Color = .primary) {
        self.tint = tint
    }
    
    func makeBody(configuration: Configuration) -> some View {
        let fractionCompleted = configuration.fractionCompleted ?? 0
        
        return VStack {
            Spacer()
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(width: geometry.size.width)
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundColor(tint)
                        .frame(width: geometry.size.width * fractionCompleted)
                }
            }.frame(height: 5)
            Spacer()
        }
    }
    
    private func isWindowFocused() -> Bool {
        let app = NSApplication.shared
        let currentWindow = app.mainWindow
        return currentWindow?.isKeyWindow ?? false
    }
}
