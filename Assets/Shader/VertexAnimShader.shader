// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/VertexAnimShader"
{
	Properties{
		_MainTex ("Main Tex", 2D) = "white"{}
		_Color("Color Tint", Color) = (1.0,1.0,1.0,1.0)
		_Magnitude("Magnitude", Float) = 1
		_Frequency_x("Frequency X", Float) = 1
		_Frequency_y("Frequency Y", Float) = 1
		_Frequency_z("Frequency Z", Float) = 1
		_InvWaveLength("InvWaveLength", Float) = 0.5
		_Speed ("Speed",Float) = 0.5
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "DisableBatching" = "True"}
		Pass{
			Tags { "LightMode" = "ForwardBase"}
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
#include "UnityCG.cginc"
		sampler2D _MainTex;
		float4 _MainTex_ST;
		fixed4 _Color;
		float _Magnitude;
		float _Frequency_x;
		float _Frequency_y;
		float _Frequency_z;
		float _InvWaveLength;
		float _Speed;

		struct a2v {
			float4 vertex: POSITION;
			float3 normal: NORMAL;
			float4 texcoord:TEXCOORD0;
		};
		struct v2f {
			float2 uv : TEXCOORD0;
			float4 pos: SV_POSITION;
		};
		v2f vert(a2v v){
			v2f o;
			float4 offset;
			offset.yzw = float3(1.0, 1.0, 1.0);
			offset.x = sin(_Frequency_x * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
			offset.y = sin(_Frequency_y * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
			offset.z = cos(_Frequency_z * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;

			o.pos = UnityObjectToClipPos(v.vertex + offset);
			o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			o.uv += float2(0.0, _Time.y*_Speed);
			return o;
		}
		fixed4 frag(v2f i) : SV_Target{
			fixed4 c = tex2D(_MainTex, i.uv);
			c.rgb *= _Color.rgb;
			return c;
		}
		ENDCG
		}
    }
    FallBack "Transparent/VertexLit"
}
