Shader"Custom/VR/TransparentObject"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Color Tint", Color) = (1,1,1,1)
        _Alpha ("Alpha", Range(0, 1)) = 0.5
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _RefractionIndex ("Refraction Index", Range(0.1, 3)) = 1.0
        _DepthOffset ("Depth Offset", Float) = 0.01
        _FresnelPower ("Fresnel Power", Range(0, 10)) = 5.0
        _FresnelIntensity ("Fresnel Intensity", Range(0, 2)) = 1.0
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
        
LOD 300
        
        // 第一个Pass：渲染背面
        Pass
        {
Name"BACKFACE"
            Tags
{"LightMode" = "ForwardBase"
}

Cull Front

ZWrite Off

Blend SrcAlpha
OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma target 3.0
            
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
    float3 worldPos : TEXCOORD3;
                UNITY_FOG_COORDS(4)
    UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
    sampler2D _MainTex;
    float4 _MainTex_ST;
    fixed4 _Color;
    fixed _Alpha;
    float _RefractionIndex;
    float _DepthOffset;
    float _FresnelPower;
    float _FresnelIntensity;
    half _Glossiness;
    half _Metallic;
            
    v2f vert(appdata v)
    {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
                
                // 应用深度偏移，减少深度冲突
        float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
        float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
        float3 worldNormal = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0)).xyz);
                
                // 深度偏移计算
        float depthBias = _DepthOffset * 0.01;
        worldPos.xyz -= worldNormal * depthBias;
                
        o.pos = mul(UNITY_MATRIX_VP, worldPos);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.normal = UnityObjectToWorldNormal(v.normal);
        o.viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
        o.worldPos = worldPos.xyz;
                
        UNITY_TRANSFER_FOG(o, o.pos);
        return o;
    }
            
    fixed4 frag(v2f i) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
        fixed4 texColor = tex2D(_MainTex, i.uv);
        fixed4 finalColor = texColor * _Color;
                
                // 菲涅尔效果
        float fresnel = pow(1.0 - saturate(dot(i.normal, i.viewDir)), _FresnelPower);
        fresnel = saturate(fresnel * _FresnelIntensity);
                
                // 折射模拟
        float2 refractionOffset = i.normal.xy * (1.0 - _RefractionIndex) * 0.01;
        fixed4 refractedColor = tex2D(_MainTex, i.uv + refractionOffset);
                
                // 混合颜色
        finalColor.rgb = lerp(refractedColor.rgb, finalColor.rgb, 0.5);
        finalColor.rgb += fresnel * _Color.rgb;
                
                // 光照计算
        float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
        float3 lightColor = _LightColor0.rgb;
        float NdotL = saturate(dot(i.normal, lightDir));
        float3 diffuse = lightColor * NdotL;
                
                // 镜面反射
        float3 halfDir = normalize(lightDir + i.viewDir);
        float NdotH = saturate(dot(i.normal, halfDir));
        float specular = pow(NdotH, _Glossiness * 128) * _Metallic;
                
        finalColor.rgb *= diffuse + specular;
        finalColor.a = _Alpha * texColor.a * _Color.a;
                
                // 环境光
        float3 ambient = ShadeSH9(float4(i.normal, 1));
        finalColor.rgb += ambient * 0.3;
                
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
        return finalColor;
    }
            ENDCG
}
        
        // 第二个Pass：渲染正面
        Pass
        {
Name"FRONTFACE"
            Tags
{"LightMode" = "ForwardBase"
}

Cull Back

ZWrite Off

Blend SrcAlpha
OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma target 3.0
            
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
    float3 worldPos : TEXCOORD3;
                UNITY_FOG_COORDS(4)
    UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
    sampler2D _MainTex;
    float4 _MainTex_ST;
    fixed4 _Color;
    fixed _Alpha;
    float _RefractionIndex;
    float _DepthOffset;
    float _FresnelPower;
    float _FresnelIntensity;
    half _Glossiness;
    half _Metallic;
            
    v2f vert(appdata v)
    {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
                
        float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
        float3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
        float3 worldNormal = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0)).xyz);
                
                // 正面深度偏移（与背面相反方向）
        float depthBias = _DepthOffset * 0.01;
        worldPos.xyz += worldNormal * depthBias;
                
        o.pos = mul(UNITY_MATRIX_VP, worldPos);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        o.normal = UnityObjectToWorldNormal(v.normal);
        o.viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
        o.worldPos = worldPos.xyz;
                
        UNITY_TRANSFER_FOG(o, o.pos);
        return o;
    }
            
    fixed4 frag(v2f i) : SV_Target
    {
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                
        fixed4 texColor = tex2D(_MainTex, i.uv);
        fixed4 finalColor = texColor * _Color;
                
                // 菲涅尔效果
        float fresnel = pow(1.0 - saturate(dot(i.normal, i.viewDir)), _FresnelPower);
        fresnel = saturate(fresnel * _FresnelIntensity);
                
                // 折射效果
        float2 refractionOffset = i.normal.xy * (_RefractionIndex - 1.0) * 0.01;
        fixed4 refractedColor = tex2D(_MainTex, i.uv + refractionOffset);
                
                // 混合颜色
        finalColor.rgb = lerp(finalColor.rgb, refractedColor.rgb, 0.3);
        finalColor.rgb += fresnel * _Color.rgb * 0.5;
                
                // 光照计算
        float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
        float3 lightColor = _LightColor0.rgb;
        float NdotL = saturate(dot(i.normal, lightDir));
        float3 diffuse = lightColor * NdotL;
                
                // 镜面反射（Blinn-Phong）
        float3 halfDir = normalize(lightDir + i.viewDir);
        float NdotH = saturate(dot(i.normal, halfDir));
        float specular = pow(NdotH, _Glossiness * 256) * _Metallic;
                
        finalColor.rgb *= diffuse + specular * 2.0;
        finalColor.a = _Alpha * texColor.a * _Color.a * (1.0 - fresnel * 0.3);
                
                // 环境光
        float3 ambient = ShadeSH9(float4(i.normal, 1));
        finalColor.rgb += ambient * 0.5;
                
        UNITY_APPLY_FOG(i.fogCoord, finalColor);
        return finalColor;
    }
            ENDCG
}
    }
    
    FallBack"Transparent/Diffuse"
}