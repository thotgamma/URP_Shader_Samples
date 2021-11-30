Shader "URP_Samples/Toon"
{
	Properties
		{
			[MainTexture] _BaseMap("Texture", 2D) = "white" {}
			[MainColor]   _BaseColor("Color", Color) = (1, 1, 1, 1)
			_ShadeColor("ShadeColor", Color) = (0.8, 0.8, 0.8, 1)
			_ShadeToony("Shade Toony", Range(0.0, 1.0)) = 0.9
			_ShadeShift("Shade Shift", Range(-1.0, 1.0)) = 0
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
				half4 _ShadeColor;
				half _ShadeToony;
				half _ShadeShift;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS       : POSITION;
				float3 normalOS         : NORMAL;
				float4 tangentOS        : TANGENT;
				float2 uv               : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float2 uv         : TEXCOORD0;
				float3 positionWS : TEXCOORD1;
				float3 normalWS   : TEXCOORD2;
				float  fogCoord   : TEXCOORD3;
				float4 positionCS : SV_POSITION;

				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			Varyings vert(Attributes input)
			{
				Varyings output = (Varyings)0;

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
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
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);

				half2 uv = input.uv;
				half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
				half3 color = texColor.rgb * _BaseColor.rgb;
				half alpha = texColor.a * _BaseColor.a;

				Light mainLight = GetMainLight(shadowCoord);

				float NoL = dot(input.normalWS, mainLight.direction);
				half thresholdL = (_ShadeShift - (1-_ShadeToony))/2 + 0.5;
				half thresholdH = (_ShadeShift + (1-_ShadeToony))/2 + 0.5;
				color *= lerp(_ShadeColor.rgb, half3(1, 1, 1), smoothstep(thresholdL, thresholdH, NoL));

				color = MixFog(color, input.fogCoord);

				return half4(color, alpha);
			}
			ENDHLSL
		}
	}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
