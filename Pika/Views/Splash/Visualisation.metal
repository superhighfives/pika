
// File for Metal kernel and shader functions
#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
//#import "ShaderTypes.h"

using namespace metal;

// macros
#define S(a,b,t) smoothstep(a,b,t)
#define sat(x) clamp(x, 0., 1.)

float f(float2 p, float time) {
  return sin(p.x + sin(p.y + (time + 20.) *0.1)) * sin(p.y * p.x * 0.1 + (time + 20.) * 0.2);
}

float2 field(float2 p, float time) {
  float2 ep = float2(.05, 0.);
  float2 rz = float2(0);
  for( int i=0; i < 7; i++ )
  {
    float t0 = f(p, time);
    float t1 = f(p + ep.xy, time);
    float t2 = f(p + ep.yx, time);
    float2 g = float2((t1 - t0), (t2 - t0)) / ep.xx;
    float2 t = float2(-g.y, g.x);
    
    p += .9 * t + g * 0.3;
    rz = t;
  }
  
  return rz;
}

// remap in 2D
float2 within(float2 uv, float4 rect)
{
    return (uv-rect.xy)/(rect.zw-rect.xy);
}

float4 Main(float2 uv, float time)
{
    float2 p = uv.xy;
    p *= 6;
  
    float3 foreground = float3(143, 15, 208) / 255.0;
    float3 background = float3(188, 42, 97) / 255.0;
  
    float2 fld = field(p, time);
    float3 pass = sin(float3(mix(foreground, background, (p.x - 5.0) * .5)) + (fld.x - fld.y));
    float3 col = mix(pass, mix(foreground, background, fld.x), 0.8) * 1.5;
     
    return float4(col, 1.0);
}

kernel void compute(texture2d<float,access::write> output [[texture(0)]],
                    constant float2 &input [[buffer(0)]],
                    uint2 gid [[thread_position_in_grid]])
{
    // get the width and height of the screen texture
    uint width = output.get_width();
    uint height = output.get_height();
    
    // set its resolution
    float2 iResolution = float2(width, height);
    
    // compute the texture coordinates with the y-coordinate flipped
    // because the origin of Shadertoy's and Metal's y-coordinates differ
    float2 uv = float2(gid.x,height - gid.y) / iResolution;
    uv -= 0.5;  // -0.5 <> 0.5
    uv.x *= iResolution.x/iResolution.y;
    
    // get time
    float time = input.x;
    
    float4 col = Main(uv, time);
    output.write(col, gid);
}
