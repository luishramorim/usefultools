//
//  ColorPickerView.swift
//  usefultools
//
//  Created by Luis Amorim on 24/02/25.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// An extension on `NSView` that provides a method to capture the view’s current appearance
/// as a high-quality `NSImage`. The function takes into account the screen’s backing scale factor,
/// ensuring that the exported image is rendered at a higher resolution.
/// - Returns: An optional `NSImage` representing a snapshot of the view.
extension NSView {
    func snapshot() -> NSImage? {
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(bounds.width * scale),
            pixelsHigh: Int(bounds.height * scale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0) else { return nil }
        rep.size = bounds.size
        cacheDisplay(in: bounds, to: rep)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)
        return image
    }
}

/// A view intended for export. It displays a rectangle filled with the selected color
/// and the HEX code below it, with added padding and a border.
/// - Parameters:
///   - color: The color to be displayed.
///   - hexColor: The HEX string representation of the color.
struct ExportColorView: View {
    var color: Color
    var hexColor: String

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(color)
                .frame(height: 200)
            Text(hexColor)
                .font(.headline)
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.white)
        }
        .padding() // Added padding around the export content.
        .border(Color.black, width: 1)
    }
}

/// A view that displays RGB sliders and text fields for selecting a color,
/// shows its HEX representation, allows editing the HEX value (updating the RGB values),
/// and permits exporting the color as a high-quality PNG image.
/// The exported image is generated as a 500×500 pixel image with a white background.
/// All documentation is provided in DocC-style comments.
///
struct ColorPickerView: View {
    /// The red component value (0 to 255).
    @State private var red: Double = 127
    /// The green component value (0 to 255).
    @State private var green: Double = 127
    /// The blue component value (0 to 255).
    @State private var blue: Double = 127
    /// A Boolean state that indicates if the "Copied!" feedback should be shown.
    @State private var showCopiedFeedback: Bool = false
    /// A state variable for the HEX text field. It supports two-way editing.
    @State private var hexInput: String = "#7F7F7F"
    
    /// Computes the current `Color` based on the RGB slider values.
    var color: Color {
        Color(red: red / 255, green: green / 255, blue: blue / 255)
    }
    
    /// Computes the HEX representation of the current color (including the '#' prefix).
    var hexColor: String {
        let r = Int(red)
        let g = Int(green)
        let b = Int(blue)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack(spacing: 20) {
                    // Left column: Display the color in a rounded rectangle.
                    Rectangle()
                        .fill(color)
                        .frame(width: 170, height: 170)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    
                    // Right column: Controls for adjusting the color, editing the HEX value,
                    // and copying/exporting the HEX code.
                    VStack(alignment: .leading, spacing: 20) {
                        // Editable HEX text field and buttons.
                        HStack(alignment: .center) {
                            TextField("HEX", text: $hexInput)
                                .font(.title)
                                .bold()
                                .textFieldStyle(PlainTextFieldStyle())
                                .frame(minWidth: 100)
                                .onSubmit {
                                    updateRGBFromHex(hexInput)
                                }
                            
                            Spacer()
                            
                            // Copy button: Copies the HEX code to the clipboard.
                            Image(systemName: "doc.on.clipboard")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .overlay {
                                    if showCopiedFeedback {
                                        Text("Copied!")
                                            .font(.caption)
                                            .padding(5)
                                            .background(Color.black.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(5)
                                            .offset(y: -30)
                                            .transition(.opacity)
                                            .frame(width: 100)
                                    }
                                }
                                .onTapGesture {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents()
                                    pasteboard.setString(hexColor, forType: .string)
                                    
                                    withAnimation {
                                        showCopiedFeedback = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            showCopiedFeedback = false
                                        }
                                    }
                                }
                            
                            // Export button: Initiates the export of the current color as a PNG file.
                            Button(action: exportColor) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Sliders and text fields for individual RGB components.
                        HStack {
                            Text("Red:")
                                .frame(width: 50, alignment: .leading)
                            Slider(value: $red, in: 0...255, step: 1)
                            TextField("", text: Binding(
                                get: { "\(Int(red))" },
                                set: { newValue in
                                    if let value = Double(newValue) {
                                        red = min(max(value, 0), 255)
                                    }
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50)
                        }
                        
                        HStack {
                            Text("Green:")
                                .frame(width: 50, alignment: .leading)
                            Slider(value: $green, in: 0...255, step: 1)
                            TextField("", text: Binding(
                                get: { "\(Int(green))" },
                                set: { newValue in
                                    if let value = Double(newValue) {
                                        green = min(max(value, 0), 255)
                                    }
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50)
                        }
                        
                        HStack {
                            Text("Blue:")
                                .frame(width: 50, alignment: .leading)
                            Slider(value: $blue, in: 0...255, step: 1)
                            TextField("", text: Binding(
                                get: { "\(Int(blue))" },
                                set: { newValue in
                                    if let value = Double(newValue) {
                                        blue = min(max(value, 0), 255)
                                    }
                                }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 50)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
                .padding()
                .frame(width: 500, height: 220)
            }
        }
        // Update the HEX text field whenever RGB values change.
        .onChange(of: red) { _ in hexInput = hexColor }
        .onChange(of: green) { _ in hexInput = hexColor }
        .onChange(of: blue) { _ in hexInput = hexColor }
    }
    
    /// Parses a HEX string and updates the RGB values accordingly.
    /// - Parameter hex: A HEX color string (with or without a '#' prefix).
    func updateRGBFromHex(_ hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }
        guard hexString.count == 6, let hexValue = Int(hexString, radix: 16) else { return }
        let r = Double((hexValue >> 16) & 0xFF)
        let g = Double((hexValue >> 8) & 0xFF)
        let b = Double(hexValue & 0xFF)
        red = r
        green = g
        blue = b
    }
    
    /// Exports the current color view as a high-quality PNG image file.
    /// The exported image is generated as a 500×500 pixel image with a white background.
    /// A save panel is presented so the user can choose the file location and name.
    func exportColor() {
        // Create the view for export: a 500x500 image with a white background.
        let exportView = ZStack {
            Color.white
            ExportColorView(color: color, hexColor: hexColor)
        }
        .frame(width: 500, height: 500)
        
        let hostingView = NSHostingView(rootView: exportView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 500, height: 500)
        
        // Capture the view as an NSImage.
        guard let image = hostingView.snapshot() else { return }
        
        // Convert the image to PNG data.
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:])
        else { return }
        
        // Create a default file name using the HEX code (without the '#' character).
        let hexName = hexColor.replacingOccurrences(of: "#", with: "")
        let defaultFileName = "\(hexName)_ExportedColor.png"
        
        // Configure and present the save panel.
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.png]
        savePanel.nameFieldStringValue = defaultFileName
        savePanel.title = "Export Color as PNG"
        savePanel.prompt = "Save"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try pngData.write(to: url)
                print("Export successful to \(url)")
            } catch {
                print("Error writing PNG file: \(error)")
            }
        }
    }
}

#Preview {
    ColorPickerView()
}
