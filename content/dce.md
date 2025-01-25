+++
title = "dead code elimination介绍"

+++


# 死代码消除

在ssa上比较好实现，根据use-def chain传播
如果只是运算指令，且没有users，就是dead的指令。

```c

worklist = {}
for bb in func{
    for inst in bb {
        if (inst not in worklist)
            worklist.push(inst)
    }
}

while(!worklist.empty()) {
    inst = worklist.pop()
    if( inst is pure && inst.num_users()== 0 ){
        // dead instruction
        for(op in inst.operands()){
            inst.remove(op)

            if class(op) == instruction and isDead(op) {
                worklist.insert(op)
            }
        }
    }
}

```
