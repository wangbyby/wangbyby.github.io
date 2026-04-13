---
title: "mlir构建"
date: 2026-04-09
---


以mac air构建为例，耗时26min。
```sh

cmake -G Ninja \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON  \
    -S ./llvm -B build \
    -DCMAKE_BUILD_TYPE=RELWITHDEBINFO \
    -DLLVM_BUILD_EXAMPLES=ON \
    -DLLVM_ENABLE_PROJECTS="mlir" \
    -DLLVM_TARGETS_TO_BUILD="Native;NVPTX" \
    -DLLVM_ENABLE_ASSERTIONS=ON

cd build && ninja

```

- 把mlir当作lib使用
1. 需要构建mlir
2. cmake配置
```sh

set -x

mkdir -p build
cd build
cmake .. -GNinja -DCMAKE_INSTALL_PREFIX=/<mlir_path>/install  -DCMAKE_PREFIX_PATH=../build
ninja

```
