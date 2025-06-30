//
//  HelloShape3DModel.swift
//  MetalWithSwiftUI
//
//  Created by CurvSurf-SGKim on 6/25/25.
//

import Metal
import MetalKit
import SwiftUI

@Observable
final class HelloShape3DModel {
    
    let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let renderer: HelloShading3DRenderer
    
    private let cube: HelloCube
    
    private var trackball: Trackball
    
    private var startTime: CFTimeInterval = CACurrentMediaTime()
    private var timeSinceStart: Float = 0.0
    
    var shapeType: Shape3DType = .cube
    
    init() {
        
        let device = MTLCreateSystemDefaultDevice()!
        let commandQueue = device.makeCommandQueue()!
        let library = device.makeDefaultLibrary()!
        
        // initialize your renderers object here
        let renderer = HelloShading3DRenderer(device, library)
        
        let cube = HelloCube(device)
        
        let camera = Camera(eye: .init(0, 0, 5), at: .zero, up: .init(0, 1, 0),
                            fovy: 2.0 * .pi / 3.0, aspectRatio: 1.0, near: 0.001, far: 10.0)
        let trackball = Trackball(camera: camera)
        
        self.device = device
        self.commandQueue = commandQueue
        
        // initialize your properties here
        self.renderer = renderer
        self.cube = cube
        self.trackball = trackball
        
        self.renderer.updateLightPosition(normalize(.init(1, 1, 1)) * sqrt(3))
        self.renderer.updateLightColor(.one)
        self.renderer.updateLightIntensity(1.0)
        self.renderer.updateAmbientIntensity(0.4)
        self.renderer.updateSpecularPower(0.3)
    }
    
    func onViewResized(_ view: MTKView, _ size: CGSize) {
        // update your camera here
        self.trackball.setViewport(width: Float(size.width), height: Float(size.height))
    }
    
    private func update(_ timeElapsed: Float) {
        // update your renderers here
        self.renderer.updateViewMatrix(trackball.viewMatrix)
        self.renderer.updateProjectionMatrix(trackball.projectionMatrix)
        self.renderer.updateCameraPosition(trackball.eye)
    }
    
    enum GestureEvent {
        case began
        case changed
        case ended
    }
    
    func onDragGesture(to location: simd_float2, _ event: GestureEvent) {
        switch event {
        case .began:    trackball.mouse(at: location, mode: .rotate)
        case .changed:  trackball.motion(at: location)
        case .ended:    trackball.mouse(at: location, mode: .none)
        }
    }
    
    func onRotateGesture(angle: Float, _ event: GestureEvent) {
        switch event {
        case .began:    trackball.mouse(at: .init(1, 0), mode: .roll)
        case .changed:  trackball.motion(at: .init(cos(angle), sin(angle)))
        case .ended:    trackball.mouse(at: .init(cos(angle), sin(angle)), mode: .roll)
        }
    }
    
    func onDraw(_ view: MTKView) {
        
        let currentTime = CACurrentMediaTime()
        let timeElapsed = Float(currentTime - startTime)
        timeSinceStart += timeElapsed
        update(timeElapsed)
        startTime = currentTime
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }
        
        // invoke draw calls with your renderers here
        let model = switch shapeType {
        case .cube: self.cube
        }
        self.renderer.draw(model, encoder)
        
        encoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
