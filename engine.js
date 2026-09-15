const canvas = document.getElementById('glcanvas');
const gl = canvas.getContext('webgl2');
if (!gl) alert("WebGL2 is not supported by your browser.");

// DOM Elements
const micBtn = document.getElementById('micBtn');
const zoomSlider = document.getElementById('zoomSlider');
const morphSlider = document.getElementById('morphSlider');
const malwareSlider = document.getElementById('malwareSlider'); // NEW
const curseSlider = document.getElementById('curseSlider');
const glitchSlider = document.getElementById('glitchSlider');
const fractalToggle = document.getElementById('fractalToggle');
const bgColorPicker = document.getElementById('bgColor');
const objColorPicker = document.getElementById('objColor');
const lightColorPicker = document.getElementById('lightColor');
const textureSlider = document.getElementById('textureSlider');
const magmaToggle = document.getElementById('magmaToggle');
const bloomSlider = document.getElementById('bloomSlider');

let mouseX = 0.0, mouseY = 0.0;
let cameraRotX = 0.0, cameraRotY = -0.2; 
let isDragging = false, lastDragX = 0, lastDragY = 0;

window.addEventListener('mousedown', (e) => { 
    if (e.target.tagName !== 'INPUT' && e.target.tagName !== 'BUTTON') { 
        isDragging = true; lastDragX = e.clientX; lastDragY = e.clientY; 
    }
});
window.addEventListener('mouseup', () => { isDragging = false; });
window.addEventListener('mousemove', (e) => {
    mouseX = e.clientX; mouseY = canvas.height - e.clientY;
    if (isDragging) {
        cameraRotX -= (e.clientX - lastDragX) * 0.01; 
        cameraRotY -= (e.clientY - lastDragY) * 0.01;
        cameraRotY = Math.max(-Math.PI/2 + 0.1, Math.min(Math.PI/2 - 0.1, cameraRotY));
        lastDragX = e.clientX; lastDragY = e.clientY;
    }
});

function hexToRGB(hex) { return [parseInt(hex.slice(1, 3), 16)/255, parseInt(hex.slice(3, 5), 16)/255, parseInt(hex.slice(5, 7), 16)/255]; }

let audioCtx, analyser, dataArray;
let isAudioInitialized = false, isAudioPlaying = false;
let smoothBass = 0.0, smoothTreble = 0.0;

micBtn.addEventListener('click', async () => {
    if (!isAudioInitialized) {
        try {
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });
            audioCtx = new (window.AudioContext || window.webkitAudioContext)();
            analyser = audioCtx.createAnalyser(); analyser.fftSize = 256; 
            const source = audioCtx.createMediaStreamSource(stream);
            source.connect(analyser);
            dataArray = new Uint8Array(analyser.frequencyBinCount);
            isAudioInitialized = true; isAudioPlaying = true; updateMicUI();
        } catch (err) { alert("Microphone access is required for audio reactivity!"); }
    } else {
        if (isAudioPlaying) { audioCtx.suspend(); isAudioPlaying = false; } 
        else { audioCtx.resume(); isAudioPlaying = true; }
        updateMicUI();
    }
});

function updateMicUI() {
    if (isAudioPlaying) {
        micBtn.innerText = "MIC ACTIVE 🔊"; micBtn.style.color = "#00ff00"; micBtn.style.borderColor = "#00ff00"; micBtn.style.background = "rgba(0, 255, 0, 0.1)";
    } else {
        micBtn.innerText = "MIC PAUSED 🔇"; micBtn.style.color = "#ff33cc"; micBtn.style.borderColor = "#ff33cc"; micBtn.style.background = "transparent";
    }
}

const vertexShaderSource = `#version 300 es
    in vec2 position; void main() { gl_Position = vec4(position, 0.0, 1.0); }`;

async function init() {
    const response = await fetch('raymarcher.glsl');
    const fragmentShaderSource = await response.text();

    function compileShader(type, source) {
        const shader = gl.createShader(type); gl.shaderSource(shader, source); gl.compileShader(shader);
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) { console.error("SHADER ERROR:", gl.getShaderInfoLog(shader)); gl.deleteShader(shader); }
        return shader;
    }

    const program = gl.createProgram();
    gl.attachShader(program, compileShader(gl.VERTEX_SHADER, vertexShaderSource)); gl.attachShader(program, compileShader(gl.FRAGMENT_SHADER, fragmentShaderSource));
    gl.linkProgram(program); gl.useProgram(program);

    const vertices = new Float32Array([-1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, 1.0]);
    const vbo = gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER, vbo); gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);
    const posLocation = gl.getAttribLocation(program, "position"); gl.enableVertexAttribArray(posLocation); gl.vertexAttribPointer(posLocation, 2, gl.FLOAT, false, 0, 0);

    const locs = {
        time: gl.getUniformLocation(program, "u_time"), res: gl.getUniformLocation(program, "u_resolution"),
        mouse: gl.getUniformLocation(program, "u_mouse"), rot: gl.getUniformLocation(program, "u_cameraRot"),
        zoom: gl.getUniformLocation(program, "u_zoom"), morph: gl.getUniformLocation(program, "u_morph"),
        malware: gl.getUniformLocation(program, "u_malware"), // NEW
        curse: gl.getUniformLocation(program, "u_curse"), glitch: gl.getUniformLocation(program, "u_glitch"),
        fractal: gl.getUniformLocation(program, "u_fractal"), bgCol: gl.getUniformLocation(program, "u_bgColor"),
        objCol: gl.getUniformLocation(program, "u_objColor"), lightCol: gl.getUniformLocation(program, "u_lightColor"),
        aBass: gl.getUniformLocation(program, "u_audioBass"), aTreble: gl.getUniformLocation(program, "u_audioTreble"),
        texInt: gl.getUniformLocation(program, "u_textureIntensity"),
        magma: gl.getUniformLocation(program, "u_magmaMode"), bloom: gl.getUniformLocation(program, "u_bloom")
    };

    function render(time) {
        if (canvas.width !== window.innerWidth || canvas.height !== window.innerHeight) {
            canvas.width = window.innerWidth; canvas.height = window.innerHeight; gl.viewport(0, 0, canvas.width, canvas.height);
        }

        let currentBass = 0.0, currentTreble = 0.0;
        if (isAudioInitialized && isAudioPlaying) {
            analyser.getByteFrequencyData(dataArray);
            let bSum = 0; for(let i = 0; i < 10; i++) bSum += dataArray[i]; currentBass = (bSum / 10) / 255.0; 
            let tSum = 0; for(let i = 50; i < 90; i++) tSum += dataArray[i]; currentTreble = (tSum / 40) / 255.0;
        }
        smoothBass = smoothBass * 0.8 + currentBass * 0.2; smoothTreble = smoothTreble * 0.8 + currentTreble * 0.2;

        gl.uniform1f(locs.time, time * 0.001); gl.uniform2f(locs.res, canvas.width, canvas.height);
        gl.uniform2f(locs.mouse, mouseX, mouseY); gl.uniform2f(locs.rot, cameraRotX, cameraRotY);
        gl.uniform1f(locs.zoom, parseFloat(zoomSlider.value)); gl.uniform1f(locs.morph, parseFloat(morphSlider.value));
        
        gl.uniform1f(locs.malware, parseFloat(malwareSlider.value)); // SEND MALWARE
        
        gl.uniform1f(locs.curse, parseFloat(curseSlider.value)); gl.uniform1f(locs.glitch, parseFloat(glitchSlider.value));
        gl.uniform1f(locs.fractal, fractalToggle.checked ? 1.0 : 0.0);
        gl.uniform3fv(locs.bgCol, hexToRGB(bgColorPicker.value)); gl.uniform3fv(locs.objCol, hexToRGB(objColorPicker.value));
        gl.uniform3fv(locs.lightCol, hexToRGB(lightColorPicker.value));
        gl.uniform1f(locs.aBass, smoothBass); gl.uniform1f(locs.aTreble, smoothTreble);
        gl.uniform1f(locs.texInt, parseFloat(textureSlider.value));
        gl.uniform1f(locs.magma, magmaToggle.checked ? 1.0 : 0.0);
        gl.uniform1f(locs.bloom, parseFloat(bloomSlider.value));

        gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
        requestAnimationFrame(render);
    }
    requestAnimationFrame(render);
}
init();