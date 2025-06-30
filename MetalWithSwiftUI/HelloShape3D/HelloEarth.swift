//
//  HelloEarth.swift
//  MetalWithSwiftUI
//
//  Created by Donggyu Lee on 30/6/2025.
//

import Metal
import MetalKit

final class HelloEarth: HelloShading3DObject {
    
    var vertexBuffer: any MTLBuffer
    var indexBuffer: any MTLBuffer                  
    var indexType: MTLIndexType = .uint16
    var indexCount: Int
    var modelMatrix: simd_float4x4 = .init(0.67)
    var texture: (any MTLTexture)?
    
    init(_ device: MTLDevice) {
        
        // 1) Generate 3D Sphere mesh on the CPU
        var (vertices, indices) = generateSphereVertices()
        
        // 2) Create Vertex Buffer for the GPU
        let vertexStride = MemoryLayout<HelloShading3DRenderer.Vertex>.stride
        let vertexBufferLength = vertices.count * vertexStride
        let vertexBuffer = device.makeBuffer(bytes: &vertices, length: vertexBufferLength)!
        
        // 3) Create Index Buffer for the GPU
        let indexStride = MemoryLayout<UInt16>.stride
        let indexBufferLength = indices.count * indexStride
        let indexBuffer = device.makeBuffer(bytes: &indices, length: indexBufferLength)!
        
        // 4) Load the Earth image into a GPU texture
        let textureLoader = MTKTextureLoader(device: device)
        let texture = try! textureLoader.newTexture(name: "earth", scaleFactor: 1.0, bundle: .main, options: [.SRGB: false])
        
        // 5) Store everything into my Earth's property
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer
        self.indexCount = indices.count
        self.texture = texture
    }
}

fileprivate func generateSphereVertices() -> (vertices: [HelloShading3DRenderer.Vertex], indices: [UInt16])
{
    let vertices: [HelloShading3DRenderer.Vertex] = []
    
    let indices: [UInt16] = []
    
    return (vertices: vertices, indices: indices)
}
