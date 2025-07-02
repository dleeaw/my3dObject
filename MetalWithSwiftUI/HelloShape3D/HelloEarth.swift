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
    let radius: Float = 2.0     // unit sphere
    let latitude = 40           // 위도 - 가로선 - 높이 - stack을 "40"개로 분할
    let longitude = 40          // 경도 - 세로선 - 너비 - sector를 "40"개로 분할
    
    // Arrays where I can store vertex data and index data
    var vertices: [HelloShading3DRenderer.Vertex] = []
    var indices: [UInt16] = []
    
    // 1) Build vertices
    for countLat in 0...latitude {
        let phi = ((.pi)/2) - (.pi) * (Float(countLat)/Float(latitude))
        let cosφ = cos(phi)
        let sinφ = sin(phi)
        
        for countLon in 0...longitude {
            let theta = 2 * (.pi) * (Float(countLon)/Float(longitude))
            let cosθ = cos(theta)
            let sinθ = sin(theta)
            
            // Cartesian coordinate on unit sphere
            let x = cosφ * cosθ
            let y = cosφ * sinθ
            let z = sinφ
            
            // Get the position vector, normal vector, and text coordinate vector
            let position = SIMD3<Float>(x, y, z) * radius
            let normal = normalize(SIMD3<Float>(x, y, z))
            let textcoord = SIMD2<Float>(Float(countLon)/Float(longitude),
                                         Float(countLat)/Float(latitude))
            
            // Add to vertices array
            vertices.append(
                HelloShading3DRenderer.Vertex(
                    position: position,
                    normal: normal,
                    texcoord: textcoord)
            )
        }
    }
    
    // 2) Build index list
    // triangle index in sphere
    //
    //                (c)th column         (c+1)th column
    //
    // (r)th row:       topLeft ------------ topRight
    //                   (r,c)               (r, c+1)
    //                     |                /    |
    //                     ↓          /          ↑
    //                     |    /                |
    // (r+1)th row:     bottomLeft --→---→-- bottomRight
    //                  (r+1, c)             (r+1, c+1)
    //
    // triangle A: topLeft → bottomLeft → topRight
    // triangle B: topRight → bottomLeft → bottomRight
    
    let cols = longitude + 1    // total numbers of column in the sphere
    
    for r in 0..<latitude {                                 // current row
        for c in 0..<longitude {                            // current column
            let topLeft     = UInt16( r * cols + c )        // ex) triangle in 2nd row, 3rd column
            let bottomLeft  = UInt16( (r+1) * cols + c )    // index = 2 * 40 + 3 = 83
            let topRight    = UInt16( r * cols + c+1 )
            let bottomRight = UInt16( (r+1) * cols + c+1 )
            
            // Triangle A
            indices += [topLeft, bottomLeft, topRight]      // counterclockwise direction
            
            // Triangle B
            indices += [topRight, bottomLeft, bottomRight]  // counterclockwise direction
        }
    }
    
    return (vertices: vertices, indices: indices)
}
