//
//  HelloShape2DView.swift
//  MetalWithSwiftUI
//
//  Created by CurvSurf-SGKim on 6/24/25.
//

import Metal
import MetalKit
import SwiftUI

enum Shape2DType: String, CaseIterable {
    case triangle = "Triangle"
    case square = "Square"
    case circle = "Circle"
}

fileprivate struct ControlView: View {
    
    @Environment(HelloShape2DModel.self) private var content
    
    var body: some View {
        @Bindable var content = content
        VStack {
            HStack {
                Text("Shape: ")
                Picker(selection: $content.shapeType) {
                    ForEach(Shape2DType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                
                let rps = String(format: "%.2f", content.rotationPerSecond)
                Text("Rotation/s: \(rps)")
                
                Slider(value: $content.rotationPerSecond, in: 0.0...1.5)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                
                Text("Brightness: \(content.brightness, format: .percent)")
                
                Slider(value: $content.brightness, in: 0.0...1.0)
            }
        }
    }
}

struct HelloShape2DView: View {
    
    @State private var content = HelloShape2DModel()
    
    var body: some View {
        ZStack {
            MetalView(content.device,
                      onViewResized: content.onViewResized(_:_:),
                      onDraw: content.onDraw(_:))
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                ControlView()
                    .environment(content)
            }
            .padding()
        }
    }
}

#Preview {
    HelloShape2DView()
}
