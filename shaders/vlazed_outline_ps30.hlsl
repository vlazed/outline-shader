// Defines cEyePos
#include "common_ps_fxc.h"

sampler BASETEXTURE : register(s0);
sampler DEPTHTEXTURE : register(s1);
sampler NORMALTEXTURE : register(s2);

float4 DEPTHSCALE : register(c0);      // Holds material flags $c0_x, $c0_y, $c0_z, and $c0_w
float4 NORMALTHRESHOLD : register(c1); // Holds material flags $c1_x, $c1_y, $c1_z, and $c1_w

float4 TEXEL : register(c2);       // Holds material flags $c2_x, $c2_y, $c2_z, and $c2_w
float4 COLOR_INPUT : register(c3); // Holds material flags $c3_x, $c3_y, $c3_z, and $c3_w

float3 decodeNormal(float2 f)
{
    f = f * 2.0 - 1.0;

    // https://twitter.com/Stubbesaurus/status/937994790553227264
    float3 n = float3(f.x, f.y, 1.0 - abs(f.x) - abs(f.y));
    float t = saturate(-n.z);
    n.xy += n.xy >= 0.0 ? -t : t;
    return normalize(n);
}

// Combines the top and bottom colors using normal blending.
// https://en.wikipedia.org/wiki/Blend_modes#Normal_blend_mode
// This performs the same operation as Blend SrcAlpha OneMinusSrcAlpha.
float4 alphaBlend(float4 top, float4 bottom)
{
    float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
    float alpha = top.a + bottom.a * (1 - top.a);

    return float4(color, alpha);
}

// Edge detection kernel that works by taking the sum of the squares of the differences between diagonally adjacent pixels (Roberts Cross).
float robertsCross3(float3 samples[4])
{
    float3 difference_1 = samples[1] - samples[2];
    float3 difference_2 = samples[0] - samples[3];
    return sqrt(dot(difference_1, difference_1) + dot(difference_2, difference_2));
}

// The same kernel logic as above, but for a single-value instead of a vector3.
float robertsCross(float samples[4])
{
    float difference_1 = samples[1] - samples[2];
    float difference_2 = samples[0] - samples[3];
    return sqrt(difference_1 * difference_1 + difference_2 * difference_2);
}

// Helper function to sample scene luminance.
float sampleSceneLuminance(float2 uv)
{
    float3 color = tex2D(BASETEXTURE, uv).rgb;
    return color.r * 0.3 + color.g * 0.59 + color.b * 0.11;
}

float3 sampleWorldNormals(float2 uv)
{
    float4 normalTangent = tex2D(NORMALTEXTURE, uv);
    float3 worldNormal = decodeNormal(normalTangent.xy);

    return worldNormal;
}

float sampleDepth(float2 uv)
{
    float depth = tex2D(DEPTHTEXTURE, uv).a;
    float z = depth * 2.0 - 1.0; // back to NDC 

    // return depth;
   return (2.0) / ((1 - z) * 4000 + 0.01);
}

struct PS_INPUT
{
    float2 uv : TEXCOORD0;             // Position on triangle
    float3 view_space_dir : TEXCOORD1; // Projection matrix (used for calculating depth)
};

float4 main(PS_INPUT frag) : COLOR
{
    float _DepthThreshold = DEPTHSCALE.x;
    float _Scale = DEPTHSCALE.y;
    float _DepthNormalThreshold = DEPTHSCALE.z;
    float _DepthNormalThresholdScale = DEPTHSCALE.w;
    float _NormalThreshold = NORMALTHRESHOLD.x;
    float _LuminanceThreshold = TEXEL.z;
    float _Debug = TEXEL.w;

    float halfScaleFloor = floor(_Scale * 0.5);
    float halfScaleCeil = ceil(_Scale * 0.5);

    float2 texel_size = TEXEL.xy;

    float2 uvs[4];
    uvs[0] = frag.uv + texel_size * float2(halfScaleFloor, halfScaleCeil) * float2(-1, 1);   // top left
    uvs[1] = frag.uv + texel_size * float2(halfScaleCeil, halfScaleCeil) * float2(1, 1);     // top right
    uvs[2] = frag.uv + texel_size * float2(halfScaleFloor, halfScaleFloor) * float2(-1, -1); // bottom left
    uvs[3] = frag.uv + texel_size * float2(halfScaleCeil, halfScaleFloor) * float2(1, -1);   // bottom right

    float3 normalSamples[4];
    float depthSamples[4], luminanceSamples[4];

    depthSamples[0] = sampleDepth(uvs[0]);
    normalSamples[0] = sampleWorldNormals(uvs[0]);
    luminanceSamples[0] = sampleSceneLuminance(uvs[0]);
    depthSamples[1] = sampleDepth(uvs[1]);
    normalSamples[1] = sampleWorldNormals(uvs[1]);
    luminanceSamples[1] = sampleSceneLuminance(uvs[1]);
    depthSamples[2] = sampleDepth(uvs[2]);
    normalSamples[2] = sampleWorldNormals(uvs[2]);
    luminanceSamples[2] = sampleSceneLuminance(uvs[2]);
    depthSamples[3] = sampleDepth(uvs[3]);
    normalSamples[3] = sampleWorldNormals(uvs[3]);
    luminanceSamples[3] = sampleSceneLuminance(uvs[3]);

    // Apply edge detection kernel on the samples to compute edges.
    float edgeDepth = robertsCross(depthSamples) * 100;
    float edgeNormal = robertsCross3(normalSamples);
    float edgeLuminance = robertsCross(luminanceSamples);

    // Transform the view normal from the 0...1 range to the -1...1 range.
    float3 viewNormal = normalSamples[2] * 2 - 1;
    float NdotV = 1 - dot(viewNormal, -frag.view_space_dir);

    // Return a value in the 0...1 range depending on where NdotV lies
    // between _DepthNormalThreshold and 1.
    float normalThreshold01 = saturate((NdotV - _DepthNormalThreshold) / (1 - _DepthNormalThreshold));
    // Scale the threshold, and add 1 so that it is in the range of 1..._NormalThresholdScale + 1.
    float normalThreshold = normalThreshold01 * _DepthNormalThresholdScale + 1;

    // Modulate the threshold by the existing depth value;
    // pixels further from the screen will require smaller differences
    // to draw an edge.
    float depthThreshold = _DepthThreshold * depthSamples[2] * normalThreshold;

    // Threshold the edges (discontinuity must be above certain threshold to be counted as an edge). The sensitivities are hardcoded here.
    edgeDepth = edgeDepth > depthThreshold ? 1 : 0;

    edgeNormal = edgeNormal > _NormalThreshold ? 1 : 0;

    edgeLuminance = edgeLuminance > _LuminanceThreshold ? 1 : 0;

    float depth = sampleDepth(frag.uv);
    // Combine the edges from depth/normals/luminance using the max operator.
    float edge = max(edgeDepth, max(edgeNormal, edgeLuminance));
    // edge *= depth;

    // If we're in debug mode, draw the inverted colors of the outline, rather than the framebuffer
    float4 color = _Debug == 0 ? tex2D(BASETEXTURE, frag.uv) : (float4(1 - COLOR_INPUT.rgb, 1));
    float4 edgeColor = float4(COLOR_INPUT.rgb, COLOR_INPUT.a * edge);

    return alphaBlend(edgeColor, color);
}