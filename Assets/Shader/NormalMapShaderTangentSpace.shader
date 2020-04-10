// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/NormalMapShaderTangentSpace"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("MainTex", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
		_Specular("Specular", Color) = (1,1,1,1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
	}
		SubShader
		{
			Pass {
			//只有定义了正确的LightMode,才能拿到正确的光照变量如_LightColor0
				Tags {"LightMode" = "ForwardBase"}
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
			//使用unity内置文件Lighting.cginc
				#include "Lighting.cginc"

			//Pass中需定义Properties中的同名变量，注意类型对应
				fixed4 _Color;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				sampler2D _BumpMap;
				float4 _BumpMap_ST;
				float _BumpScale;
				fixed4 _Specular;
				float _Gloss;
				//顶点着色器输入
				struct a2v {
					// 模型空间坐标
					float4 vertex:POSITION;
					// 模型空间 顶点法向
					float3 normal:NORMAL;
					// 模型空间 顶点切向
					float4 tangent:TANGENT;
					// 第一套纹理坐标（未缩放平移的）
					float4 texcoord:TEXCOORD0;
				};
				//顶点着色器输出，片元着色器输出
				struct v2f {
					// 裁剪空间顶点坐标
					float4 pos:SV_POSITION;
					// xy存储贴图纹理坐标 zw存储法线纹理坐标
					float4 uv:TEXCOORD0;
					// 灯光方向
					float3 lightDir:TEXCOORD1;
					// 摄像机方向
					float3 viewDir:TEXCOORD2;
				};
				v2f vert(a2v v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
					o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
					//得到从模型空间到切线空间的变换矩阵rotation
					TANGENT_SPACE_ROTATION;
					o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
					o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
					return o;
				}
				fixed4 frag(v2f i) :SV_Target{
					//归一化
					fixed3 tangentLightDir = normalize(i.lightDir);
					fixed3 tangentViewDir = normalize(i.viewDir);
					//tex2D 得到纹素值（根据纹理坐标找到贴图上的值）
					fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
					//法向
					fixed3 tangentNormal;
					//贴图被设定为NormalMap后会被压缩，使用UnpackNormal函数得到正确的法向
					tangentNormal = UnpackNormal(packedNormal);
					tangentNormal.xy *= _BumpScale;
					//根据归一化向量，计算z值
					tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
					//反射率（漫反射）
					fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
					//环境光
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
					//漫反射结果 需要光向、法向
					fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
					//高光反射需要 光向、摄像机方向、法向
					fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
					//高光反射结果
					fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);

					return fixed4(ambient + diffuse + specular, 1.0);
				}
				ENDCG
		}
    }
    FallBack "Diffuse"
}
