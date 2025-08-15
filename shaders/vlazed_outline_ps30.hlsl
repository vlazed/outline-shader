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

float2 decodeDiamond(float p)
{
    float2 v;

    // Remap p to the appropriate segment on the diamond
    float p_sign = sign(p - 0.5f);
    v.x = -p_sign * 4.f * p + 1.f + p_sign * 2.f;
    v.y = p_sign * (1.f - abs(v.x));

    // Normalization extends the point on the diamond back to the unit circle
    return normalize(v);
}

float3 decodeTangent(float3 normal, float diamond_tangent)
{
    // As in the encode step, find our canonical tangent basis span(t1, t2)
    float3 t1;
    if (abs(normal.y) > abs(normal.z))
    {
        t1 = float3(normal.y, -normal.x, 0.f);
    }
    else
    {
        t1 = float3(normal.z, 0.f, -normal.x);
    }
    t1 = normalize(t1);

    float3 t2 = cross(t1, normal);

    // Recover the coordinates used with t1 and t2
    float2 packed_tangent = decodeDiamond(diamond_tangent);

    return packed_tangent.x * t1 + packed_tangent.y * t2;
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

float3 getWorldNormal(float2 uv)
{
    float4 normalTangent = tex2D(NORMALTEXTURE, uv);
    float3 worldNormal = decodeNormal(normalTangent.xy);

    return worldNormal;
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

    float halfScaleFloor = floor(_Scale * 0.5);
    float halfScaleCeil = ceil(_Scale * 0.5);

    // Sample the pixels in an X shape, roughly centered around i.texcoord.
    // As the _CameraDepthTexture and _CameraNormalsTexture default samplers
    // use point filtering, we use the above variables to ensure we offset
    // exactly one pixel at a time.
    float2 bottomLeftUV = frag.uv - float2(TEXEL.x, TEXEL.y) * halfScaleFloor;
    float2 topRightUV = frag.uv + float2(TEXEL.x, TEXEL.y) * halfScaleCeil;
    float2 bottomRightUV = frag.uv + float2(TEXEL.x * halfScaleCeil, -TEXEL.y * halfScaleFloor);
    float2 topLeftUV = frag.uv + float2(-TEXEL.x * halfScaleFloor, TEXEL.y * halfScaleCeil);

    float3 normal0 = getWorldNormal(bottomLeftUV).rgb;
    float3 normal1 = getWorldNormal(topRightUV).rgb;
    float3 normal2 = getWorldNormal(bottomRightUV).rgb;
    float3 normal3 = getWorldNormal(topLeftUV).rgb;

    float depth0 = tex2D(DEPTHTEXTURE, bottomLeftUV).r;
    float depth1 = tex2D(DEPTHTEXTURE, topRightUV).r;
    float depth2 = tex2D(DEPTHTEXTURE, bottomRightUV).r;
    float depth3 = tex2D(DEPTHTEXTURE, topLeftUV).r;

    // Transform the view normal from the 0...1 range to the -1...1 range.
    float3 viewNormal = normal0 * 2 - 1;
    float NdotV = 1 - dot(viewNormal, -frag.view_space_dir);

    // Return a value in the 0...1 range depending on where NdotV lies
    // between _DepthNormalThreshold and 1.
    float normalThreshold01 = saturate((NdotV - _DepthNormalThreshold) / (1 - _DepthNormalThreshold));
    // Scale the threshold, and add 1 so that it is in the range of 1..._NormalThresholdScale + 1.
    float normalThreshold = normalThreshold01 * _DepthNormalThresholdScale + 1;

    // Modulate the threshold by the existing depth value;
    // pixels further from the screen will require smaller differences
    // to draw an edge.
    float depthThreshold = _DepthThreshold * depth0 * normalThreshold;

    float depthFiniteDifference0 = depth1 - depth0;
    float depthFiniteDifference1 = depth3 - depth2;
    // edgeDepth is calculated using the Roberts cross operator.
    // The same operation is applied to the normal below.
    // https://en.wikipedia.org/wiki/Roberts_cross
    float edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;
    edgeDepth = edgeDepth > depthThreshold ? 1 : 0;

    float3 normalFiniteDifference0 = normal1 - normal0;
    float3 normalFiniteDifference1 = normal3 - normal2;
    // Dot the finite differences with themselves to transform the
    // three-dimensional values to scalars.
    float edgeNormal = sqrt(dot(normalFiniteDifference0, normalFiniteDifference0) + dot(normalFiniteDifference1, normalFiniteDifference1));
    edgeNormal = edgeNormal > _NormalThreshold ? 1 : 0;

    float edge = max(edgeDepth, edgeNormal);

    float4 color = tex2D(BASETEXTURE, frag.uv);
    float4 edgeColor = float4(COLOR_INPUT.rgb, COLOR_INPUT.a * edge);

    return alphaBlend(edgeColor, color);
}