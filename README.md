# zdraw
Simple drawing program written in Zig

<img width="767" height="804" alt="image" src="https://github.com/user-attachments/assets/574c552d-f751-4ce0-be3d-716abd349d69" />

This was born out of an interest to re-write [my entry](https://github.com/taylorplewe/flopathon-2025/tree/sdl) into a work competition from C to Zig.

The project consists of a _backend_, which contains all the actual drawing code and is written in Zig, and two different _frontends:_ a native SDL one, which is written in Zig but calls SDL C functions, and a WebAssembly one.

You can see the WebAssembly one at https://tplewe.com/zdraw.

### Build instructions
Requirements:
- [Zig](https://ziglang.org/)
- for the _native_ frontend, [SDL development headers](https://github.com/libsdl-org/SDL/releases) (the one I used on Windows was `SDL3-devel-3.2.18-VC`)
- for the _WebAssembly_ frontend, TypeScript

Make sure to edit `build.zig` to contain the paths to your SDL directories.
```sh
zig build
```
To fully build the wasm frontend, you'll need TypeScript and run
```sh
tsc
```
