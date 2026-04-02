---
title: "inline asm"
---

```c
asm volatile (
    "asm template"
    : output_operands        // ← 第一个冒号后
    : input_operands         // ← 第二个冒号后
    : clobbers               // ← 第三个冒号后
);

```


example:
```c
#include <stdint.h>

__attribute__((noinline))
int mul_add(
    int a, int b, int c,
    int *sum,
    int *acc)
{
    asm volatile (
        "imull  %[b], %[a]\n\t"
        "leal   (%[a], %[c]), %[s]\n\t"
        "addl   %[a], %[acc]\n\t"
        : [a]   "+r"(a),        // read-write
          [s]   "=r"(*sum),     // write-only
          [acc] "+r"(*acc)      // read-write
        : [b]   "r"(b),
          [c]   "r"(c)
        : "cc", "memory"
    );

    return a;
}

```

`%[b]` 是命名参数, 与后面的`[a]`对应。

`"+r"` read-write
`"=r"` write only, 新定义一次，不读旧值
`"r"`  read only，只读

