Shader "URP_Samples/Unlit"
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
				float3 positionWS : TEXCOORD0;
				float3 normalWS   : TEXCOORD1;
				float  fogCoord   : TEXCOORD2;
				float4 positionCS : SV_POSITION;

				UNITY_VERTEX_OUTPUT_STEREO
			};

			Varyings vert(Attributes input)
			{
				Varyings output = (Varyings)0;

				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				output.positionWS = vertexInput.positionWS;
				output.positionCS = vertexInput.positionCS;

				VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
				output.normalWS = normalInput.normalWS;

				return output;
			}

			half4 frag(Varyings input) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				float3 tripUV = input.positionWS;
				float3 tripFactor = normalize(abs(input.normalWS));

				half4 albedoX = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, tripUV.zy * float2(sign(input.normalWS.x), 1.0));
				half4 albedoY = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, tripUV.xz * float2(sign(input.normalWS.y), 1.0));
				half4 albedoZ = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, tripUV.xy * float2(-sign(input.normalWS.z), 1.0));

				half4 color = (albedoX * tripFactor.x + albedoY * tripFactor.y + albedoZ * tripFactor.z) * _BaseColor;

				color.rgb = MixFog(color.rgb, input.fogCoord);

				return color;
			}
			ENDHLSL
		}
	}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
