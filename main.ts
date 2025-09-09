const canvas: HTMLCanvasElement | null = document.getElementById('canvas') as HTMLCanvasElement;
const ctx = canvas?.getContext('2d');
const SCALE = 5;
const WIDTH = 128;
const HEIGHT = 128;

type Pixel = {
  a: number,
  b: number,
  g: number,
  r: number,
}

interface ZdrawExports extends WebAssembly.Exports {
  init: () => void,
  update_mouse_button: (button: number) => void,
  update_mouse_motion: (x: number, y: number) => void,
  update_mouse_wheel: (delta: number) => void,
  update_program_event: (event_type: number) => void,
  get_pixels: () => number, // [*]Pixel
  get_width: () => number,
  get_height: () => number,
  get_pencil_radius: () => number,
}

let wasmInstance: ZdrawExports;
let pixelsPtr: number;

async function loadWasm() {
  const response = await fetch('zig-out/bin/zdraw-wasm.wasm');
  const buffer = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(buffer);
  wasmInstance = instance.exports as ZdrawExports;

  // Initialize
  wasmInstance.init();
  pixelsPtr = wasmInstance.get_pixels();

  // Start render loop
  render();
}

function render() {
  if (!wasmInstance) return;

  // Get pixel data from WASM memory
  const memory = new Uint8Array(wasmInstance.memory["buffer"], pixelsPtr, WIDTH * HEIGHT * 4);
  const imageData = new ImageData(WIDTH, HEIGHT);
  imageData.data.set(memory);

  // Scale and draw to canvas
  const scaledCanvas = document.createElement('canvas');
  scaledCanvas.width = WIDTH;
  scaledCanvas.height = HEIGHT;
  const scaledCtx = scaledCanvas.getContext('2d');
  scaledCtx?.putImageData(imageData, 0, 0);

  if (ctx) {
    ctx.imageSmoothingEnabled = false;
    ctx.drawImage(scaledCanvas, 0, 0, canvas?.width ?? 0, canvas?.height || 0);
  }

  requestAnimationFrame(render);
}

// Mouse event handlers
let mouseDown = false;

canvas.addEventListener('mousedown', (e) => {
  mouseDown = true;
  const rect = canvas.getBoundingClientRect();
  const x = (e.clientX - rect.left) / SCALE;
  const y = (e.clientY - rect.top) / SCALE;
  const button = e.button === 0 ? 0 : 1; // 0=left, 1=right
  wasmInstance.update_mouse_button(button);
  wasmInstance.update_mouse_motion(x, y);
});

canvas.addEventListener('mouseup', () => {
  mouseDown = false;
  wasmInstance.update_mouse_button(2); // None
});

canvas.addEventListener('mousemove', (e) => {
  const rect = canvas.getBoundingClientRect();
  const x = (e.clientX - rect.left) / SCALE;
  const y = (e.clientY - rect.top) / SCALE;
  wasmInstance.update_mouse_motion(x, y);
  if (mouseDown) {
    const button = e.buttons & 1 ? 0 : (e.buttons & 2 ? 1 : 2);
    wasmInstance.update_mouse_button(button);
  }
});

canvas.addEventListener('wheel', (e) => {
  e.preventDefault();
  const delta = e.deltaY > 0 ? 1 : -1;
  wasmInstance.update_mouse_wheel(delta);
});

// Keyboard for undo/redo
document.addEventListener('keydown', (e) => {
  if (e.ctrlKey && e.key === 'z') {
    e.preventDefault();
    wasmInstance.update_program_event(0); // Undo
  } else if (e.ctrlKey && e.shiftKey && e.key === 'z') {
    e.preventDefault();
    wasmInstance.update_program_event(1); // Redo
  }
});

loadWasm();
