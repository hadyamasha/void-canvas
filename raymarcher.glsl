#version 300 es
precision highp float;

uniform float u_time; uniform vec2 u_resolution; uniform vec2 u_mouse; uniform vec2 u_cameraRot; 
uniform float u_zoom; uniform float u_morph; uniform float u_curse; uniform float u_glitch; uniform float u_fractal;
uniform vec3 u_bgColor; uniform vec3 u_objColor; uniform vec3 u_lightColor;
uniform float u_audioBass; uniform float u_audioTreble;

// NEW UNIFORMS
uniform float u_textureIntensity;
uniform float u_magmaMode;
uniform float u_bloom;

out vec4 fragColor;

// --- 1. PROCEDURAL 3D NOISE (Fractional Brownian Motion) ---
// Generates random pseudo-static based on a coordinate
float hash(float n) { return fract(sin(n) * 43758.5453123); }

// Smooths the static into cloudy 3D noise
float noise(vec3 x) {
    vec3 p = floor(x); vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0 + p.z * 113.0;
    return mix(
        mix(mix(hash(n+0.0), hash(n+1.0), f.x), mix(hash(n+57.0), hash(n+58.0), f.x), f.y),
        mix(mix(hash(n+113.0), hash(n+114.0), f.x), mix(hash(n+170.0), hash(n+171.0), f.x), f.y), f.z);
}

// Loops the noise 4 times to create highly detailed natural fractals
float fbm(vec3 p) {
    float f = 0.0; float amp = 0.5;
    for(int i = 0; i < 4; i++) {
        f += amp * noise(p);
        p *= 2.0; amp *= 0.5;
    }
    return f;
}

// --- 2. UTILITY & SHAPES ---
float smax(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0); return mix(a, b, h) + k * h * (1.0 - h);
}

mat2 rot(float a) { float s = sin(a), c = cos(a); return mat2(c, -s, s, c); }
float sdBox(vec3 p, vec3 b) { vec3 q = abs(p) - b; return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0); }

vec3 getEraserPos() {
    vec2 mouseUV = (u_mouse - 0.5 * u_resolution.xy) / u_resolution.y;
    vec3 mouse_rd = normalize(vec3(mouseUV, 1.0));
    mouse_rd.yz *= rot(u_cameraRot.y); mouse_rd.xz *= rot(u_cameraRot.x);
    vec3 ro = vec3(0.0, 0.0, -u_zoom);
    ro.yz *= rot(u_cameraRot.y); ro.xz *= rot(u_cameraRot.x);
    return ro + mouse_rd * (u_zoom - 0.5);
}

// --- 3. SCENE MATH ---
float map(vec3 p) {
    vec3 objPos = p;
    if (u_fractal > 0.5) {
        float spacing = 4.0;
        objPos.xz = mod(objPos.xz + spacing * 0.5, spacing) - spacing * 0.5;
    }

    float dynamicRipple = 0.1 * u_curse + (u_audioBass * 0.4);
    float ripple = sin(5.0 * objPos.x + u_time * 2.0) * sin(5.0 * objPos.y + u_time * 2.0) * sin(5.0 * objPos.z + u_time * 2.0) * dynamicRipple;
    float currentRadius = 1.0 + (u_audioBass * 0.3);
    float sphereSDF = length(objPos) - currentRadius; 
    float boxSDF = sdBox(objPos, vec3(currentRadius * 0.8));
    
    float baseShape = mix(sphereSDF, boxSDF, u_morph);
    float mutatedShape = baseShape - ripple;
    
    float eraserSphere = length(p - getEraserPos()) - 0.5; 
    float corruptedShape = smax(mutatedShape, -eraserSphere, 0.3) * 0.5;
    
    float floorPlane = p.y + 1.5;
    return min(corruptedShape, floorPlane);
}

float raymarch(vec3 ro, vec3 rd) {
    float dO = 0.0; 
    for(int i = 0; i < 100; i++) {
        vec3 p = ro + rd * dO; 
        float dS = map(p);     
        dO += dS;              
        if(dS < 0.001 || dO > 100.0) break;
    }
    return dO;
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.001, 0.0);
    vec3 n = vec3(map(p+e.xyy)-map(p-e.xyy), map(p+e.yxy)-map(p-e.yxy), map(p+e.yyx)-map(p-e.yyx));
    return normalize(n);
}

float getSoftShadow(vec3 ro, vec3 rd, float mint, float maxt, float k) {
    float res = 1.0; float t = mint;
    for(int i = 0; i < 30; i++) {
        float h = map(ro + rd * t);
        if(h < 0.001) return 0.0; 
        res = min(res, k * h / t); t += clamp(h, 0.02, 0.2); 
        if(t > maxt) break;
    }
    return clamp(res, 0.0, 1.0);
}

// --- 4. LIGHTING & TEXTURES ---
vec3 getLight(vec3 p, vec3 rd) {
    vec3 lightPos = vec3(2.0 * sin(u_time * 1.5), 3.0, 2.0 * cos(u_time * 1.5));
    vec3 l = normalize(lightPos - p);
    vec3 n = getNormal(p);
    vec3 v = normalize(-rd); 

    float distToLight = length(lightPos - p);
    float shadow = getSoftShadow(p + n * 0.05, l, 0.01, distToLight, 16.0);

    vec3 baseColor = vec3(0.1, 0.1, 0.12);
    float shininess = 16.0;
    bool isObject = (p.y > -1.49);
    float corruptionBlend = 0.0;
    vec3 emission = vec3(0.0);

    if (isObject) {
        shininess = 32.0;

        // --- APPLY 3D TEXTURES ---
        // Generate the swirling organic noise based on 3D coordinates and time
        float surfaceNoise = fbm(p * 2.5 + u_time * 0.3); 
        
        // Mode 1: Marble (Mixes base color with white veins)
        float marbleVeins = smoothstep(0.4, 0.5, sin(surfaceNoise * 10.0));
        vec3 marble = mix(u_objColor, vec3(1.0), marbleVeins);
        
        // Mode 2: Magma (Mixes glowing lava with dark crust)
        vec3 hotLava = vec3(1.0, 0.2, 0.0);
        vec3 darkCrust = vec3(0.05, 0.02, 0.01);
        float magmaMix = smoothstep(0.2, 0.6, surfaceNoise);
        vec3 magma = mix(hotLava, darkCrust, magmaMix);
        
        // Select texture and blend it based on the Texture slider
        vec3 texturedColor = mix(marble, magma, u_magmaMode);
        baseColor = mix(u_objColor, texturedColor, u_textureIntensity);
        
        // Make the Magma actually emit light in the dark spots!
        if (u_magmaMode > 0.5) {
            emission += hotLava * (1.0 - magmaMix) * 1.5 * u_textureIntensity;
        }

        // --- APPLY NEON ERASER ---
        float distToEraser = length(p - getEraserPos());
        corruptionBlend = smoothstep(0.8, 0.45, distToEraser);
        baseColor = mix(baseColor, vec3(0.0), corruptionBlend); // Scorch the surface black
        
        vec3 neonGlow = vec3(1.0, 0.2, 0.8) * (1.0 + u_audioTreble * 5.0);
        emission += neonGlow * corruptionBlend;
    }

    vec3 ambient = vec3(0.05, 0.05, 0.1); 
    float diffIntensity = max(dot(n, l), 0.0);
    vec3 diffuse = baseColor * diffIntensity * shadow * u_lightColor; 
    
    vec3 r = reflect(-l, n);
    float specIntensity = pow(max(dot(r, v), 0.0), shininess); 
    vec3 specular = vec3(1.0) * specIntensity * shadow * (1.0 - corruptionBlend) * u_lightColor;

    return ambient + diffuse + specular + emission;
}

vec3 renderScene(vec3 ro, vec3 rd) {
    float d = raymarch(ro, rd);
    vec3 color = u_bgColor; 
    if (d < 100.0) {
        vec3 p = ro + rd * d; vec3 n = getNormal(p); color = getLight(p, rd);
        if (p.y < -1.49) {
            vec3 ref_rd = reflect(rd, n); vec3 ref_ro = p + n * 0.05; 
            float ref_d = raymarch(ref_ro, ref_rd);
            if (ref_d < 100.0) {
                vec3 ref_p = ref_ro + ref_rd * ref_d; vec3 ref_color = getLight(ref_p, ref_rd);
                color = mix(color, ref_color, 0.4);
            }
        }
    }
    return color;
}

// --- 5. POST-PROCESSING (CHROMATIC ABERRATION & BLOOM) ---
void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;
    vec2 mouseUV = (u_mouse - 0.5 * u_resolution.xy) / u_resolution.y;
    
    float distToMouse = length(uv - mouseUV);
    float glitchMask = smoothstep(0.4, 0.0, distToMouse);
    float dynamicGlitch = u_glitch + (u_audioTreble * 8.0);
    float jitter = sin(u_time * 50.0 + uv.y * 100.0) * 0.03 * glitchMask * dynamicGlitch;
    vec2 glitchOffset = vec2(jitter, 0.0);

    vec3 ro = vec3(0.0, 0.0, -u_zoom); 
    ro.yz *= rot(u_cameraRot.y); ro.xz *= rot(u_cameraRot.x);

    // 1. The Tri-Pass Base Image (Chromatic Aberration)
    vec3 rd_r = normalize(vec3(uv + glitchOffset, 1.0)); rd_r.yz *= rot(u_cameraRot.y); rd_r.xz *= rot(u_cameraRot.x);
    vec3 rd_g = normalize(vec3(uv, 1.0)); rd_g.yz *= rot(u_cameraRot.y); rd_g.xz *= rot(u_cameraRot.x);
    vec3 rd_b = normalize(vec3(uv - glitchOffset, 1.0)); rd_b.yz *= rot(u_cameraRot.y); rd_b.xz *= rot(u_cameraRot.x);
    
    vec3 finalColor = vec3(renderScene(ro, rd_r).r, renderScene(ro, rd_g).g, renderScene(ro, rd_b).b);

    // 2. The Bright-Pass Bloom
    // If the slider is up, we tap the render engine 4 more times slightly offset from the pixel.
    // If it finds a color brighter than 0.8, it smears it across the neighboring pixels as a glow.
    if (u_bloom > 0.0) {
        float bSize = 0.015 * u_bloom; // Blur radius
        
        vec3 rd1 = normalize(vec3(uv + vec2(bSize, bSize), 1.0)); rd1.yz *= rot(u_cameraRot.y); rd1.xz *= rot(u_cameraRot.x);
        vec3 rd2 = normalize(vec3(uv + vec2(-bSize, bSize), 1.0)); rd2.yz *= rot(u_cameraRot.y); rd2.xz *= rot(u_cameraRot.x);
        vec3 rd3 = normalize(vec3(uv + vec2(bSize, -bSize), 1.0)); rd3.yz *= rot(u_cameraRot.y); rd3.xz *= rot(u_cameraRot.x);
        vec3 rd4 = normalize(vec3(uv + vec2(-bSize, -bSize), 1.0)); rd4.yz *= rot(u_cameraRot.y); rd4.xz *= rot(u_cameraRot.x);
        
        vec3 b1 = renderScene(ro, rd1); vec3 b2 = renderScene(ro, rd2);
        vec3 b3 = renderScene(ro, rd3); vec3 b4 = renderScene(ro, rd4);
        
        // Filter out dark pixels so ONLY the bright neon parts bloom
        vec3 brightColors = max(b1 - 0.8, 0.0) + max(b2 - 0.8, 0.0) + max(b3 - 0.8, 0.0) + max(b4 - 0.8, 0.0);
        finalColor += brightColors * 0.5 * u_bloom;
    }

    finalColor = pow(finalColor, vec3(1.0/2.2)); // Gamma correction
    fragColor = vec4(finalColor, 1.0);
}