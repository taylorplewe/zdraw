# zdraw
Simple drawing program written in Zig

<img width="767" height="804" alt="image" src="https://github.com/user-attachments/assets/574c552d-f751-4ce0-be3d-716abd349d69" />

This was born out of an interest to re-write [my entry](https://github.com/taylorplewe/flopathon-2025/tree/sdl) into a work competition from C to Zig.

| button | action |
| - | - |
| left click | draw black |
| right click | draw white |
| wheel up | increase pencil size |
| wheel down | decrease pencil size |
| ctrl + z | undo |
| ctrl + shift + z | redo |
| q | (on native app) quit |

The project consists of a _backend_, which contains all the actual drawing code and is written in Zig, and two different _frontends:_ a native SDL one, which is written in Zig but calls SDL C functions, and a WebAssembly one.

You can see the WebAssembly one live at https://tplewe.com/zdraw.

## Build instructions
You have the option to build one or both of the frontends.
### Native (SDL3)
Requirements:
- [Zig](https://ziglang.org/) 0.14.x
- [SDL3 development headers and DLLs](https://github.com/libsdl-org/SDL/releases) (the one I used on Windows was `SDL3-devel-3.2.18-VC`)

```fish
zig build -Dnative
```
By default, it searches for your SDL3 lib and include directories in your `%LIB%` and `%INCLUDE%` environment variables, respectively. If you wish to manually provide the paths to these directories, build with
```fish
zig build -Dnative -Dinclude-path="path/to/sdl3/include" -Dlib-path="path/to/sdl3/lib"
```
### WebAssembly
Requirements:
- [Zig](https://ziglang.org/) 0.14.x
- TypeScript

```fish
zig build -Dwasm
```
This will also run `tsc`, transpiling any TypeScript files to JavaScript.

---

To build both frontends, simply run
```fish
zig build
```
With any of the above build commands, append `-Doptimize=ReleaseSmall` for an optimized release build.
