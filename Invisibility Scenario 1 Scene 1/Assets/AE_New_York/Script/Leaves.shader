// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "AE/Leaves"
{
	Properties
	{
		_Emmisive_Power("Emmisive_Power", Range( 0 , 1)) = 0
		_WindScale("Wind Scale", Range( 0 , 1)) = 0.3622508
		_WindPower("Wind Power", Range( 0 , 0.5)) = 0.2506492
		_WindSpeed("Wind Speed", Range( 0 , 1)) = 0.2327153
		_Wind_Size("Wind_Size", Range( 0 , 1)) = 0.5
		_Power_Normal("Power_Normal", Range( 0 , 3)) = 0
		_AmbientOcclusion("AmbientOcclusion", Range( 0 , 3)) = 0.3504248
		_UltraDetailScale("UltraDetailScale", Range( 0 , 2048)) = 652.3411
		_Smoothness_Power("Smoothness_Power", Range( 0 , 3)) = 0
		[Toggle]_MixSmoothnesFromBase("MixSmoothnesFromBase", Float) = 1
		_Base_Color("Base_Color", 2D) = "white" {}
		_SubSurfColor("SubSurfColor", Color) = (0.5943396,0.4697596,0.372864,1)
		_Tint("Tint", Color) = (1,1,1,0)
		_Normal("Normal", 2D) = "bump" {}
		_Mask("Mask", 2D) = "white" {}
		_Noise("Noise", 2D) = "black" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "AlphaTest+0" "DisableBatching" = "LODFading" "IsEmissive" = "true"  }
		Cull Off
		AlphaToMask On
		ColorMask RGB
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityStandardUtils.cginc"
		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#define ASE_TEXTURE_PARAMS(textureName) textureName

		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldPos;
			float2 uv_texcoord;
			float3 worldNormal;
			INTERNAL_DATA
			float4 vertexColor : COLOR;
		};

		uniform sampler2D _Noise;
		uniform float _WindSpeed;
		uniform float _Wind_Size;
		uniform float _WindScale;
		uniform float _WindPower;
		uniform sampler2D _Mask;
		uniform float4 _Mask_ST;
		uniform float _Power_Normal;
		uniform sampler2D _Normal;
		uniform float4 _Normal_ST;
		uniform float4 _Tint;
		uniform sampler2D _Base_Color;
		uniform float4 _Base_Color_ST;
		uniform float _AmbientOcclusion;
		uniform float4 _SubSurfColor;
		uniform float _Emmisive_Power;
		uniform float _MixSmoothnesFromBase;
		uniform float _UltraDetailScale;
		uniform float _Smoothness_Power;


		inline float4 TriplanarSamplingSV( sampler2D topTexMap, float3 worldPos, float3 worldNormal, float falloff, float2 tiling, float3 normalScale, float3 index )
		{
			float3 projNormal = ( pow( abs( worldNormal ), falloff ) );
			projNormal /= ( projNormal.x + projNormal.y + projNormal.z ) + 0.00001;
			float3 nsign = sign( worldNormal );
			half4 xNorm; half4 yNorm; half4 zNorm;
			xNorm = ( tex2Dlod( ASE_TEXTURE_PARAMS( topTexMap ), float4( tiling * worldPos.zy * float2( nsign.x, 1.0 ), 0, 0 ) ) );
			yNorm = ( tex2Dlod( ASE_TEXTURE_PARAMS( topTexMap ), float4( tiling * worldPos.xz * float2( nsign.y, 1.0 ), 0, 0 ) ) );
			zNorm = ( tex2Dlod( ASE_TEXTURE_PARAMS( topTexMap ), float4( tiling * worldPos.xy * float2( -nsign.z, 1.0 ), 0, 0 ) ) );
			return xNorm * projNormal.x + yNorm * projNormal.y + zNorm * projNormal.z;
		}


		float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }

		float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }

		float snoise( float2 v )
		{
			const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
			float2 i = floor( v + dot( v, C.yy ) );
			float2 x0 = v - i + dot( i, C.xx );
			float2 i1;
			i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
			float4 x12 = x0.xyxy + C.xxzz;
			x12.xy -= i1;
			i = mod2D289( i );
			float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
			float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
			m = m * m;
			m = m * m;
			float3 x = 2.0 * frac( p * C.www ) - 1.0;
			float3 h = abs( x ) - 0.5;
			float3 ox = floor( x + 0.5 );
			float3 a0 = x - ox;
			m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
			float3 g;
			g.x = a0.x * x0.x + h.x * x0.y;
			g.yz = a0.yz * x12.xz + h.yz * x12.yw;
			return 130.0 * dot( m, g );
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float2 temp_cast_0 = (_WindSpeed).xx;
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float3 ase_worldNormal = UnityObjectToWorldNormal( v.normal );
			float4 triplanar26 = TriplanarSamplingSV( _Noise, ase_worldPos, ase_worldNormal, 1.0, (0.1 + (_Wind_Size - 0.0) * (3.0 - 0.1) / (1.0 - 0.0)), 1.0, 0 );
			float2 temp_cast_1 = (triplanar26.x).xx;
			float2 panner27 = ( 1.0 * _Time.y * temp_cast_0 + temp_cast_1);
			float2 uv_Mask = v.texcoord * _Mask_ST.xy + _Mask_ST.zw;
			float4 tex2DNode15 = tex2Dlod( _Mask, float4( uv_Mask, 0, 0.0) );
			v.vertex.xyz += ( ( tex2Dlod( _Noise, float4( ( panner27 * _WindScale ), 0, 0.0) ) * _WindPower ) * tex2DNode15.a ).rgb;
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float2 uv_Normal = i.uv_texcoord * _Normal_ST.xy + _Normal_ST.zw;
			float3 tex2DNode86 = UnpackScaleNormal( tex2D( _Normal, uv_Normal ), _Power_Normal );
			o.Normal = tex2DNode86;
			float2 uv_Base_Color = i.uv_texcoord * _Base_Color_ST.xy + _Base_Color_ST.zw;
			float4 tex2DNode89 = tex2D( _Base_Color, uv_Base_Color );
			float4 temp_output_82_0 = ( _Tint * tex2DNode89 );
			o.Albedo = temp_output_82_0.rgb;
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_vertexNormal = mul( unity_WorldToObject, float4( ase_worldNormal, 0 ) );
			float3 ase_worldPos = i.worldPos;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = Unity_SafeNormalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult60 = dot( ase_vertexNormal , ase_worldlightDir );
			float clampResult62 = clamp( dotResult60 , 0.0 , 1.0 );
			float temp_output_66_0 = pow( sqrt( clampResult62 ) , 1.0 );
			float lerpResult97 = lerp( 1.0 , i.vertexColor.r , _AmbientOcclusion);
			float clampResult94 = clamp( _SubSurfColor.a , 0.5 , 1.0 );
			float4 temp_output_95_0 = ( lerpResult97 * _SubSurfColor * ( tex2DNode89 * clampResult94 ) );
			float4 normalizeResult81 = normalize( temp_output_95_0 );
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float fresnelNdotV84 = dot( (WorldNormalVector( i , tex2DNode86 )), ase_worldViewDir );
			float fresnelNode84 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV84, 1.04 ) );
			float4 temp_output_79_0 = ( ( temp_output_66_0 * normalizeResult81 * fresnelNode84 ) * 0.41 * _SubSurfColor );
			o.Emission = ( ( ( ase_lightColor * temp_output_66_0 * temp_output_82_0 ) + temp_output_95_0 + temp_output_79_0 ) * _Emmisive_Power ).rgb;
			float2 temp_output_57_0 = ( i.uv_texcoord * _UltraDetailScale );
			float simplePerlin2D71 = snoise( ( temp_output_57_0 * 2.98 ) );
			float simplePerlin2D72 = snoise( temp_output_57_0 );
			float clampResult74 = clamp( (0.0 + (( simplePerlin2D71 * simplePerlin2D72 ) - -1.0) * (0.8437597 - 0.0) / (1.0 - -1.0)) , 0.6661261 , 1.0 );
			float4 temp_cast_2 = ((( _MixSmoothnesFromBase )?( ( ( tex2DNode89.g * 0.8437597 ) + clampResult74 ) ):( 0.8437597 ))).xxxx;
			float4 lerpResult77 = lerp( temp_cast_2 , ( (( _MixSmoothnesFromBase )?( ( ( tex2DNode89.g * 0.8437597 ) + clampResult74 ) ):( 0.8437597 )) * temp_output_79_0 ) , clampResult94);
			float clampResult76 = clamp( lerpResult77.r , 0.015 , 1.0 );
			float2 uv_Mask = i.uv_texcoord * _Mask_ST.xy + _Mask_ST.zw;
			float4 tex2DNode15 = tex2D( _Mask, uv_Mask );
			float lerpResult102 = lerp( clampResult76 , tex2DNode15.g , _Smoothness_Power);
			o.Smoothness = lerpResult102;
			float lerpResult109 = lerp( lerpResult97 , tex2DNode15.b , _AmbientOcclusion);
			o.Occlusion = ( 1.0 - lerpResult109 );
			o.Alpha = tex2DNode89.a;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows exclude_path:deferred vertex:vertexDataFunc 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			AlphaToMask Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				half4 color : COLOR0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.color = v.color;
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				surfIN.vertexColor = IN.color;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18000
20;12;1920;991;1461.839;770.6132;1.81811;True;False
Node;AmplifyShaderEditor.TextureCoordinatesNode;54;-5067.679,-1254.981;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;55;-5275.679,-921.9808;Float;False;Property;_UltraDetailScale;UltraDetailScale;8;0;Create;True;0;0;False;0;652.3411;0;0;2048;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;57;-4695.679,-1130.981;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;56;-4970.52,-1515.628;Float;False;Constant;_Float2;Float 2;14;0;Create;True;0;0;False;0;2.98;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;58;-3730.77,-1077.386;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;59;-3641.164,-819.3028;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.VertexColorNode;99;-1959.361,619.9745;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;88;-3469.481,468.6158;Float;False;Property;_SubSurfColor;SubSurfColor;12;0;Create;True;0;0;False;0;0.5943396,0.4697596,0.372864,1;0.1564125,0.3113208,0.05727126,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;70;-4599.928,-1495.369;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;71;-4326.111,-1508.852;Inherit;False;Simplex2D;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;60;-3419.725,-973.2789;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;89;-5143.93,-250.9651;Inherit;True;Property;_Base_Color;Base_Color;11;0;Create;True;0;0;False;0;-1;8c53ce4fa3ccbf2488d44ed772e59b97;8c53ce4fa3ccbf2488d44ed772e59b97;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;113;-3953.062,216.4988;Inherit;False;Property;_Power_Normal;Power_Normal;6;0;Create;True;0;0;False;0;0;0;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;72;-4306.352,-1327.89;Inherit;False;Simplex2D;False;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;94;-4408.24,295.5604;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.5;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;96;-1646.77,631.1315;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;98;-1755.942,325.6453;Float;False;Property;_AmbientOcclusion;AmbientOcclusion;7;0;Create;True;0;0;False;0;0.3504248;0.22;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;61;-4813.813,-622.0917;Float;False;Constant;_Smoothness;Smoothness;13;0;Create;True;0;0;False;0;0.8437597;0.6193905;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;62;-3179.606,-881.9898;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;86;-3610.102,65.96718;Inherit;True;Property;_Normal;Normal;14;0;Create;True;0;0;False;0;-1;ab3d463ad637645499dcdceee7f03099;ab3d463ad637645499dcdceee7f03099;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;93;-3962.548,-55.11485;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;97;-1383.295,454.6516;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;73;-3961.957,-1368.265;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;85;-3053.728,124.6013;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;95;-2798.968,-586.5844;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TFHCRemapNode;65;-4341.662,-952.6917;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SqrtOpNode;63;-2889.749,-897.2487;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;64;-4866.548,-841.2347;Float;False;Constant;_SmoothnesMin;SmoothnesMin;6;0;Create;True;0;0;False;0;0.6661261;0.6221998;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;74;-4093.121,-712.341;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;75;-4155.57,-432.5639;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;-1434.832,1524.589;Float;False;Property;_Wind_Size;Wind_Size;5;0;Create;True;0;0;False;0;0.5;0.743;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;66;-2634.175,-871.0628;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;84;-2613.014,131.3973;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1.04;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;81;-2461.854,-158.273;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;-2142.596,43.64542;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TexturePropertyNode;16;-1118.099,1130.62;Float;True;Property;_Noise;Noise;16;0;Create;True;0;0;False;0;None;26e819997ca443c449ab615eff7fae83;False;black;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.TFHCRemapNode;24;-1085.995,1786.528;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0.1;False;4;FLOAT;3;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;80;-2106.354,310.0883;Inherit;False;Constant;_Float3;Float 3;13;0;Create;True;0;0;False;0;0.41;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;90;-3809.042,-422.308;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;79;-1793.786,51.53897;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;25;-784.1006,1911.848;Float;False;Property;_WindSpeed;Wind Speed;4;0;Create;True;0;0;False;0;0.2327153;0.15;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ToggleSwitchNode;91;-2823.38,-272.808;Float;False;Property;_MixSmoothnesFromBase;MixSmoothnesFromBase;10;0;Create;True;0;0;False;0;1;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TriplanarNode;26;-963.0375,1562.312;Inherit;True;Spherical;World;False;Top Texture 1;_TopTexture1;white;0;None;Mid Texture 1;_MidTexture1;white;-1;None;Bot Texture 1;_BotTexture1;white;-1;None;Triplanar Sampler;False;10;0;SAMPLER2D;;False;5;FLOAT;1;False;1;SAMPLER2D;;False;6;FLOAT;0;False;2;SAMPLER2D;;False;7;FLOAT;0;False;9;FLOAT3;0,0,0;False;8;FLOAT;1;False;3;FLOAT;1;False;4;FLOAT;1;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PannerNode;27;-409.0768,1712.115;Inherit;False;3;0;FLOAT2;1,1;False;2;FLOAT2;0.3,0.3;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;78;-1485.186,60.40114;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;36;-506.3718,2021.44;Float;False;Property;_WindScale;Wind Scale;2;0;Create;True;0;0;False;0;0.3622508;0.392;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;100;-2180.961,-1366.243;Float;False;Property;_Tint;Tint;13;0;Create;True;0;0;False;0;1,1,1,0;0.6620684,0.8113207,0.7118191,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;82;-1787.921,-687.5289;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;77;-1246.029,50.2571;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;35;-138.4134,1896.03;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LightColorNode;67;-2647.521,-1166.764;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;69;-2319.234,-995.2896;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;28;-55.00644,1661.506;Inherit;True;Property;_TextureSample1;Texture Sample 1;6;0;Create;True;0;0;False;0;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;39;127.9309,1940.322;Float;False;Property;_WindPower;Wind Power;3;0;Create;True;0;0;False;0;0.2506492;0.181;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;15;-853.6616,555.1021;Inherit;True;Property;_Mask;Mask;15;0;Create;True;0;0;False;0;-1;b6838c4bcaff17144bd113496564acae;b6838c4bcaff17144bd113496564acae;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;68;-984.1448,49.50514;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.LerpOp;109;-260.9127,440.3779;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;103;-595.8417,287.4701;Inherit;False;Property;_Smoothness_Power;Smoothness_Power;9;0;Create;True;0;0;False;0;0;0.41;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;38;389.9534,1678.307;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;112;-819.0513,-157.323;Inherit;False;Property;_Emmisive_Power;Emmisive_Power;1;0;Create;True;0;0;False;0;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;87;-1494.413,-307.8394;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;76;-695.8752,43.41713;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.015;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;37;469.6121,1280.029;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;111;71.14991,-44.39376;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;110;103.8916,410.0589;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;102;-303.2519,14.87502;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;269.0389,-90.68015;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;AE/Leaves;False;False;False;False;False;False;False;False;False;False;False;False;False;LODFading;False;False;False;False;False;False;False;Off;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.67;True;True;0;False;Opaque;;AlphaTest;ForwardOnly;14;all;True;True;True;False;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;0;4;10;25;False;0.5;True;0;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;21;False;-1;1;False;-1;92;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;True;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;57;0;54;0
WireConnection;57;1;55;0
WireConnection;70;0;57;0
WireConnection;70;1;56;0
WireConnection;71;0;70;0
WireConnection;60;0;58;0
WireConnection;60;1;59;0
WireConnection;72;0;57;0
WireConnection;94;0;88;4
WireConnection;96;0;99;1
WireConnection;62;0;60;0
WireConnection;86;5;113;0
WireConnection;93;0;89;0
WireConnection;93;1;94;0
WireConnection;97;1;96;0
WireConnection;97;2;98;0
WireConnection;73;0;71;0
WireConnection;73;1;72;0
WireConnection;85;0;86;0
WireConnection;95;0;97;0
WireConnection;95;1;88;0
WireConnection;95;2;93;0
WireConnection;65;0;73;0
WireConnection;65;4;61;0
WireConnection;63;0;62;0
WireConnection;74;0;65;0
WireConnection;74;1;64;0
WireConnection;75;0;89;2
WireConnection;75;1;61;0
WireConnection;66;0;63;0
WireConnection;84;0;85;0
WireConnection;81;0;95;0
WireConnection;92;0;66;0
WireConnection;92;1;81;0
WireConnection;92;2;84;0
WireConnection;24;0;22;0
WireConnection;90;0;75;0
WireConnection;90;1;74;0
WireConnection;79;0;92;0
WireConnection;79;1;80;0
WireConnection;79;2;88;0
WireConnection;91;0;61;0
WireConnection;91;1;90;0
WireConnection;26;0;16;0
WireConnection;26;3;24;0
WireConnection;27;0;26;1
WireConnection;27;2;25;0
WireConnection;78;0;91;0
WireConnection;78;1;79;0
WireConnection;82;0;100;0
WireConnection;82;1;89;0
WireConnection;77;0;91;0
WireConnection;77;1;78;0
WireConnection;77;2;94;0
WireConnection;35;0;27;0
WireConnection;35;1;36;0
WireConnection;69;0;67;0
WireConnection;69;1;66;0
WireConnection;69;2;82;0
WireConnection;28;0;16;0
WireConnection;28;1;35;0
WireConnection;68;0;77;0
WireConnection;109;0;97;0
WireConnection;109;1;15;3
WireConnection;109;2;98;0
WireConnection;38;0;28;0
WireConnection;38;1;39;0
WireConnection;87;0;69;0
WireConnection;87;1;95;0
WireConnection;87;2;79;0
WireConnection;76;0;68;0
WireConnection;37;0;38;0
WireConnection;37;1;15;4
WireConnection;111;0;87;0
WireConnection;111;1;112;0
WireConnection;110;0;109;0
WireConnection;102;0;76;0
WireConnection;102;1;15;2
WireConnection;102;2;103;0
WireConnection;0;0;82;0
WireConnection;0;1;86;0
WireConnection;0;2;111;0
WireConnection;0;4;102;0
WireConnection;0;5;110;0
WireConnection;0;9;89;4
WireConnection;0;11;37;0
ASEEND*/
//CHKSM=D6A77C0C96FF38EBBB74904497E8FEDB44D85BCA