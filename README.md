# 🌌 The Void Canvas: Audio-Reactive Raymarching Sandbox

**A custom-built 3D rendering engine built entirely from scratch using pure math and WebGL2.**

Forget traditional polygons and triangles. *The Void Canvas* is a real-time Raymarching engine powered by Signed Distance Fields (SDFs). There are no external 3D libraries like Three.js used here—every pixel, shadow, reflection, and glowing neon edge is calculated mathematically in a custom GLSL fragment shader.

## 🚀 Live Demo
**Play with the engine here:** `[Insert your GitHub Pages URL here]`

*(Note: Click "Engage Microphone" and play some music with heavy bass to see the audio reactivity in action!)*

---

## 🎮 The Features

* 🔊 **Audio-Reactive Physics:** Hook up your microphone or blast a song from your speakers. The Web Audio API analyzes the frequency spectrum, causing the geometry to physically throb to the bass while the camera glitches to the treble.
* ⛏️ **Real-Time Geometry Carving:** Wield the Paintress's eraser! Using SDF Boolean Subtraction, you can use your mouse to smoothly "melt" and carve through the 3D geometry like wet clay, exposing the glowing neon core inside.
* 🌋 **Procedural 3D Textures:** Toggle on *Magma Mode*. Instead of flat image files, the engine uses Fractional Brownian Motion (fBm) to generate infinite, swirling 3D noise that physically wraps around the mutating shapes. 
* 🦠 **Malware Voxelizer:** Inject a mathematical payload that snaps the smooth SDF coordinates to a rigid grid, shattering the shapes into hundreds of twitching 3D voxels.
* 🌌 **Infinite Fractal Grids:** Bend space itself. With a single click, a modulo function splinters the world into an endless horizon of repeating shapes.
* ✨ **Cinematic Post-Processing:** Features ray-traced soft shadows, mirror reflections, cinematic bloom (glow), and a custom Chromatic Aberration lens glitch effect. 

---

## 💻 How to Run Locally

Because this project uses the Web Audio API (for the microphone) and the `fetch()` API (to load the GLSL shader), **it must be run through a local web server**. You cannot just double-click the `index.html` file.

### Option 1: VS Code (Recommended)
1. Clone this repository to your machine.
2. Open the folder in **Visual Studio Code**.
3. Install the **Live Server** extension by Ritwick Dey.
4. Click the **"Go Live"** button in the bottom right corner of VS Code.
5. The project will automatically open in your browser at `http://127.0.0.1:5500`.

### Option 2: Python HTTP Server
If you have Python installed, open your terminal in the project directory and run:
```bash
python -m http.server 8000
