Shader "URP_Samples/Dither"
{
	Properties
		{
			[MainTexture] _BaseMap("Texture", 2D) = "white" {}
			[MainColor]   _BaseColor("Color", Color) = (1, 1, 1, 1)
			[NoScaleOffset] _DitherMap("DitherMap", 2D) = "white" {}
			_Opacity("Opacity", Range(0, 1)) = 1
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
			TEXTURE2D(_DitherMap);
			SAMPLER(sampler_DitherMap);

			CBUFFER_START(UnityPerMaterial)
				float4 _BaseMap_ST;
				half4 _BaseColor;
				half _Cutoff;
				half _Surface;
				float _Opacity;
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
				float4 positionCS : SV_POSITION;

				UNITY_VERTEX_OUTPUT_STEREO
			};

			Varyings vert(Attributes input)
			{
				Varyings output = (Varyings)0;

				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
				output.positionCS = vertexInput.positionCS;
				output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

				VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS);
				output.normalWS = normalInput.normalWS;

				return output;
			}

			half4 frag(Varyings input) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				float2 ditherUV = input.positionCS.xy / 4;
				float dither = SAMPLE_TEXTURE2D(_DitherMap, sampler_DitherMap, ditherUV).r;
				if (_Opacity - dither < 0) discard;

				half2 uv = input.uv;
				half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
				half3 color = texColor.rgb * _BaseColor.rgb;
				half alpha = texColor.a * _BaseColor.a;

				color = MixFog(color, input.fogCoord);

				return half4(color, alpha);
			}
			ENDHLSL
		}
	}

	FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
