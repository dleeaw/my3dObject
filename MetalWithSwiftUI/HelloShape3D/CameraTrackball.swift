//
//  CameraTrackball.swift
//  MetalWithSwiftUI
//
//  Created by CurvSurf-SGKim on 6/25/25.
//

import simd

struct Camera: Equatable {
    
    var eye: simd_float3
    var at: simd_float3
    var up: simd_float3
    
    var fovy: Float
    var aspectRatio: Float
    var near: Float
    var far: Float
    
    var zoomFactor: Float = 1.0
    
    var dir: simd_float3 {
        normalize(at - eye)
    }
    
    var distance: Float {
        simd_distance(eye, at)
    }
    
    fileprivate var movingStep: simd_float2 {
        let t = tan(min(fovy, fovy * aspectRatio) * 0.5)
        let scale = simd_distance(eye, at) * t
        if aspectRatio > 1 {
            return .init(aspectRatio, 1) * scale
        } else {
            return .init(1 , 1 / aspectRatio) * scale
        }
    }
    
    var viewMatrix: simd_float4x4 {
        // LookAtRH
        let eye = mix(self.at, self.eye, t: self.zoomFactor)
        let f = normalize(at - eye)
        let s = normalize(cross(f, up))
        let u = cross(s, f)
        let t = -simd_float3(dot(s, eye), dot(u, eye), dot(-f, eye))
        
        return .init(.init(s.x, u.x, -f.x, 0),
                     .init(s.y, u.y, -f.y, 0),
                     .init(s.z, u.z, -f.z, 0),
                     .init(t, 1))
    }
    
    var projectionMatrix: simd_float4x4 {
        // PerspectiveLH_ZO
        
        let tanHalfFovy = tan(fovy * 0.5)
        
        let depth = far - near
        
        let m11 = 1.0 / tanHalfFovy
        let m00 = m11 / aspectRatio
        let m22 = -far / depth
        let m32 = Float(-1.0)
        let m23 = -(far * near) / depth
        
        return .init(.init(m00, 0, 0, 0),
                     .init(0, m11, 0, 0),
                     .init(0, 0, m22, m32),
                     .init(0, 0, m23, 0))
    }
}

@dynamicMemberLookup
final class Trackball {
    
    enum Mode: String, CaseIterable {
        case none = "None"
        case rotate = "Rotate"
        case roll = "Roll"
        case move = "Move"
        case zoom = "Zoom"
        
        static var allCasesWithoutNone: [Self] {
            [.rotate, .roll, .move, .zoom]
        }
    }
    
    private(set) var curr: Camera
    private(set) var prev: Camera
    private(set) var home: Camera
    
    private var mode: Mode = .none
    private var m0: simd_float2 = .zero
    
    init(camera: Camera) {
        self.curr = camera
        self.prev = camera
        self.home = camera
    }
    
    subscript<T>(dynamicMember keyPath: KeyPath<Camera, T>) -> T {
        self.curr[keyPath: keyPath]
    }
    
    func setHome() {
        self.prev = self.home
        self.curr = self.home
    }
    
    func mouse(at location: simd_float2, mode: Mode) {
        self.prev = self.curr
        self.m0 = location
        self.mode = mode
    }
    
    func motion(at location: simd_float2) {
        
        let d = location - self.m0
        
        guard simd_length_squared(d) > 0.01 else { return }
        
        switch self.mode {
        case .rotate:   rotate(d)
        case .roll:     roll(d)
        case .move:     move(d)
        case .zoom:     zoom(d)
        default: break
        }
    }
    
    func setViewport(width: Float, height: Float) {
        let aspectRatio = width / height
        self.curr.aspectRatio = aspectRatio
        self.prev.aspectRatio = aspectRatio
        self.home.aspectRatio = aspectRatio
    }
    
    static func == (lhs: Trackball, rhs: Trackball) -> Bool {
        return lhs.curr == rhs.curr
            && lhs.prev == rhs.prev
            && lhs.home == rhs.home
            && lhs.mode == rhs.mode
            && lhs.m0 == rhs.m0
    }
    
    private func rotate(_ d: simd_float2) {
        
        let eye = self.prev.eye
        let at = self.prev.at
        let up = self.prev.up
        
        let rotation = simd_float3x3(
            simd_make_float3(self.prev.viewMatrix.columns.0),
            simd_make_float3(self.prev.viewMatrix.columns.1),
            simd_make_float3(self.prev.viewMatrix.columns.2)
        )
        
        let angle = -simd_length(d) * .pi * 0.5
        let c = simd_float3(-d.y, d.x, 0)
        let axis = normalize(c) * rotation // apply inverse transform by multiplying the matrix from the right hand side.
        
        let rotate = simd_float4x4.rotate(angle: angle, along: axis)
        
        self.curr.eye = simd_make_float3(rotate * simd_float4(eye - at, 0)) + at
        self.curr.up = simd_make_float3(rotate * simd_float4(up, 0))
    }
    
    private func roll(_ d: simd_float2) {
        
        let m0 = self.m0
        let dir = self.prev.dir
        let up = self.prev.up
        
        let p0 = normalize(.init(m0, 0.0))
        let p1 = normalize(.init(m0 + d, 0.0))
        
        let angle = orientedAngle(p0, p1, .init(0, 0, 1))
        
        let rotate = simd_float4x4.rotate(angle: angle, along: dir)
        
        self.curr.up = simd_make_float3(rotate * simd_float4(up, 0))
    }
    
    private func move(_ d: simd_float2) {
        
        let eye = self.prev.eye
        let at = self.prev.at
        let up = self.prev.up
        let dir = self.prev.dir
        let movingStep = self.prev.movingStep
        
        let movingDistance = d * movingStep
        
        let hori = normalize(cross(dir, up))
        let vert = normalize(cross(hori, dir))
        
        let p = hori * movingDistance.x + vert * movingDistance.y
        self.curr.eye = eye - p
        self.curr.at = at - p
    }
    
    private func zoom(_ d: simd_float2) {
        
        let zoomFactor = self.prev.zoomFactor
        
        let t = pow(1.2, -d.y)
        
        self.curr.zoomFactor = zoomFactor * t
    }
}
