#include "common_vs_fxc.h"

// Our default vertex data input structure
struct VS_INPUT
{
	float4 vPos : POSITION;
	float4 vTexCoord : TEXCOORD0;
};

// Please note that storing the view projection matrix in the output structure is kind of cursed,
// but I don't have another method of calculating the right depth in a pixel shader.
//
// You could potentially pass the matrix in the $viewprojmat flag (which is probably more performant),
// however I'm pretty sure its not directly accessable via GLua and needs to be explicitly constructed
struct VS_OUTPUT
{
	float4 proj_pos : POSITION; // Screen space position
	float2 uv : TEXCOORD0;		// World space position
	float3 view_space_dir : TEXCOORD1;
};

// The code below runs for every vertex in the model
VS_OUTPUT main(VS_INPUT vert)
{
	// Model space -> World space calculation
	float3 world_pos;
	SkinPosition(0, vert.vPos, 0, 0, world_pos);

	// World space -> Screen space calculation
	float4 proj_pos = mul(float4(world_pos, 1), cViewProj);

	VS_OUTPUT output = (VS_OUTPUT)0;
	output.proj_pos = proj_pos;
	output.uv = vert.vTexCoord.xy;
	output.view_space_dir = mul(cViewProj, float4(vert.vPos.xy, 0.0, 1.0)).xyz;

	return output;
};