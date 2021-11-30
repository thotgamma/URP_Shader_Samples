Shader "URP_Samples/Diffuse"
{
	Properties
		{
			[MainTexture] _BaseMap("Texture", 2D) = "white" {}
			[MainColor]   _BaseColor("Color", Color) = (1, 1, 1, 1)
		}
	SubShader
	{
		Tags {"RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" "ShaderModel"="4.5"}
		LOD 100

		Blend One Zero
		ZWrite On
		Cull Back

		Pass
		{
			Name "FowerdLit"
			Tags{"LightMode" = "UniversalForward"}

			HLSLPROGRAM
			#pragma exclude_renderers gles gles3 glcore
			#pragma target 4.5

			#pragma vertex vert
			#pragma fragment frag

			// -------------------------------------
			// Unity defined keywords
			#pragma multi_compile_fog

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			TEXTURE2D(_BaseMap);
			SAMPLER(sampler_BaseMap);

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseMap_ST;
				half4 _BaseColor;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS       : POSITION;
				float3 normalOS         : NORMAL;
				float4 tangentOS        : TANGENT;
				float2 uv               : TEXCOORD0;
			};

			struct Varyings
			{
				float2 uv         : TEXCOORD0;
				float3 positionWS : TEXCOORD1;
				float3 normalWS   : TEXCOORD2;
				float  fogCoord   : TEXCOORD3;
				float4 positionCS : SV_POSITION;

				UNITY_VERTEX_OUTPUT_STEREO
			};

			Varyings vert(Attributes input)
			{
				Varyings output = (Varyings)0;

				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				output.positionCS = vertexInput.positionCS;
				output.positionWS = vertexInput.positionWS;
				output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
				output.fogCoord = ComputeFogFactor(vertexInput.positionCS.z);

				VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
				output.normalWS = normalInput.normalWS;

				return output;
			}

			half4 frag(Varyings input) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);

				half2 uv = input.uv;
				half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
				half3 baseColor = texColor.rgb * _BaseColor.rgb;
				half alpha = texColor.a * _BaseColor.a;

				Light mainLight = GetMainLight(shadowCoord);

				float NoL = dot(input.normalWS, mainLight.direction);
				half3 color = baseColor * mainLight.color * mainLight.distanceAttenuation * NoL;

				uint pixelLightCount = GetAdditionalLightsCount();
				for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex) {
					Light light = GetAdditionalLight(lightIndex, input.positionWS);
					half add_NoL = saturate(dot(input.normalWS, light.direction));

					color +=  baseColor * light.color * light.distanceAttenuation * add_NoL;
				}

				color = MixFog(color, input.fogCoord);

				return half4(color, alpha);
			}
			ENDHLSL
		}
	}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
