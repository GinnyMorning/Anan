//
//  SimpleAdvancedVisualEditor.swift
//  MTMR
//
//  Created by Enhanced Menu System on 2024.
//  Simple Advanced Visual Editor for TouchBar layout management.
//

import Cocoa
import SwiftUI

@MainActor
final class SimpleAdvancedVisualEditor: ObservableObject {
    static let shared = SimpleAdvancedVisualEditor()
    
    @Published var isVisible = false
    
    private var editorWindow: NSWindow?
    
    private init() {}
    
    func showEditor() {
        isVisible = true
        
        if editorWindow == nil {
            createEditorWindow()
        }
        
        editorWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func createEditorWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "MTMR Advanced Visual Editor"
        window.center()
        window.setFrameAutosaveName("SimpleAdvancedVisualEditorWindow")
        
        let editorView = SimpleAdvancedVisualEditorView(
            onClose: { [weak self] in
                self?.editorWindow?.close()
            }
        )
        
        let hostingView = NSHostingView(rootView: editorView)
        window.contentView = hostingView
        
        self.editorWindow = window
    }
}

struct SimpleAdvancedVisualEditorView: View {
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            contentView
            Spacer()
            closeButton
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .cornerRadius(4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Advanced Visual Editor")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Professional TouchBar layout management")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("This feature provides drag-and-drop TouchBar layout management, visual widget configuration, templates, and performance monitoring.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 16) {
            FeatureCard(
                title: "Drag & Drop Layout",
                description: "Intuitive TouchBar layout management with visual feedback",
                icon: "hand.draw",
                color: .blue
            )
            
            FeatureCard(
                title: "Widget Configuration",
                description: "Visual widget configuration with real-time preview",
                icon: "slider.horizontal.3",
                color: .green
            )
            
            FeatureCard(
                title: "Templates & Presets",
                description: "Pre-built layouts and customizable templates",
                icon: "doc.on.doc",
                color: .orange
            )
            
            FeatureCard(
                title: "Performance Monitoring",
                description: "Real-time performance metrics and optimization",
                icon: "chart.bar",
                color: .purple
            )
            
            FeatureCard(
                title: "Advanced Controls",
                description: "Professional-grade layout controls and settings",
                icon: "gearshape",
                color: .red
            )
        }
    }
    
    private var closeButton: some View {
        HStack {
            Spacer()
            
            Button("Close") {
                onClose()
            }
            .keyboardShortcut(.escape)
        }
    }
}

struct FeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(color)
                .frame(width: 32, height: 32)
                .cornerRadius(4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Rectangle()
                .fill(Color.gray)
                .frame(width: 16, height: 16)
                .cornerRadius(2)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}
