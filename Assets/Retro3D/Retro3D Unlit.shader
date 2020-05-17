Shader "Retro3D/Unlit"
{
    Properties
    {
        _MainTex("Base", 2D) = "white" {}
        _Color("Color", Color) = (0.5, 0.5, 0.5, 1)
        _GeoRes("Geometric Resolution", Float) = 40
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

            #include "UnityCG.cginc"

            #pragma vertex vert
            #pragma fragment frag

            struct v2f
            {
                float4 position : SV_POSITION;
                float3 texcoord : TEXCOORD;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            float4 _Color;
            float _GeoRes;

            float3 CameraWorldPos()
            {
                #if UNITY_SINGLE_PASS_STEREO
                    return(unity_StereoWorldSpaceCameraPos[0] * .5) + (unity_StereoWorldSpaceCameraPos[1] * .5);
                #endif
                return _WorldSpaceCameraPos;
            }

            v2f vert(appdata_base v)
            {
                v2f o;
                float4 wp = mul(unity_ObjectToWorld, v.vertex);

                // Distort in world space.
                // Distorting in camera space? Doing this for real
                // won't work in VR, but maybe we can fake it...
                // float3 viewDir = UNITY_MATRIX_IT_MV[2].xyz;
                float4 objPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
                float3 cameraFac = frac(normalize((CameraWorldPos() - objPos.xyz)) * _GeoRes);

                wp.xyz = wp.xyz * _GeoRes;
                wp.xyz = floor(wp.xyz+cameraFac);
                wp.xyz = wp.xyz / _GeoRes;

                float4 sp = UnityWorldToClipPos(wp);
                o.position = sp;

                float2 uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.texcoord = float3(uv * sp.w, sp.w);

                return o;
            }

            // Returns pixel sharpened to nearest pixel boundary. 
            // texelSize is Unity _Texture_TexelSize; zw is w/h, xy is 1/wh
            float2 sharpSample( float4 texelSize , float2 p )
            {
                p = p*texelSize.zw;
                float2 c = max(0.0001, fwidth(p));
                p = floor(p) + saturate(frac(p) / c);
                p = (p - 0.5)*texelSize.xy;
                return p;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.texcoord.xy / i.texcoord.z;
                uv = sharpSample(_MainTex_TexelSize, uv);
                return tex2D(_MainTex, uv) * _Color * 2;
            }

            ENDCG
        }
    }
}
