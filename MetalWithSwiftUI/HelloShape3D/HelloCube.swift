//
//  HelloCube.swift
//  MetalWithSwiftUI
//
//  Created by CurvSurf-SGKim on 6/25/25.
//

import Metal
import MetalKit

final class HelloCube: HelloShading3DObject {
    
    let vertexBuffer: any MTLBuffer
    let indexBuffer: any MTLBuffer
    let indexType: MTLIndexType = .uint16
    let indexCount: Int
    var modelMatrix: simd_float4x4 = .init(0.67)
    let texture: MTLTexture?
    
    init(_ device: MTLDevice) {
        
        var (vertices, indices) = generateCubeVertices()
        
        let vertexStride = MemoryLayout<HelloShading3DRenderer.Vertex>.stride
        let vertexBufferLength = vertices.count * vertexStride
        let vertexBuffer = device.makeBuffer(bytes: &vertices, length: vertexBufferLength)!
        
        let indexBufferLength = indices.count * MemoryLayout<UInt16>.stride
        let indexBuffer = device.makeBuffer(bytes: &indices, length: indexBufferLength)!
        
        let textureLoader = MTKTextureLoader(device: device)
        let texture = try! textureLoader.newTexture(name: "dice", scaleFactor: 1.0, bundle: .main, options: [.SRGB: false])
        
        self.vertexBuffer = vertexBuffer
        self.indexBuffer = indexBuffer
        self.indexCount = indices.count
        self.texture = texture
    }
}

fileprivate func generateCubeVertices() -> (vertices: [HelloShading3DRenderer.Vertex], indices: [UInt16]) {
    
    // positions
    //
    //      l: left   r: right
    //      |         |
    //     ulf ----- urf -- u: upper
    //     /|        /|
    //    / |       / |
    //  uln ----- urn |
    //   |  |      |  |  -- l: lower
    //   | llf ----| lrf -- f: far
    //   | /       | /
    //   |/        |/
    //  lln ----- lrn -- n: near
    //
    let lln = simd_float3(-1, -1, +1)
    let llf = simd_float3(-1, -1, -1)
    let uln = simd_float3(-1, +1, +1)
    let ulf = simd_float3(-1, +1, -1)
    let lrn = simd_float3(+1, -1, +1)
    let lrf = simd_float3(+1, -1, -1)
    let urn = simd_float3(+1, +1, +1)
    let urf = simd_float3(+1, +1, -1)
    
    // normals
    let front = simd_float3(0, 0, 1)
    let back = -front
    let right = simd_float3(1, 0, 0)
    let left = -right
    let up = simd_float3(0, 1, 0)
    let down = -up
    
    // texture coordinates
    // 0.0       0.25         0.50         0.75       1.0
    //  |         |            |            |          |
    // ul1 --- ur1, ul2 --- ur2, ul3 --- ur3, 000 --- 000 -- 0.0
    //  |       |    | 0     |    |     0 |    |       |
    //  |   0   |    |       |    |   0   |    |       |
    //  |       |    |     0 |    | 0     |    |       |
    // ll1 --- lr1, ll2 --- lr2, ll3 --- lr3, 000 --- 000 -- 0.5
    // ul4 --- ur4, ul5 --- ur5, ul6 --- ur6, 000 --- 000
    //  | 0   0 |    | 0   0 |    | 0   0 |    |       |
    //  |       |    |   0   |    | 0   0 |    |       |
    //  | 0   0 |    | 0   0 |    | 0   0 |    |       |
    // ll4 --- lr4, ll5 --- lr5, ll6 --- lr6, 000 --- 000 -- 1.0
    
    let ll1 = simd_float2(0.00, 0.50)
    let ul1 = simd_float2(0.00, 0.00)
    let lr1 = simd_float2(0.25, 0.50)
    let ur1 = simd_float2(0.25, 0.00)
    let ll2 = simd_float2(0.25, 0.50)
    let ul2 = simd_float2(0.25, 0.00)
    let lr2 = simd_float2(0.50, 0.50)
    let ur2 = simd_float2(0.50, 0.00)
    let ll3 = simd_float2(0.50, 0.50)
    let ul3 = simd_float2(0.50, 0.00)
    let lr3 = simd_float2(0.75, 0.50)
    let ur3 = simd_float2(0.75, 0.00)
    let ll4 = simd_float2(0.00, 1.00)
    let ul4 = simd_float2(0.00, 0.50)
    let lr4 = simd_float2(0.25, 1.00)
    let ur4 = simd_float2(0.25, 0.50)
    let ll5 = simd_float2(0.25, 1.00)
    let ul5 = simd_float2(0.25, 0.50)
    let lr5 = simd_float2(0.50, 1.00)
    let ur5 = simd_float2(0.50, 0.50)
    let ll6 = simd_float2(0.50, 1.00)
    let ul6 = simd_float2(0.50, 0.50)
    let lr6 = simd_float2(0.75, 1.00)
    let ur6 = simd_float2(0.75, 0.50)
    
    let vertices: [HelloShading3DRenderer.Vertex] = [
        .init(position: lln, normal: front, texcoord: ll1), // front
        .init(position: uln, normal: front, texcoord: ul1),
        .init(position: lrn, normal: front, texcoord: lr1),
        .init(position: urn, normal: front, texcoord: ur1),
        .init(position: lrn, normal: right, texcoord: ll3), // right
        .init(position: urn, normal: right, texcoord: ul3),
        .init(position: lrf, normal: right, texcoord: lr3),
        .init(position: urf, normal: right, texcoord: ur3),
        .init(position: lrf, normal: back, texcoord: ll6), // back
        .init(position: urf, normal: back, texcoord: ul6),
        .init(position: llf, normal: back, texcoord: lr6),
        .init(position: ulf, normal: back, texcoord: ur6),
        .init(position: llf, normal: left, texcoord: ll4), // left
        .init(position: ulf, normal: left, texcoord: ul4),
        .init(position: lln, normal: left, texcoord: lr4),
        .init(position: uln, normal: left, texcoord: ur4),
        .init(position: uln, normal: up, texcoord: ll2), // up
        .init(position: ulf, normal: up, texcoord: ul2),
        .init(position: urn, normal: up, texcoord: lr2),
        .init(position: urf, normal: up, texcoord: ur2),
        .init(position: llf, normal: down, texcoord: ll5), // down
        .init(position: lln, normal: down, texcoord: ul5),
        .init(position: lrf, normal: down, texcoord: lr5),
        .init(position: lrn, normal: down, texcoord: ur5)
    ]
    
    let indices: [UInt16] = [
        0, 2, 1, 1, 2, 3,
        4, 6, 5, 5, 6, 7,
        8, 10, 9, 9, 10, 11,
        12, 14, 13, 13, 14, 15,
        16, 18, 17, 17, 18, 19,
        20, 22, 21, 21, 22, 23
    ]
    
    return (vertices: vertices, indices: indices)
}
