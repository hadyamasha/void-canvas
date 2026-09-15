The Void Canvas: Audio-Reactive Raymarching Sandbox
A custom-built 3D rendering engine built entirely from scratch using pure math and WebGL2.

Forget traditional polygons and triangles. The Void Canvas is a real-time Raymarching engine powered by Signed Distance Fields (SDFs). There are no external 3D libraries like Three.js used here—every pixel, shadow, reflection, and glowing neon edge is calculated mathematically in a custom GLSL fragment shader.


🎮 The Features:

-🔊 Audio-Reactive Physics: Hook up your microphone or blast a song from your speakers. The Web Audio API analyzes the frequency spectrum, causing the geometry to physically throb to the bass while the camera glitches to the treble.

-⛏️ Real-Time Geometry Carving: Wield the Paintress's eraser! Using SDF Boolean Subtraction, you can use your mouse to smoothly "melt" and carve through the 3D geometry like wet clay, exposing the glowing neon core inside.

-🌋 Procedural 3D Textures: Toggle on Magma Mode or Marble Mode. Instead of flat image files, the engine uses Fractional Brownian Motion (fBm) to generate infinite, swirling 3D noise that physically wraps around the mutating shapes.

-🌌 Infinite Fractal Grids: Bend space itself. With a single click, a modulo function splinters the world into an endless horizon of repeating shapes—without dropping a single frame of performance.

-✨ Cinematic Post-Processing: Features ray-traced soft shadows, mirror reflections, cinematic bloom (glow), and a custom Chromatic Aberration lens glitch effect.


🛠️ The Tech Stack:

-Graphics: WebGL2, GLSL (Custom Vertex and Fragment Shaders)

-Logic & UI: Vanilla JavaScript, HTML5, CSS3

-Audio: Web Audio API (Fast Fourier Transform frequency analysis)
