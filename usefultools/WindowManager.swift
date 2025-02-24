//
//  WindoManager.swift
//  usefultools
//
//  Created by Luis Amorim on 24/02/25.
//

import SwiftUI
import AppKit

/// A window manager that handles opening and managing separate windows.
/// This manager ensures that only one ColorPicker window is open at any time.
class WindowManager: ObservableObject {
    /// Reference to the currently open ColorPicker window, if any.
    var colorPickerWindow: NSWindow?
    
    /// Opens the ColorPicker window if it is not already open.
    func openColorPicker() {
        // If the window is already open, bring it to the front.
        if let window = colorPickerWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        // Create a new window for the ColorPickerView.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false)
        window.title = "Color Picker"
        window.center()
        
        // Set the window's content to the ColorPickerView.
        window.contentView = NSHostingView(rootView: ColorPickerView())
        
        // Save the window reference.
        colorPickerWindow = window
        
        // Observe window closing to reset the reference.
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            self?.colorPickerWindow = nil
        }
        
        // Show the window.
        window.makeKeyAndOrderFront(nil)
    }
}
