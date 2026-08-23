# Zui Linux host provenance

- Target: Linux x86-64
- Source: `native/` in this repository
- Framework version: Zui 0.1.0
- Compiler: GNU C++ 16.2.1
- Qt: 6.11.2
- Build type: CMake `Release`

The binary is reproducible from the checked-in C++ sources with:

```bash
cmake -S native -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
```
