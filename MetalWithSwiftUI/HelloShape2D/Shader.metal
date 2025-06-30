//
//  Shader.metal
//  MetalWithSwiftUI
//
//  Created by CurvSurf-SGKim on 6/23/25.
//

#include <metal_stdlib>

using namespace metal;

namespace hello_triangle {
    
    struct Vertex {
        float2 position [[ attribute(0) ]];
        float3 color    [[ attribute(1) ]];
    };
    
    struct VertexOut {
        float4 position [[ position ]];
        float3 color;
    };
    
    vertex VertexOut vertex_function(Vertex in [[ stage_in ]],
                                     constant float4x4 &transform [[ buffer(1) ]]) {
        
        VertexOut out;
        out.position = transform * float4(in.position, 0, 1);
        out.color = in.color;
        
        return out;
    }
    
    fragment float4 fragment_function(VertexOut in [[ stage_in ]],
                                      constant float &brightness [[ buffer(1) ]]) {
        auto final_color = in.color * brightness;
        return float4(final_color, 1);
    }
};

namespace hello_square {
    
    struct Vertex {
        float2 position [[ attribute(0) ]];
        float2 texcoord [[ attribute(1) ]];
    };
    
    struct VertexOut {
        float4 position [[ position ]];
        float2 texcoord;
    };
    
    vertex VertexOut vertex_function(Vertex in [[ stage_in ]],
                                     constant float4x4 &transform [[ buffer(1) ]]) {
        
        return {
            .position = transform * float4(in.position, 0, 1),
            .texcoord = in.texcoord
        };
    }
    
    // reference: https://www.shadertoy.com/view/ll2GD3
    float3 pal(float t, float3 a, float3 b, float3 c, float3 d) {
        return a + b * cos(6.28318 * (c * t + d));
    }
    
    constant constexpr auto v0 = float3(0.5, 0.5, 0.5);
    constant constexpr auto v1 = float3(1.0, 1.0, 1.0);
    constant constexpr auto v2 = float3(0.0, 0.33, 0.67);
    constant constexpr auto v3 = float3(0.0, 0.1, 0.2);
    constant constexpr auto v4 = float3(0.3, 0.2, 0.2);
    constant constexpr auto v5 = float3(1.0, 1.0, 0.5);
    constant constexpr auto v6 = float3(0.8, 0.9, 0.3);
    constant constexpr auto v7 = float3(1.0, 0.7, 0.4);
    constant constexpr auto v8 = float3(0.0, 0.15, 0.2);
    constant constexpr auto v9 = float3(2.0, 1.0, 0.0);
    constant constexpr auto v10 = float3(0.5, 0.2, 0.25);
    constant constexpr auto v11 = float3(0.8, 0.5, 0.4);
    constant constexpr auto v12 = float3(0.2, 0.4, 0.2);
    constant constexpr auto v13 = float3(2.0, 1.0, 1.0);
    constant constexpr auto v14 = float3(0.0, 0.25, 0.25);
    
    fragment float4 fragment_function(VertexOut in [[ stage_in ]],
                                      constant float& brightness [[ buffer(1) ]],
                                      constant float& time [[ buffer(2) ]]) {
        auto p = in.texcoord;
        p.x += 0.01 * time;
        
        float3             col = pal(p.x,  v0,  v0,  v1,  v2);
        if (p.y>(1.0/7.0)) col = pal(p.x,  v0,  v0,  v1,  v3);
        if (p.y>(2.0/7.0)) col = pal(p.x,  v0,  v0,  v1,  v4);
        if (p.y>(3.0/7.0)) col = pal(p.x,  v0,  v0,  v5,  v6);
        if (p.y>(4.0/7.0)) col = pal(p.x,  v0,  v0,  v7,  v8);
        if (p.y>(5.0/7.0)) col = pal(p.x,  v0,  v0,  v9, v10);
        if (p.y>(6.0/7.0)) col = pal(p.x, v11, v12, v13, v14);
        
        // band
        float f = fract(p.y * 7.0);
        
        // borders
        col *= smoothstep(0.49, 0.47, abs(f - 0.5));
        
        // shadowing
        col *= 0.5 + 0.5 * sqrt(4.0 * f * (1.0 - f));
        
        return float4(col, 1);
    }
};

namespace hello_circle {
    
    struct Vertex {
        float2 position [[ attribute(0) ]];
    };
    
    struct VertexOut {
        float4 position [[ position ]];
        float2 frag_coord;
    };
    
    vertex VertexOut vertex_function(Vertex in [[ stage_in ]],
                                     constant float4x4 &transform [[ buffer(1) ]],
                                     constant float2 &resolution [[ buffer(2) ]]) {
        auto npos = transform * float4(in.position, 0, 1);
        auto frag_coord = (npos.xy * float2(1, -1) - 1) * 0.5 * resolution;
        return {
            .position = npos,
            .frag_coord = frag_coord
        };
    }
    
    // reference: https://www.shadertoy.com/view/dstSWM
    constant constexpr float MATH_PI = 3.14159265359;
    constant constexpr float CIRCLE_COLUMNS = 16.0;
    constant constexpr float TIME_SCALE = 0.08;

    fragment float4 fragment_function(VertexOut in [[ stage_in ]],
                                      constant float &brightness [[ buffer(1) ]],
                                      constant float &time [[ buffer(2) ]],
                                      constant float2 &resolution [[ buffer(3) ]]) {
        // Normalized pixel coordinates (from 0 to 1)
        float2 uv = in.frag_coord / resolution;
        float circle_rows = CIRCLE_COLUMNS * resolution.y / resolution.x;
        float scaled_time = time * TIME_SCALE;
        
        float circle = -cos((uv.x - scaled_time) * MATH_PI * 2 * CIRCLE_COLUMNS)
                      * cos((uv.y + scaled_time) * MATH_PI * 2 * circle_rows);
        
        float step_circle = step(circle, -sin(time + uv.x - uv.y));
        
        float3 color1 = float3(0.07, 0.2, 0.48);
        float3 color2 = float3(0.2, 0.45, 0.78);
        
        return float4(mix(color1, color2, step_circle) * brightness, 1);
    }
};
