+++
title = "tablegen"

+++



1. 构建llvm-tblgen， cmake configure后 `cd build && ninja llvm-tblgen`
2. 查看tblgen对某个td文件的实际命令：在build.ninja里面搜索。
比如说 X86GenAsmMatcher.inc是怎么编译出来的.
```txt

# Custom command for lib\Target\X86\X86GenAsmMatcher.inc

build lib/Target/X86/X86GenAsmMatcher.inc | ${cmake_ninja_workdir}lib/Target/X86/X86GenAsmMatcher.inc: CUSTOM_COMMAND bin/llvm-tblgen.exe bin/llvm-tblgen.exe D$:/Code/llvm-project/llvm/lib/Target/X86/X86.td || bin/llvm-min-tblgen.exe bin/llvm-tblgen.exe include/llvm/CodeGen/vt_gen include/llvm/IR/intrinsics_gen lib/LLVMCodeGenTypes.lib lib/LLVMDemangle.lib lib/LLVMSupport.lib lib/LLVMTableGen.lib lib/Support/BLAKE3/LLVMSupportBlake3 utils/TableGen/Basic/obj.LLVMTableGenBasic utils/TableGen/Common/obj.LLVMTableGenCommon
  COMMAND = C:\WINDOWS\system32\cmd.exe /C "cd /D D:\Code\llvm-project\build\lib\Target\X86 && D:\Code\llvm-project\build\bin\llvm-tblgen.exe -gen-asm-matcher -ID:/Code/llvm-project/llvm/lib/Target/X86 -ID:/Code/llvm-project/build/include -ID:/Code/llvm-project/llvm/include -I D:/Code/llvm-project/llvm/lib/Target D:/Code/llvm-project/llvm/lib/Target/X86/X86.td --write-if-changed -o X86GenAsmMatcher.inc -d X86GenAsmMatcher.inc.d && "D:\Program Files\bin\cmake.exe" -E cmake_transform_depfile Ninja gccdepfile D:/Code/llvm-project/llvm D:/Code/llvm-project/llvm/lib/Target/X86 D:/Code/llvm-project/build D:/Code/llvm-project/build/lib/Target/X86 D:/Code/llvm-project/build/lib/Target/X86/X86GenAsmMatcher.inc.d D:/Code/llvm-project/build/CMakeFiles/d/c78dca343be67cfabd341efa9fb0fbe70dafdeceb081e5cb7ee12866c0dd9055.d"
  DESC = Building X86GenAsmMatcher.inc...
  depfile = CMakeFiles\d\c78dca343be67cfabd341efa9fb0fbe70dafdeceb081e5cb7ee12866c0dd9055.d
  deps = gcc
  restat = 1

```

实际的命令就是`D:/Code/llvm-project/build/bin/llvm-tblgen.exe -gen-asm-matcher -ID:/Code/llvm-project/llvm/lib/Target/X86 -ID:/Code/llvm-project/build/include -ID:/Code/llvm-project/llvm/include -I D:/Code/l
lvm-project/llvm/lib/Target D:/Code/llvm-project/llvm/lib/Target/X86/X86.td --write-if-changed -o X86GenAsmMatcher.inc`. -gen-asm-matcher就是生成具体代码实现。

3. 生成record：删除掉`-gen-asm-matcher`就行。record文件巨大会卡。

