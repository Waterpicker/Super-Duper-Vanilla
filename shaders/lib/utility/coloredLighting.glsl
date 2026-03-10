struct LightData {
    vec3  lightColor;
    ivec2 lmCoord;
};

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;// epsilon to prevent division by zero
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

LightData decodeLightCoord(ivec2 rawLm) {
    int lsShort   = rawLm.x;
    int msShort   = rawLm.y;

    int red8      = (lsShort >> 0) & 0xFF;
    int green8    = (lsShort >> 8) & 0xFF;
    int skyLight4 = (msShort >> 0) & 0xF;
    int blue8     = (msShort >> 4) & 0xFF;
    int alpha4    = (msShort >> 12) & 0xF;

    LightData data;

    if (alpha4 == 0xF) {
        vec3 rgb = pow(vec3(red8, green8, blue8) * 0.003921, vec(1.3));;

        vec3 hsv = rgb2hsv(rgb);

        data.lmCoord.x = int(hsv.z * 16);

        data.lightColor = hsv2rgb(vec3(hsv.xy, 1));
        data.lmCoord.y   = skyLight4 << 4;
    } else {
        data.lightColor = vec3(1);
        data.lmCoord = rawLm;
    }

    return data;
}

vec2 correctedLightMap(ivec2 rawlm) {
    LightData data = decodeLightCoord(rawlm.xy);

    vec2 lm;

    // Lightmap fix for mods
    #ifdef WORLD_CUSTOM_SKYLIGHT
        lm = vec2(lightMapCoord(data.lmCoord.x), WORLD_CUSTOM_SKYLIGHT);
    #else
        lm = lightMapCoord(data.lmCoord.xy);
    #endif

    return lm;
}
