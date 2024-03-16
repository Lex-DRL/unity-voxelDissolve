#ifndef DRL_SHADER_VoxelDissolve_LIB_INCLUDED
#define DRL_SHADER_VoxelDissolve_LIB_INCLUDED

#ifdef __RESHARPER__
#endif

// #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// Might define an override-macro for half:
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
// it ^ also includes a macro for float/half epsilon values


// ========================================================
// Utility functions

// Returns true if the vector has zero length and therefore it's replaced with fallback
bool SafeNormalize_withFallback_half(inout half3 V, half3 fallbackVector, out half vectorLength) {
	half lenSquared = dot(V, V);
	if(lenSquared < HALF_MIN) {
		vectorLength = 0.0h;
		V = fallbackVector;
		return true;
	}
	half lengthScaler = rsqrt(lenSquared);
	vectorLength = 1.0h / lengthScaler;
	V *= lengthScaler;
	return false;
}
bool SafeNormalize_withFallback_float(inout float3 V, float3 fallbackVector, out float vectorLength) {
	float lenSquared = dot(V, V);
	if(lenSquared < FLT_MIN) {
		vectorLength = 0.0;
		V = fallbackVector;
		return true;
	}
	float lengthScaler = rsqrt(lenSquared);
	vectorLength = 1.0 / lengthScaler;
	V *= lengthScaler;
	return false;
}

half3 SnapToCell_half(half3 inV, bool doRound) {
	half3 signs = sign(inV);
	inV *= signs;
	inV = doRound ? floor(inV + 0.5h) : ceil(inV);
	return inV * signs;
}
float3 SnapToCell_float(float3 inV, bool doRound) {
	float3 signs = sign(inV);
	inV *= signs;
	inV = doRound ? floor(inV + 0.5) : ceil(inV);
	return inV * signs;
}

// ========================================================
// High-level functions (ShaderGraph)

void VoxelDissolve_half(
	float3 vertexPos, float3 originPos, half3 cellSize, half radius, bool doRound,
	out float3 outPos, out half modifiedMask
) {
	half3 relDir = vertexPos - originPos; // relative vertex offset from origin; for now, non-normalized
	radius = max(0.0h, radius);

	half posDistance;
	// Split relDir into normalized direction and it's length:
	bool isZero = SafeNormalize_withFallback_half(relDir, half3(0.0h, 1.0h, 0.0h), posDistance);

	// Keep the position intact if it's within the radius
	if(isZero || posDistance < radius) {
		outPos = vertexPos;
		modifiedMask = 0.0h;
		return;
	}

	// Now, turn relDir into new position, yet still relative from origin:
	relDir *= radius;
	// ... and snap it to the highest cell boundary within radius:
	relDir = SnapToCell_half(relDir / cellSize, doRound) * cellSize;
	
	// Finally, restore object-space vertex position:
	outPos = originPos + relDir;
	modifiedMask = 1.0h;
}

void VoxelDissolve_float(
	float3 vertexPos, float3 originPos, float3 cellSize, float radius, bool doRound,
	out float3 outPos, out float modifiedMask
) {
	float3 relDir = vertexPos - originPos;
	radius = max(0.0, radius);
	float posDistance;
	bool isZero = SafeNormalize_withFallback_float(relDir, float3(0.0h, 1.0h, 0.0h), posDistance);
	if(isZero || posDistance < radius) {
		outPos = vertexPos;
		modifiedMask = 0.0h;
		return;
	}

	relDir *= radius;
	relDir = SnapToCell_float(relDir / cellSize, doRound) * cellSize;
	outPos = originPos + relDir;
	modifiedMask = 1.0h;
}

#endif
