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

The `convert-source.sh` script automates this conversion:

```bash
./convert-source.sh
```

This copies files from `src/` to `asm/`, renaming from `.Z80` to `.asm` and applying the directive translations. The original source files are preserved.

## Build Approach

The build uses an include-based approach following the pattern used by the Marvin monitor:

```bash
./build.sh cpm
```

**Process:**

1. Wrapper file (cpm.asm or acorn.asm) includes all modules in order
2. Single-pass assembly produces complete binary
3. DATA segment placed via inline ORG directive

This approach is simpler than the original linker-based build, with no need for PUBLIC/EXTERN directives since all symbols are globally visible. It's easier to debug with a single assembly pass.

For an alternative modular build approach that mirrors the original CP/M linker-based process, see [alternative-build-approach.md](alternative-build-approach.md).

## Memory Layout

### CP/M Target

```
0x0000 - 0x00FF   CP/M zero page (system use)
0x0100 - 0x4AFF   BBC BASIC code (DIST through CMOS)
0x4B00 - 0x4CFF   DATA segment (variables, buffers)
0x4D00 - TPA      User program space
```

The DATA segment must start on a page boundary because ACCS (string accumulator) and BUFFER require 256-byte alignment.

### Acorn Target

```
0x0100 - 0x4BFF   BBC BASIC code (MAIN through AMOS)
0x4C00 - 0x4DFF   DATA segment
```

## Known Issues and Considerations

### DATA Segment Placement

The original build places DATA at a specific address using the linker's `/p:` directive. In the include-based approach, we use an inline `ORG 0x4B00` directive. This works but:

- Creates a gap in the binary if code doesn't reach 0x4B00
- May need adjustment if code size changes significantly

### ORG Directives in Modules

Some modules contain their own ORG directives (e.g., DIST.Z80 has `ORG 100H` and `ORG 1F0H`). These work correctly in the include-based approach.

### END Directives

Each module ends with an `END` directive. In z88dk with includes, these should be removed or the assembler may stop processing prematurely. The translation script doesn't handle this automatically.

### Conditional Assembly

The source uses `IF`/`ENDIF` for conditional assembly (e.g., checking code size limits). z88dk supports these but syntax may differ slightly. Manual review recommended.

## Testing the Build

After building, verify the output:

1. Check binary size matches expectations (~18-20KB for code)
2. Verify entry point at 0x0100 using hexdump
3. Compare with original pre-built binaries in `repo/bin/` directory
4. Test on emulator (e.g., RunCPM, MAME CP/M)

## Future Improvements

- Create proper makefile with dependency tracking
- Add size comparison reporting
- Automate testing against reference binaries
- Consider creating a BeanZee target configuration
