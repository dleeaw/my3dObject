//
//  CircleRenderer.swift
//  MetalWithSwiftUI
//
//  Created by CurvSurf-SGKim on 6/24/25.
//

import simd
import Metal

fileprivate struct Vertex {
    let position: simd_float2
}

final class CircleRenderer {
    
    private let pipelineState: MTLRenderPipelineState
    private let vertexBuffer: MTLBuffer
    private let indexBuffer: MTLBuffer
    private let indexCount: Int
    
    init(_ device: MTLDevice, _ library: MTLLibrary) {
        
        // --- function creation ---
        let vertexFunction = library.makeFunction(name: "hello_circle::vertex_function")!
        let fragmentFunction = library.makeFunction(name: "hello_circle::fragment_function")!
        
        // --- vertex data ---
        let vertexSize = MemoryLayout<Vertex>.stride
        let angles = (0...32).map { index in
            let ratio = Float(index) / 32.0
            return ratio * .pi * 2
        }
        let rimVertices = angles.map { angle in
            return 0.67 * simd_float2(cos(angle), sin(angle))
        }
        
        var vertexData = [Vertex]()
        vertexData.reserveCapacity(angles.count + 1)
        vertexData.append(Vertex(position: .zero)) // 0
        vertexData.append(contentsOf: rimVertices.map { Vertex(position: $0) }) // 1...33
        
        let vertexBufferLength = MemoryLayout<Vertex>.stride * vertexData.count
        let vertexBuffer = device.makeBuffer(bytes: &vertexData, length: vertexBufferLength)!
        
        // --- vertex format ---
        let vertexDescriptor = MTLVertexDescriptor()
        
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = MemoryLayout<Vertex>.offset(of: \.position)!
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stride = vertexSize
        
        // --- index data ---
        var indices: [UInt16] = (1..<33).map { index in
//            0, 1, 2,
//            0, 2, 3,
//            0, 3, 4,
//            ...
//            0, 32, 33,
            [0, index, index + 1]
        }.flatMap { $0 }.map { UInt16($0) }
        let indexBufferLength = MemoryLayout<UInt16>.stride * indices.count
        let indexBuffer = device.makeBuffer(bytes: &indices, length: indexBufferLength)!
        
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
        self.indexBuffer = indexBuffer
        self.indexCount = indices.count
    }
    
    var viewAspectRatio: Float { viewSize.x / viewSize.y }
    var transform: simd_float4x4 = .init(1.0)
    var brightness: Float = 1.0
    var time: Float = 0.0
    var viewSize: simd_float2 = .zero
    
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
        encoder.setVertexBytes(&self.viewSize, length: MemoryLayout<simd_float2>.stride, index: 2)
        
        encoder.setFragmentBytes(&self.brightness, length: MemoryLayout<Float>.stride, index: 1)
        encoder.setFragmentBytes(&self.time, length: MemoryLayout<Float>.stride, index: 2)
        encoder.setFragmentBytes(&self.viewSize, length: MemoryLayout<simd_float2>.stride, index: 3)
        
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: self.indexCount,
                                      indexType: .uint16,
                                      indexBuffer: self.indexBuffer,
                                      indexBufferOffset: 0)
    }
}
