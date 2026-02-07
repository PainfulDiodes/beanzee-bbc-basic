# Building BBC BASIC Z80 with z88dk

This document explains the process of adapting R.T. Russell's BBC BASIC Z80 source code to build with z88dk's assembler (z88dk-z80asm) instead of the original CP/M toolchain.

## Background

The original source files use directives and conventions specific to the CP/M assembler toolchain. To cross-compile on Linux or macOS, we need to translate these to z88dk-compatible syntax.

### Original Build Process

The original CP/M build uses `MAKE.SUB` batch files:

```
z80asm dist/rmf          ; Assemble each module to relocatable object
z80asm main/rmf
...
link bbcbasic=dist,main,exec,eval,asmb,math,hook,cmos,/p:4B00,data
hexbin bbcbasic          ; Convert to binary
```

Key characteristics:
- Each module assembled separately to relocatable object files
- Linker combines modules and resolves cross-references
- DATA module placed at separate address (0x4B00) via `/p:4B00` directive
- Final output at ORG 0x0100 (CP/M TPA start)

### Source File Structure

The codebase consists of 11 modules totalling approximately 210KB of source:

| Module    | Purpose                                    | Size  |
|-----------|--------------------------------------------|-------|
| DIST.Z80  | Entry point, CP/M interface, jump table    | 3.9KB |
| MAIN.Z80  | Main interpreter loop, commands            | 31KB  |
| EXEC.Z80  | Statement execution engine                 | 45KB  |
| EVAL.Z80  | Expression evaluation                      | 36KB  |
| MATH.Z80  | Floating-point and maths functions         | 32KB  |
| ASMB.Z80  | Inline assembler                           | 11KB  |
| CMOS.Z80  | CP/M OS interface                          | 22KB  |
| HOOK.Z80  | Stub functions for unsupported features    | 0.6KB |
| ACORN.Z80 | Acorn tube interface (alternative to HOOK) | 9KB   |
| AMOS.Z80  | Acorn MOS interface (alternative to CMOS)  | 16KB  |
| DATA.Z80  | RAM variables and buffers                  | 1.6KB |

Two build targets exist:
- **CP/M**: DIST + MAIN + EXEC + EVAL + ASMB + MATH + HOOK + CMOS + DATA
- **Acorn**: MAIN + EXEC + EVAL + ASMB + MATH + ACORN + AMOS + DATA

## Directive Translation

The CP/M assembler uses different directive names than z88dk:

| CP/M Directive | z88dk Equivalent  | Purpose                           |
|----------------|-------------------|-----------------------------------|
| `GLOBAL`       | `PUBLIC`          | Export symbol from module         |
| `EXTRN`        | `EXTERN`          | Import symbol from another module |
| `TITLE`        | N/A (comment out) | Module title for listings         |
| `ASEG`         | N/A (remove)      | Absolute segment declaration      |

The `convert-source.sh` script automates these conversions:

```bash
./convert-source.sh
```

This copies files from `src/` to `asm/`, renaming from `.Z80` to `.asm` and applying:

- Directive translations (GLOBAL→PUBLIC, EXTRN→EXTERN)
- Comment out ORG and END directives (linker controls placement)
- Convert string quotes (single to double for DEFM)
- Convert character expressions (`'X' AND 1FH` to numeric values)
- Add `INCLUDE "constants.inc"` to each module
- Comment out duplicate EQU definitions (centralised in `constants.inc`)
- Handle special cases (DIST.Z80 ORG 1F0H → DEFS padding)

The original source files are preserved unchanged.

## Build Process

The build mirrors the original CP/M linker-based approach, assembling each module separately and linking them together:

```bash
./convert-source.sh   # Convert source files (run once)
./build.sh cpm        # Build CP/M version
./build.sh acorn      # Build Acorn version
```

**Process:**

1. Each module assembled separately to `.o` object files
2. Linker combines all object files
3. Cross-module references resolved via PUBLIC/EXTERN declarations
4. Output binary at CODE_ORG (0x0100)

## Memory Layout

### CP/M Target

```text
0x0000 - 0x00FF   CP/M zero page (system use)
0x0100 - 0x4AFF   BBC BASIC code (DIST through CMOS)
0x4B00 - 0x4CFF   DATA segment (variables, buffers)
0x4D00 - TPA      User program space
```

The DATA segment must start on a page boundary because ACCS (string accumulator) and BUFFER require 256-byte alignment.

### Acorn Target

```text
0x0100 - 0x4BFF   BBC BASIC code (MAIN through AMOS)
0x4C00 - 0x4DFF   DATA segment
```

## Testing the Build

After building, verify the output:

1. Check binary size matches expectations (~18-20KB for code)
2. Verify entry point at 0x0100 using hexdump
3. Compare with original pre-built binaries in `bin/` directory

## Current Status

The modular build is working. Each module compiles separately, preserving namespace isolation.

```bash
./convert-source.sh   # Convert source files
./build.sh cpm        # Build CP/M version (19568 bytes)
./build.sh acorn      # Build Acorn version (19740 bytes)
```

Note: The DATA segment currently follows code directly instead of being placed at a fixed address (0x4B00 for CP/M, 0x4C00 for Acorn). This results in slightly larger binaries than the reference versions.

## Future Improvements

- Implement proper DATA segment placement using z88dk sections
- Add size comparison reporting
- Automate testing against reference binaries
- Consider creating a BeanZee target configuration

---

## Notes

### Why Not a Monolithic Build?

An include-based approach was initially attempted, where a wrapper file would include all modules in order for single-pass assembly. This failed because the original codebase was designed for modular compilation where each module has its own namespace.

Combining all modules into a single namespace caused approximately 200 duplicate label errors. Labels like `COLD`, `ERROR0`-`ERROR4`, `CLS`, and `CMDTAB` are defined in multiple modules with different implementations. Constants like `BDOS`, `DEL`, and `ESC` also conflicted with labels of the same name in other modules.

Resolving these conflicts would require extensive manual renaming throughout the source files. The modular build approach avoids this by preserving the original namespace isolation.
