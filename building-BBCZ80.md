# Building BBC BASIC Z80 with z88dk

This document explains the process of adapting R.T. Russell's BBC BASIC Z80 source code to build with z88dk's assembler (z88dk-z80asm) instead of the original CP/M toolchain.

## Background

The original source files use directives and conventions specific to the CP/M assembler toolchain. To cross-compile on Linux or macOS, we need to translate these to z88dk-compatible syntax.

### Original Build Process

The original CP/M build uses `MAKE.SUB` batch files:

```text
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

- **CP/M** (9 modules): DIST + MAIN + EXEC + EVAL + ASMB + MATH + HOOK + CMOS + DATA
- **Acorn** (8 modules): MAIN + EXEC + EVAL + ASMB + MATH + ACORN + AMOS + DATA

## Directive Translation

The CP/M assembler uses different directive names than z88dk:

| CP/M Directive | z88dk Equivalent  | Purpose                           |
|----------------|-------------------|-----------------------------------|
| `GLOBAL`       | `PUBLIC`          | Export symbol from module         |
| `EXTRN`        | `EXTERN`          | Import symbol from another module |
| `TITLE`        | N/A (comment out) | Module title for listings         |
| `ASEG`         | N/A (remove)      | Absolute segment declaration      |

The `convert.sh` script automates these conversions:

```bash
./convert.sh
```

This converts `.Z80` files to `.asm` in `src/`, then copies them to per-target directories (`targets/cpm/`, `targets/acorn/`), applying:

- Directive translations (GLOBAL→PUBLIC, EXTRN→EXTERN)
- Comment out ORG and END directives (linker controls placement)
- Convert string quotes (single to double for DEFM)
- Convert character expressions (`'X' AND 1FH` to numeric values)
- Handle special cases (DIST.Z80 ORG 1F0H → DEFS padding)
- Add SECTION and ORG directives to DATA.asm for fixed placement

Each target directory receives only the modules it needs. EQU definitions are left intact in each module. Since modules are assembled independently, duplicate definitions across modules (e.g., `CR EQU 0DH` in several files) don't conflict.

The original source files are preserved unchanged.

## Build Process

The build mirrors the original CP/M linker-based approach, assembling each module separately and linking them together. Each target has its own self-contained build directory with a standalone build script:

```bash
./convert.sh              # Convert source files (run when the forked source changes)
targets/cpm/build.sh      # Build CP/M version
targets/acorn/build.sh    # Build Acorn version
```

Each target's build.sh has a hardcoded module list and memory layout. Building one target does not affect the other's artefacts.

**Process:**

1. `convert.sh` converts `src/*.Z80` to `src/*.asm`, then copies to `targets/<target>/`
2. Each module assembled separately to `.o` object files
3. Linker combines all object files
4. Cross-module references resolved via PUBLIC/EXTERN declarations
5. DATA section placed at fixed origin via z88dk SECTION directives
6. Code binary padded with zeros to reach DATA origin
7. Output compared against reference binary in `bin/<target>/`

## Memory Layout

### CP/M Target

```text
0x0000 - 0x00FF   CP/M zero page (system use)
0x0100 - 0x4AFF   BBC BASIC code (DIST through CMOS)
0x4B00 - 0x4CFF   DATA segment (variables, buffers)
0x4D00 - TPA      User program space
```

### Acorn Target

```text
0x0100 - 0x4BFF   BBC BASIC code (MAIN through AMOS)
0x4C00 - 0x4DFF   DATA segment
```

The DATA segment must start on a page boundary because ACCS (string accumulator) and BUFFER require 256-byte alignment. The z88dk build achieves this using a `SECTION data` directive with `ORG DATA_ORG`, where DATA_ORG is passed as a define at assembly time (`-DDATA_ORG=0x4B00` for CP/M, `-DDATA_ORG=0x4C00` for Acorn). The linker places the data section at the fixed address, and the build script pads the code binary with zeros to fill the gap between code end and DATA origin.

## Build Verification

Both targets produce byte-for-byte identical binaries compared with the original pre-built reference binaries in `bin/`:

| Target | Binary size | Padding   | Reference match |
|--------|-------------|-----------|-----------------|
| CP/M   | 18,944      | 144 bytes | Identical       |
| Acorn  | 19,200      | 228 bytes | Identical       |

The build scripts automatically compare against the reference binaries and report the result. To clean build artefacts for a target while preserving converted source files:

```bash
targets/cpm/clean.sh      # Clean CP/M build artefacts
targets/acorn/clean.sh    # Clean Acorn build artefacts
./clean-converted.sh      # Clean converted source and derivatives
```

## Repository Structure

```text
src/                      Original .Z80 source files (unchanged)
  *.asm                   Converted source files (generated by convert.sh)
bin/                      Original binaries (unchanged)
  cpm/BBCBASIC.COM        CP/M reference binary
  acorn/BBCBASIC.COM      Acorn reference binary
convert.sh                Source conversion script
clean-converted.sh        Clean converted source and derivatives
targets/
  cpm/                    CP/M target (self-contained)
    build.sh              Build script (9 modules, DATA at 0x4B00)
    clean.sh              Clean build artefacts
    *.asm                 Copied converted source files
    *.o, *.lis            Intermediate artefacts
    bbcbasic.bin/hex/map  Build output
  acorn/                  Acorn target (self-contained)
    build.sh              Build script (8 modules, DATA at 0x4C00)
    clean.sh              Clean build artefacts
    *.asm                 Copied converted source files
    *.o, *.lis            Intermediate artefacts
    bbcbasic.bin/hex/map  Build output
```

The BeanZee target was previously built here but has been moved to the [BeanZeeOS](https://github.com/PainfulDiodes/BeanZeeOS) superproject, which combines BBC BASIC with the Marvin monitor.

## Future Work

- BeanZee platform builds are now handled by [BeanZeeOS](https://github.com/PainfulDiodes/BeanZeeOS)

---

## Notes

### Why Not a Monolithic Build?

An include-based approach was initially attempted, where a wrapper file would include all modules in order for single-pass assembly. This failed because the original codebase was designed for modular compilation where each module has its own namespace.

Combining all modules into a single namespace caused approximately 200 duplicate label errors. Labels like `COLD`, `ERROR0`-`ERROR4`, `CLS`, and `CMDTAB` are defined in multiple modules with different implementations. Constants like `BDOS`, `DEL`, and `ESC` also conflicted with labels of the same name in other modules.

Resolving these conflicts would require extensive manual renaming throughout the source files. The modular build approach avoids this by preserving the original namespace isolation.

### Binary Equality Journey

The initial modular build produced functionally equivalent but not identical binaries. The DATA segment followed code directly instead of being placed at a fixed address, causing all DATA address references to differ by a constant offset (144 bytes for CP/M, 228 bytes for Acorn). 

Analysis confirmed the machine code was identical in both cases -- only embedded DATA addresses differed. Using z88dk's SECTION directives to place DATA at the correct fixed origin, combined with padding and excluding the data section binary, achieved byte-for-byte equality with the reference binaries.
