
---
title: "[WIP]mlir"
date: 2026-04-13
---

>学习下mlir

# 1. 基本概念

- 树形结构。Op，Region，Block，Op
- 使用基本块参数代替phi
- Operand结构
    1. 操作
    2. 返回值：OpResult
    3. regions
    4. attrDict，属性字典
    5. 参数：OpOperand, 经典的Use结构
- Value是ValueImpl*的包装，type+kind
- Type, TypeStorage* 实际上是AbstractType* = {dialect, interface, typeid,name, subtypes}
- interface vs trait
    - interface想要语义描述和具体Op/dialect解耦, 给pass提供api
        使用主要是 
        ```cpp
        Dialect *dialect = ...;
        if (DialectInlinerInterface *interface = dyn_cast<DialectInlinerInterface>(dialect)) {
        // The dialect has provided an implementation of this interface.
        ...
        }
        ```
    - trait 更加静态，为attrs/ops/types 提供公共信息，比如说side effects
    `Operation *op = ..; if (op->hasTrait<MyTrait>()) ...`

# 2. 添加dialect
# 3. 添加pass
# 4. pattern rewriter
# 5. converter

# ref
- https://github.com/KEKE046/mlir-tutorial 


