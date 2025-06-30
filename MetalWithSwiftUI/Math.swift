//
//  Math.swift
//  MetalWithSwiftUI
//
//  Created by CurvSurf-SGKim on 6/23/25.
//

import simd

func clamp<C: Comparable>(_ x: C, min: C, max: C) -> C {
    return Swift.max(Swift.min(x, max), min)
}

func orientedAngle(_ x: simd_float3,
                   _ y: simd_float3,
                   _ ref: simd_float3) -> Float {
    let angle = acos(Swift.min(Swift.max(dot(x, y), -1.0), 1.0))
    return simd_mix(angle, -angle, dot(ref, cross(x, y)) < 0 ? 1.0 : 0.0)
}

extension simd_float4x4 {
    
    static func scale(x: Float = 1.0, y: Float = 1.0, z: Float = 1.0) -> simd_float4x4 {
        return .init(.init(x, 0, 0, 0),
                     .init(0, y, 0, 0),
                     .init(0, 0, z, 0),
                     .init(0, 0, 0, 1))
    }
    
    static func scale(factors: simd_float3) -> simd_float4x4 {
        return .scale(x: factors.x, y: factors.y, z: factors.z)
    }
    
    static func scale(factor: Float) -> simd_float4x4 {
        return .scale(x: factor, y: factor, z: factor)
    }
    
    static func translate(x: Float = 0.0, y: Float = 0.0, z: Float = 0.0) -> simd_float4x4 {
        return .init(.init(1, 0, 0, 0),
                     .init(0, 1, 0, 0),
                     .init(0, 0, 1, 0),
                     .init(x, y, z, 1))
    }
    
    static func translate(offset: simd_float3) -> simd_float4x4 {
        return .translate(x: offset.x, y: offset.y, z: offset.z)
    }
    
    static func rotate(angle: Float, along axis: simd_float3) -> simd_float4x4 {
    
        let c = cos(angle)
        let s = sin(angle)
        
        let axis = normalize(axis)
        let temp = (1 - c) * axis
        
        let m00 = c + temp.x * axis.x;
        let m01 = temp.x * axis.y + s * axis.z;
        let m02 = temp.x * axis.z - s * axis.y;
        let m10 = temp.y * axis.x - s * axis.z;
        let m11 = c + temp.y * axis.y;
        let m12 = temp.y * axis.z + s * axis.x;
        let m20 = temp.z * axis.x + s * axis.y;
        let m21 = temp.z * axis.y - s * axis.x;
        let m22 = c + temp.z * axis.z;
        
        return .init(.init(m00, m10, m20, 0),
                     .init(m01, m11, m21, 0),
                     .init(m02, m12, m22, 0),
                     .init(0, 0, 0, 1))
    }
}
