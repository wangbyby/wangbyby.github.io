---
title: "win构建llvm"
---

构建llvm

以win11+git bash为例

1. 配置
```sh
set -x

export COMPILER_DIR=D:/LLVM/bin/ # 替换为一个已有compiler的path
export CC=$COMPILER_DIR/clang.exe
export CXX=$COMPILER_DIR/clang++.exe
export RC_COMPILER=$LLVM_DIR/llvm-rc.exe

mkdir -p build
mkdir -p install

cmake -S ./llvm -B build -G Ninja -DCMAKE_BUILD_TYPE=DEBUG -DLLVM_ENABLE_PROJECTS="clang" -DLLVM_TARGETS_TO_BUILD=X86 -DCMAKE_RC_COMPILER=$RC_COMPILER
```

2. 构建，ninja
一个线程最少4G内存。4线程16G不一定够用。链接很慢。