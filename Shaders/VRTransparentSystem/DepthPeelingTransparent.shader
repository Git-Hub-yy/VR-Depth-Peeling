Shader"Custom/VR/DepthPeelingTransparent"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
        _Alpha ("Alpha", Range(0, 1)) = 0.8
        _LayerCount ("Layer Count", Int) = 2
        _DepthTolerance ("Depth Tolerance", Float) = 0.01
    }
    
    SubShader
    {
        Tags 
        {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "IgnoreProjector"="True"
            "VREnabled"="True"
        }
        
LOD 400
        
        // 深度剥离的第一个通道 - 第一层
        Pass
        {
Name"DEPTH_PEEL_LAYER_1"
            Tags
{"LightMode" = "ForwardBase"
}
            
            // 设置模板缓冲用于深度剥离
            Stencil 
            {
Ref 1
                Comp Always
                Pass Replace
            }
            
ZWrite On

ZTest Less

Cull Off

Blend SrcAlpha
OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma target 4.0
            #pragma require depthtexture
            
#include "UnityCG.cginc"
#include "Lighting.cginc"
            
struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
};
            
struct v2f
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 viewDir : TEXCOORD2;
    float4 screenPos : TEXCOORD3;
    float eyeDepth : TEXCOORD4;
                UNITY_FOG_COORDS(5)
    UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
    sampler2D _MainTex;
    float4 _MainTex_ST;
    sampler2D _CameraDepthTexture;
    fixed4 _Color;
    fixed _Alpha;
    int _LayerCount;
    float _DepthTolerance;
            
    v2f vert(appdata v)
    {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
                
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.normal = UnityObjectToWorldNormal(v.normal);
        o.viewDir = normalize(UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v.vertex)));
        o.screenPos = ComputeScreenPos(o.pos);
        o.eyeDepth = -mul(UNITY_MATRIX_MV, v.vertex).z;
                
        UNITY_TRANSFER_FOG(o, o.pos);
        return o;
    }
            
    fixed4 frag(v2f i) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                // 获取当前像素的深度
        float2 screenUV = i.screenPos.xy / i.screenPos.w;
        float sceneDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV));
                
                // 深度剥离：如果当前深度与场景深度相近，则丢弃
        if (abs(i.eyeDepth - sceneDepth) < _DepthTolerance)
        {
            discard;
        }
                
        fixed4 texColor = tex2D(_MainTex, i.uv);
        fixed4 finalColor = texColor * _Color;
                
                // 简单的光照
        float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
        float NdotL = saturate(dot(i.normal, lightDir));
        float3 lighting = NdotL * _LightColor0.rgb + ShadeSH9(float4(i.normal, 1));
                
        finalColor.rgb *= lighting;
        finalColor.a = _Alpha * texColor.a * _Color.a;
                
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
        return finalColor;
    }
            ENDCG
}
        
        // 深度剥离的第二个通道 - 第二层
        Pass
        {
Name"DEPTH_PEEL_LAYER_2"
            Tags
{"LightMode" = "ForwardBase"
}
            
            Stencil 
            {
Ref 2
                Comp Equal
                Pass Keep
            }
            
ZWrite On

ZTest Less

Cull Off

Blend SrcAlpha
OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma target 4.0
            #pragma require depthtexture
            
#include "UnityCG.cginc"
#include "Lighting.cginc"
            
struct appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
};
            
struct v2f
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 viewDir : TEXCOORD2;
    float4 screenPos : TEXCOORD3;
    float eyeDepth : TEXCOORD4;
                UNITY_FOG_COORDS(5)
    UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
    sampler2D _MainTex;
    float4 _MainTex_ST;
    sampler2D _CameraDepthTexture;
    fixed4 _Color;
    fixed _Alpha;
    float _DepthTolerance;
            
    v2f vert(appdata v)
    {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
                
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.normal = UnityObjectToWorldNormal(v.normal);
        o.viewDir = normalize(UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v.vertex)));
        o.screenPos = ComputeScreenPos(o.pos);
        o.eyeDepth = -mul(UNITY_MATRIX_MV, v.vertex).z;
                
        UNITY_TRANSFER_FOG(o, o.pos);
        return o;
    }
            
    fixed4 frag(v2f i) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
                // 获取当前像素的深度
        float2 screenUV = i.screenPos.xy / i.screenPos.w;
        float sceneDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV));
                
                // 深度剥离：只渲染比第一层更深的片段
        if (i.eyeDepth <= sceneDepth)
        {
            discard;
        }
                
        fixed4 texColor = tex2D(_MainTex, i.uv);
        fixed4 finalColor = texColor * _Color;
                
                // 简单的光照
        float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
        float NdotL = saturate(dot(i.normal, lightDir));
        float3 lighting = NdotL * _LightColor0.rgb + ShadeSH9(float4(i.normal, 1));
                
        finalColor.rgb *= lighting * 0.8; // 第二层稍暗
        finalColor.a = _Alpha * texColor.a * _Color.a * 0.6;
                
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
        return finalColor;
    }
            ENDCG
}
        
        // 第三层及以上的通用通道
        Pass
        {
Name"DEPTH_PEEL_LAYER_N"
            Tags
{"LightMode" = "ForwardAdd"
}
            
            Stencil 
            {
Ref 3
                Comp Equal
                Pass Keep
            }
            
ZWrite Off

ZTest Less

Cull Off

Blend SrcAlpha
OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma target 4.0
            #pragma require depthtexture
            
#include "UnityCG.cginc"
            
struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
};
            
struct v2f
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float4 screenPos : TEXCOORD1;
                UNITY_FOG_COORDS(2)
    UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
    sampler2D _MainTex;
    float4 _MainTex_ST;
    sampler2D _CameraDepthTexture;
    fixed4 _Color;
    fixed _Alpha;
            
    v2f vert(appdata v)
    {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
                
        o.pos = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.screenPos = ComputeScreenPos(o.pos);
                
        UNITY_TRANSFER_FOG(o, o.pos);
        return o;
    }
            
    fixed4 frag(v2f i) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
        fixed4 texColor = tex2D(_MainTex, i.uv);
        fixed4 finalColor = texColor * _Color;
        finalColor.a = _Alpha * texColor.a * _Color.a * 0.3;
                
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
        return finalColor;
    }
            ENDCG
}
    }
    
    FallBack"Transparent/VertexLit"
}