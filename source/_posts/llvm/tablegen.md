---
title: "tablegen"
date: 2026-04-22
---

# 0

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


# 1. Basic 

基本流程 .td ---> records ---> .inc

## class，def
- class： 和cpp里的类差不多,定义一个类型
- def：一个record实例，类似定义一个cpp变量


```td

class A{
string fromA = "From A";
}
class B {
int num = 10;
}

def X0: A, B{}
def X1: A, B{}

```
结果是：
```td
------------- Classes -----------------
class A {
  string fromA = "From A";
}
class B {
  int num = 10;
}
------------- Defs -----------------
def X0 {        // A B
  string fromA = "From A";
  int num = 10;
}
def X1 {        // A B
  string fromA = "From A";
  int num = 10;
}

```

record的member必须有类型， 内建类型有`int, string, bits, bits<size>, list<type>, dag`，自定义类型就是class了


## multiclass,defm

multiclass就是多个record，而不是类型。defm一次定义多个record。

```td
class Inst<string n, int p>{
    string name = n;
    int price = p;
}

multiclass Bundle<string base> {
def A: Inst<!strconcat(base, "-", "A"),1 >;
def B: Inst<!strconcat(base, "-", "B"),2 >;
def C {
string name = !strconcat(base, "-", "C");
string tag = "special";
}
}

class ShippingPrice<int arg> {
int shippingPrice = arg;
}
defm valuedBundle : Bundle<"valued">, ShippingPrice<5>;

def AnotherRecord {
list<Inst> gifts = [valuedBundleA, valuedBundleB];
list<ShippingPrice> ps = [valuedBundleA, valuedBundleB];
}
```
```td
------------- Classes -----------------
class Inst<string Inst:n = ?, int Inst:p = ?> {
  string name = Inst:n;
  int price = Inst:p;
}
class ShippingPrice<int ShippingPrice:arg = ?> {
  int shippingPrice = ShippingPrice:arg;
}
------------- Defs -----------------
def AnotherRecord {
  list<Inst> gifts = [valuedBundleA, valuedBundleB];
  list<ShippingPrice> ps = [valuedBundleA, valuedBundleB];
}
def valuedBundleA {     // Inst ShippingPrice
  string name = "valued-A";
  int price = 1;
  int shippingPrice = 5;
}
def valuedBundleB {     // Inst ShippingPrice
  string name = "valued-B";
  int price = 2;
  int shippingPrice = 5;
}
def valuedBundleC {     // ShippingPrice
  string name = "valued-C";
  string tag = "special";
  int shippingPrice = 5;
}
```

## let绑定

注意顺序。

```td
class MyClass<string _alias=""> {
string alias = _alias;
}
let alias = "let from out" in
def A: MyClass<> {}
def B: MyClass<> {
let alias = "let from body";
}
def C: MyClass<"from arg">;
let alias = "alias from bigger scope" in {
let alias = "let from out" in
def D: MyClass<"from arg"> {
let alias = "let from body";
}
def E: MyClass<"will be overridden">;
} // end "alias from bigger scope"

def F:MyClass<"from arg">{
    let alias = "let From body";
}
let alias = "let from Out" in
    def G:MyClass<"from arg">{}
```

```td
------------- Classes -----------------
class MyClass<string MyClass:_alias = ""> {
  string alias = MyClass:_alias;
}
------------- Defs -----------------
def A { // MyClass
  string alias = "let from out";
}
def B { // MyClass
  string alias = "let from body";
}
def C { // MyClass
  string alias = "from arg";
}
def D { // MyClass
  string alias = "let from body";
}
def E { // MyClass
  string alias = "alias from bigger scope";
}
def F { // MyClass
  string alias = "let From body";
}
def G { // MyClass
  string alias = "let from Out";
}
```


# 2. Backend

clang-tblgen, llvm-tblgen, mlir-tblgen