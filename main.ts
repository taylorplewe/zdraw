const canvas: HTMLCanvasElement | null = document.querySelector('canvas') as HTMLCanvasElement;
const ctx = canvas?.getContext('2d');
const SCALE = 5;
const WIDTH = 128;
const HEIGHT = 128;

interface ZdrawExports extends WebAssembly.Exports {
  init: () => void,
  update_mouse_button: (button: number) => void,
  update_mouse_motion: (x: number, y: number) => void,
  update_mouse_wheel: (delta: number) => void,
  update_program_event: (event_type: number) => void,
  get_pixels: () => number, // [*]Pixel
}

enum MouseButton {
  Left,
  Right,
  None,
}

enum ProgramEvent {
  Quit,
  Undo,
  Redo
}

let wasmInstance: ZdrawExports;
let pixelsPtr: number;

async function loadWasm() {
  const response = await fetch('zig-out/bin/zdraw-wasm.wasm');
  const buffer = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(buffer);
  wasmInstance = instance.exports as ZdrawExports;

  // initialize
  wasmInstance.init();
  pixelsPtr = wasmInstance.get_pixels();

  // start render loop
  render();
}

function render() {
  if (!wasmInstance) return;

  // get pixel data from wasm memory
  const memory = new Uint8Array(wasmInstance.memory["buffer"], pixelsPtr, WIDTH * HEIGHT * 4);
  const imageData = new ImageData(WIDTH, HEIGHT);
  imageData.data.set(memory);

  // scale and draw to canvas
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

canvas.addEventListener('mousedown', (e) => {
  const rect = canvas.getBoundingClientRect();
  const x = (e.clientX - rect.left) / SCALE;
  const y = (e.clientY - rect.top) / SCALE;
  const button = e.button === 0 ? MouseButton.Left : MouseButton.Right;
  wasmInstance.update_mouse_button(button);
  wasmInstance.update_mouse_motion(x, y);
  e.preventDefault();
});

canvas.addEventListener('mouseup', (e) => {
  wasmInstance.update_mouse_button(MouseButton.None); // None
  e.preventDefault();
});

canvas.addEventListener('mousemove', (e) => {
  const rect = canvas.getBoundingClientRect();
  const x = (e.clientX - rect.left) / SCALE;
  const y = (e.clientY - rect.top) / SCALE;
  wasmInstance.update_mouse_motion(x, y);
});

canvas.addEventListener('wheel', (e) => {
  e.preventDefault();
  const delta = e.deltaY < 0 ? 1 : -1;
  wasmInstance.update_mouse_wheel(delta);
});

document.addEventListener('keydown', (e) => {
  if (e.ctrlKey && e.key === 'z') {
    e.preventDefault();
    wasmInstance.update_program_event(ProgramEvent.Undo);
  } else if (e.ctrlKey && e.shiftKey && e.key === 'z') {
    e.preventDefault();
    wasmInstance.update_program_event(ProgramEvent.Redo);
  }
});

loadWasm();
