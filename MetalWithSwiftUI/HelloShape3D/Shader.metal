//
//  Shader.metal
//  MetalWithSwiftUI
//
//  Created by CurvSurf-SGKim on 6/25/25.
//

#include <metal_stdlib>

using namespace metal;

struct Uniform {
    float4x4 view_matrix        [[ id(0) ]];
    float4x4 projection_matrix  [[ id(1) ]];
    float3 camera_position      [[ id(2) ]];
    float3 light_position       [[ id(3) ]];
    float3 light_color          [[ id(4) ]];
    float light_intensity       [[ id(5) ]];
    float ambient_intensity     [[ id(6) ]];
    float specular_power        [[ id(7) ]];
};

namespace hello_shading_3d {
    
    struct Vertex {
        float3 position [[ attribute(0) ]];
        float3 normal   [[ attribute(1) ]];
        float2 texcoord [[ attribute(2) ]];
    };
    
    struct VertexOut {
        float4 position [[ position ]];
        float3 world_position;
        float3 world_normal;
        float2 texcoord;
    };
    
    vertex VertexOut vertex_function(Vertex in [[ stage_in ]],
                                     constant float4x4 &model_matrix [[ buffer(1) ]],
                                     constant Uniform &uniform [[ buffer(2) ]]) {
        
        auto world_position = model_matrix * float4(in.position, 1);
        auto view_position = uniform.view_matrix * world_position;
        auto position = uniform.projection_matrix * view_position;
        
        auto world_normal = normalize((model_matrix * float4(in.normal, 0)).xyz);
        
        return {
            .position = position,
            .world_position = world_position.xyz,
            .world_normal = world_normal,
            .texcoord = in.texcoord
        };
    }
    
    fragment float4 fragment_function(VertexOut in [[ stage_in ]],
                                      constant Uniform &uniform [[ buffer(1) ]],
                                      texture2d<float> texture [[ texture(0) ]]) {
        
        constexpr sampler sampler(mag_filter::linear,
                                  min_filter::linear);
        
        float3 N = normalize(in.world_normal);
        float3 to_light = uniform.light_position - in.world_position;
        float light_distance = length(to_light);
        float3 L = normalize(to_light);
        
        float3 V = normalize(uniform.camera_position - in.world_position);
        float3 H = normalize(L + V);
        
        float3 NdotL = max(dot(N, L), 0.0);
        
        float attenuation = uniform.light_intensity / (light_distance * light_distance);
        
        float3 ambient = uniform.ambient_intensity * uniform.light_color;
        float3 diffuse = NdotL * uniform.light_intensity * uniform.light_color * attenuation;
        float NdotH = max(dot(N, H), 0.0);
        float3 specular = pow(NdotH, uniform.specular_power) * uniform.light_intensity * uniform.light_color * attenuation;
        
        float4 texture_color = texture.sample(sampler, in.texcoord);
        
        float3 color = texture_color.xyz * (ambient + diffuse) + specular;
        return float4(color, 1);
    }
};
