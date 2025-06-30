//
//  HelloShading3DRenderer.swift
//  MetalWithSwiftUI
//
//  Created by CurvSurf-SGKim on 6/25/25.
//

import simd
import Metal


protocol HelloShading3DObject {
    var vertexBuffer: MTLBuffer { get }
    var indexBuffer: MTLBuffer { get }
    var indexType: MTLIndexType { get }
    var indexCount: Int { get }
    var modelMatrix: simd_float4x4 { get set }
    var texture: MTLTexture? { get }
}

final class HelloShading3DRenderer {
    
    struct Vertex {
        let position: simd_float3
        let normal: simd_float3
        let texcoord: simd_float2
    }
    
    private let pipelineState: MTLRenderPipelineState
    private let uniformBufferEncoder: MTLArgumentEncoder
    private let uniformBuffer: MTLBuffer
    
    init(_ device: MTLDevice, _ library: MTLLibrary) {
        
        // --- function creation ---
        let vertexFunction = library.makeFunction(name: "hello_shading_3d::vertex_function")!
        let fragmentFunction = library.makeFunction(name: "hello_shading_3d::fragment_function")!
        
        // --- vertex format ---
        let vertexDescriptor = MTLVertexDescriptor()
        
        // attributes[0] is position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = MemoryLayout<Vertex>.offset(of: \.position)!
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // attributes[1] is normal
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = MemoryLayout<Vertex>.offset(of: \.normal)!
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        // attributes[2] is texture coordinates
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = MemoryLayout<Vertex>.offset(of: \.texcoord)!
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        
        // --- render pipeline ---
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        pipelineDescriptor.rasterSampleCount = 1
        
        let pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        // --- uniform buffer ---
        let uniformBufferEncoder = vertexFunction.makeArgumentEncoder(bufferIndex: 2)
        let bufferLength = uniformBufferEncoder.encodedLength
        let uniformBuffer = device.makeBuffer(length: bufferLength)!
        uniformBufferEncoder.setArgumentBuffer(uniformBuffer, offset: 0)
        
        self.pipelineState = pipelineState
        self.uniformBufferEncoder = uniformBufferEncoder
        self.uniformBuffer = uniformBuffer
        
        self.updateViewMatrix(.init(1.0))
        self.updateProjectionMatrix(.init(1.0))
        self.updateCameraPosition(.zero)
        self.updateLightPosition(.zero)
        self.updateLightColor(.one)
        self.updateLightIntensity(1.0)
        self.updateAmbientIntensity(1.0)
        self.updateSpecularPower(1.0)
    }
    
    func updateViewMatrix(_ viewMatrix: simd_float4x4) {
        uniformBufferEncoder.constantData(at: 0).bindMemory(to: simd_float4x4.self, capacity: 1).pointee = viewMatrix
    }
    
    func updateProjectionMatrix(_ projectionMatrix: simd_float4x4) {
        uniformBufferEncoder.constantData(at: 1).bindMemory(to: simd_float4x4.self, capacity: 1).pointee = projectionMatrix
    }
    
    func updateCameraPosition(_ cameraPosition: simd_float3) {
        uniformBufferEncoder.constantData(at: 2).bindMemory(to: simd_float3.self, capacity: 1).pointee = cameraPosition
    }
    
    func updateLightPosition(_ lightPosition: simd_float3) {
        uniformBufferEncoder.constantData(at: 3).bindMemory(to: simd_float3.self, capacity: 1).pointee = lightPosition
    }
    
    func updateLightColor(_ lightColor: simd_float3) {
        uniformBufferEncoder.constantData(at: 4).bindMemory(to: simd_float3.self, capacity: 1).pointee = lightColor
    }
    
    func updateLightIntensity(_ lightIntensity: Float) {
        uniformBufferEncoder.constantData(at: 5).bindMemory(to: Float.self, capacity: 1).pointee = lightIntensity
    }
    
    func updateAmbientIntensity(_ ambientIntensity: Float) {
        uniformBufferEncoder.constantData(at: 6).bindMemory(to: Float.self, capacity: 1).pointee = ambientIntensity
    }
    
    func updateSpecularPower(_ specularPower: Float) {
        uniformBufferEncoder.constantData(at: 7).bindMemory(to: Float.self, capacity: 1).pointee = specularPower
    }
    
    func draw<M: HelloShading3DObject>(_ model: M,
                                       _ encoder: MTLRenderCommandEncoder) {
        var model = model
        encoder.setCullMode(.back)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setRenderPipelineState(self.pipelineState)
        
        encoder.setVertexBuffer(model.vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBytes(&model.modelMatrix, length: MemoryLayout<simd_float4x4>.stride, index: 1)
        encoder.setVertexBuffer(self.uniformBuffer, offset: 0, index: 2)
        
        encoder.setFragmentBuffer(self.uniformBuffer, offset: 0, index: 1)
        encoder.setFragmentTexture(model.texture, index: 0)
        
        encoder.drawIndexedPrimitives(type: .triangle,
                                      indexCount: model.indexCount,
                                      indexType: model.indexType,
                                      indexBuffer: model.indexBuffer,
                                      indexBufferOffset: 0)
    }
}


