Shader "URP_Samples/Outline"
{
	Properties
		{
			[MainTexture] _BaseMap("Texture", 2D) = "white" {}
			[MainColor]   _BaseColor("Color", Color) = (1, 1, 1, 1)
			_OutlineWidth ("Outline Width", Range(0,0.1)) = 0.01
			_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
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
			#pragma require geometry

			#pragma vertex vert
			#pragma geometry geom
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
				half _OutlineWidth;
				float4 _OutlineColor;
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
				float3 normalWS   : TEXCOORD1;
				float  fogCoord   : TEXCOORD2;
				float4 outline    : TEXCOORD3;
				float3 positionWS : TEXCOORD4;
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
				output.outline = float4(0, 0, 0, 0);

				VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
				output.normalWS = normalInput.normalWS;

				return output;
			}

			[maxvertexcount(6)]
			void geom(triangle Varyings input[3], inout TriangleStream<Varyings> outputStream)
			{
				[unroll(3)]
				for (int i = 0; i < 3; ++i) {
					outputStream.Append(input[i]);
				}

				outputStream.RestartStrip();

				[unroll(3)]
				for (int j = 2; j >= 0; --j) {
					input[j].positionCS = TransformWorldToHClip(input[j].positionWS += (_OutlineWidth)*input[j].normalWS);
					input[j].outline = float4(_OutlineColor.rgb, 1.0f);
					outputStream.Append(input[j]);
				}
			}

			half4 frag(Varyings input) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				half2 uv = input.uv;
				half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);

				half3 color = (input.outline.a <= 0.5) ? texColor.rgb * _BaseColor.rgb : input.outline.rgb;

				half alpha = texColor.a * _BaseColor.a;

				color = MixFog(color, input.fogCoord);

				return half4(color, alpha);
			}
			ENDHLSL
		}
	}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
