//
//  HelloCone.swift
//  MetalWithSwiftUI
//
//  Created by Donggyu Lee on 2/7/2025.
//

import Metal
import MetalKit

fileprivate func generateConeVertices(radius: Float, height: Float, segmentCount: Int) -> (vertices: [HelloShading3DRenderer.Vertex], indices: [UInt16])
{
    // Arrays where I can store vertex data and index data
    var vertices: [HelloShading3DRenderer.Vertex] = []
    var indices: [UInt16] = []
    
    // 1) Apex vertex
    let apex = SIMD3<Float>(0, height, 0)
    let apexNormal = normalize(SIMD3<Float>(0, radius, height))
    let apexTexcoord = SIMD2<Float>(0.5, 1)
    let apexIndex: UInt16 = 0                   // First, append the apex vertices[0]
    vertices.append(
        HelloShading3DRenderer.Vertex(
            position: apex,
            normal: apexNormal,
            texcoord: apexTexcoord)
    )
    
    // 2) Base-center vertex
    let baseCenter = SIMD3<Float>(0, 0, 0)
    let baseNormal = SIMD3<Float>(0, -1, 0)
    let baseTexcoord = SIMD2<Float>(0.5, 0.5)
    let baseCenterIndex: UInt16 = 1             // Then, append the base-center vertices[1]
    vertices.append(
        HelloShading3DRenderer.Vertex(
            position: baseCenter,
            normal: baseNormal,
            texcoord: baseTexcoord)
    )
    
    // 3) Base circle (Rim)
    for segment in 0..<segmentCount {
        let segmentFraction = Float(segment) / Float(segmentCount)
        let angle = segmentFraction * 2 * (.pi)
        let x = radius * cos(angle)
        let z = radius * sin(angle)

        // Get the position vector, normal vector, and texture coordinate vector
        // position: a point on the rim(x,0,z)
        // slantMid: a point in between rim(x, 0, z) and apex(0, y, 0)
        // normal: normal for side
        // texcoord: -1 < x = cos(angle) < 1 && -1 < z = sin(angle) < 1
        //           divide by 2 and shift up by 0.5 changes the range [-1,1] to [0,1]
        
        let position = SIMD3<Float>(x, 0, z)
        let slantMid = SIMD3<Float>(x/2, height/2, z/2)  // 옆면중간점
        let normal = normalize(slantMid)
        let texcoord = SIMD2<Float>(cos(angle)/2 + 0.5, sin(angle)/2 + 0.5)
        
        vertices.append(
            HelloShading3DRenderer.Vertex(
                position: position,
                normal: normal,
                texcoord: texcoord)
        )
    }
    
    // 4) Build indices
    // Side Triangle: [ apex, nowRim, nextRim ]
    // Base Triangle: [ baseCenter, nextRim, nowRim ]
    
    /*
     Side triangle (counter-clockwise)          Base triangle (counter-clockwise)
              apex                               nowRim ------ nextRim
              / \                                   \            /
             /   \                                   \          /
            /     \                                   \        /
           /       \                                   \      /
          /         \                                   \    /
         /           \                                   \  /
     nowRim ------ nextRim                            baseCenter
     
      apex >>> nowRim >>> nextRim                baseCenter >>> nextRim >>> nowRim
     
     */
    
    for slice in 0..<segmentCount {
        let nowRim = UInt16(2 + slice)                       // if segmentCount = 4 and nowRim = 3
        let nextRim = UInt16(2 + ((slice+1) % segmentCount)) // nextRim = 0 (not 4) 0→1→2→3→0
        
        // Side triangle
        indices += [apexIndex, nowRim, nextRim]
        
        // Base triangle
        indices += [baseCenterIndex, nextRim, nowRim]
    }
    
    return (vertices, indices)
}

final class HelloCone: HelloShading3DObject {
    
    let device: MTLDevice
    var vertexBuffer: any MTLBuffer
    var indexBuffer: any MTLBuffer
    var indexType: MTLIndexType = .uint16
    var indexCount: Int
    var modelMatrix: simd_float4x4 = .init(1)
    var texture: (any MTLTexture)?
    
    init(device: MTLDevice,
         radius: Float = 1,
         height: Float = 2,
         segments: Int = 40) throws
    {
        self.device = device
        
        let mesh = generateConeVertices(
            radius: radius,
            height: height,
            segmentCount: segments)
        
        self.indexCount = mesh.indices.count
        
        // Create Vertex Buffer
        let vertexStride = MemoryLayout<HelloShading3DRenderer.Vertex>.stride
        let vertexBufferLength = vertexStride * mesh.vertices.count
        let vertexBuffer = device.makeBuffer(bytes: mesh.vertices, length: vertexBufferLength)!
        
        // Create Index Buffer
        let indexStride = MemoryLayout<UInt16>.stride
        let indexBufferLength = indexStride * mesh.indices.count
        let indexBuffer = device.makeBuffer(bytes: mesh.indices, length: indexBufferLength)!
        
        // Load the texture of the cone into a GPU
//        let textureLoader = MTKTextureLoader(device: device)
//        let texture = try! textureLoader.newTexture(name: "checker", scaleFactor: 1.0, bundle: .main, options: [.SRGB: false])
        
        // Store everything into my cone's property
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer
        self.indexCount = mesh.indices.count
//        self.texture = texture
        
    }
}
