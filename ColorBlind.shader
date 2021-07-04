Shader "yelby/ColorBlind"
{
	Properties
	{
		_ColorBlindMode("Mode", Range (0,3)) = 1
		_MeshRadius ("Mesh Radius", float) = 1
		[Toggle(EnableShader)]
		_EnableShader("Enable", Float) = 1
		_CRed("Red", Vector)		= (1.0,1.0,1.0)
		_CGreen("Green", Vector)	= (1.0,1.0,1.0)
		_CBlue("Blue", Vector)		= (1.0,1.0,1.0)
	}
	SubShader
	{
		// Draw after all opaque geometry
		Tags { "Queue" = "Overlay" }

		Cull off

		// Grab the screen behind the object into _BackgroundTexture
		GrabPass
		{
			"_BackgroundTexture"
		}

		// Render the object with the texture generated above, and invert the colors
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature EnableShader
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 grabPos : TEXCOORD0;
				float4 pos : SV_POSITION;
			};

			uniform float _MeshRadius;

			v2f vert(appdata_base v) {
				v2f o;

				#ifdef UNITY_SINGLE_PASS_STEREO
				float3 camPos = (unity_StereoWorldSpaceCameraPos[0] + unity_StereoWorldSpaceCameraPos[1]) * 0.5;
				#else
				float3 camPos = _WorldSpaceCameraPos;
				#endif

				float3 worldPivot = unity_ObjectToWorld._m03_m13_m23;

				float dist = length(camPos - worldPivot);

				//If you're past a distance you can't see
				if (dist > _MeshRadius/*0.25*/)
				{
					v.vertex.xyz = 0.0;
				}
					

				// use UnityObjectToClipPos from UnityCG.cginc to calculate 
				// the clip-space of the vertex
				o.pos = UnityObjectToClipPos(v.vertex);

				// use ComputeGrabScreenPos function from UnityCG.cginc
				// to get the correct texture coordinate
				o.grabPos = ComputeGrabScreenPos(o.pos);

				return o;
			}

			sampler2D _BackgroundTexture;
			float _ColorBlindMode;
			Vector _CRed;
			Vector _CGreen;
			Vector _CBlue;

			half4 frag(v2f i) : SV_Target
			{
				half4 bgcolor = tex2Dproj(_BackgroundTexture, i.grabPos);

				float red;
				float green;
				float blue;
				int divide = 100;

				int colorMode = _ColorBlindMode;

				switch (colorMode) 
				{
					//Custom
					case 0:
						red		= bgcolor.r * (_CRed[0]/divide)		+ bgcolor.g * (_CRed[1]/divide)		+ bgcolor.b * (_CRed[2]/divide);
						green	= bgcolor.r * (_CGreen[0]/divide)	+ bgcolor.g * (_CGreen[1]/divide)	+ bgcolor.b * (_CGreen[2]/divide);
						blue	= bgcolor.r * (_CBlue[0]/divide)	+ bgcolor.g * (_CBlue[1]/divide)	+ bgcolor.b * (_CBlue[2]/divide);
						break;
					//Red-Green
					case 1:
						red		= bgcolor.r * 0.56667 + bgcolor.g * 0.43333 + bgcolor.b * 0.00000;
						green	= bgcolor.r * 0.55833 + bgcolor.g * 0.44167 + bgcolor.b * 0.00000;
						blue	= bgcolor.r * 0.00000 + bgcolor.g * 0.24167 + bgcolor.b * 0.75833;
						break;
					//Blue-Yellow
					case 2:
						red		= bgcolor.r * 0.95 + bgcolor.g * 0.05000 + bgcolor.b * 0.00000;
						green	= bgcolor.r * 0.00 + bgcolor.g * 0.43333 + bgcolor.b * 0.56667;
						blue	= bgcolor.r * 0.00 + bgcolor.g * 0.47500 + bgcolor.b * 0.52500;
						break;
					//Mono
					case 3:
						red		= bgcolor.r * 0.299 + bgcolor.g * 0.587 + bgcolor.b * 0.114;
						green	= bgcolor.r * 0.299 + bgcolor.g * 0.587 + bgcolor.b * 0.114;
						blue	= bgcolor.r * 0.299 + bgcolor.g * 0.587 + bgcolor.b * 0.114;
						break;
				}

				#ifdef EnableShader
				bgcolor.r = red;
				bgcolor.g = green;
				bgcolor.b = blue;
				#endif

				return bgcolor;
			}
			ENDCG
		}

	}
}
