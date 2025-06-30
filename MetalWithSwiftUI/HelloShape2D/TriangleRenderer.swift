//
//  TriangleRenderer.swift
//  MetalWithSwiftUI
//
//  Created by CurvSurf-SGKim on 6/23/25.
//

import simd
import Metal

fileprivate struct Vertex {
    let position: simd_float2
    let color: simd_float3
}

final class TriangleRenderer {
    
    private let pipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    
    init(_ device: MTLDevice, _ library: MTLLibrary) {
        
        // --- function creation ---
        let vertexFunction = library.makeFunction(name: "hello_triangle::vertex_function")!
        let fragmentFunction = library.makeFunction(name: "hello_triangle::fragment_function")!
        
        // --- vertex data ---
        let vertexSize = MemoryLayout<Vertex>.stride
        let angles: [Float] = [0, 0.33, 0.67].map { (2.0 * $0 + 0.5) * .pi }
        var vertexData: [Vertex] = angles.enumerated().map { (index, angle) in
            
            let radius: Float = 0.67
            let pos = radius * simd_float2(cos(angle), sin(angle))
            
            let color = switch index % 3 {
            case 0: simd_float3(1, 0, 0)
            case 1: simd_float3(0, 1, 0)
            default: simd_float3(0, 0, 1)
            }
            
            return Vertex(position: pos, color: color)
        }
        let vertexBufferLength = MemoryLayout<Vertex>.stride * vertexData.count
        let vertexBuffer = device.makeBuffer(bytes: &vertexData, length: vertexBufferLength)!
        
        // --- vertex format ---
        let vertexDescriptor = MTLVertexDescriptor()
        
        // float2 position [[ attribute(0) ]];
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = MemoryLayout<Vertex>.offset(of: \.position)!
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // float3 color [[ attribute(1) ]];
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = MemoryLayout<Vertex>.offset(of: \.color)!
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stride = vertexSize
        
        // --- render pipeline ---
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.rasterSampleCount = 1
        
        let pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        self.pipelineState = pipelineState
        self.vertexBuffer = vertexBuffer
    }
    
    var viewAspectRatio: Float = 1.0
    var transform: simd_float4x4 = .init(1.0)
    var brightness: Float = 1.0
    
    func draw(_ encoder: MTLRenderCommandEncoder) {
     
        var transform = self.transform
        if viewAspectRatio > 1.0 {
            transform = .scale(x: 1 / viewAspectRatio) * transform
        } else {
            transform = .scale(y: viewAspectRatio) * transform
        }
        
        encoder.setRenderPipelineState(self.pipelineState)
        
        encoder.setVertexBuffer(self.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&transform, length: MemoryLayout<simd_float4x4>.stride, index: 1)
        
        encoder.setFragmentBytes(&self.brightness, length: MemoryLayout<Float>.stride, index: 1)
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
    }
}
