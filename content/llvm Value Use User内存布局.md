
>- 起源：工作里用c搓了个ir库，ssa形式，但在实现方面遇到了问题（replaceAllUsesWith) 。所以看看工业级的llvm怎么处理的
>- 参考llvm18版本源码

我的设计：
```c
enum ClassID{
   BasicBlock,
   Instruction,
   ...
};
struct Value{
    char* name;
    ClassID id;
    Type* ty;
    Use* use_list;
};

struct Use{
   Value* user;
   Use* next;
};

struct Instruction{
    Value base;
    Value* arr[];
};

```

Instruction即User，只储存了`Value*`数组
以下面的IR为例：

```c
%add = add %a, %b  
%mul = mul %add, %b
```


>![[static/images/use_graph.png]]

看起来很简单，那实现replaceAllUsesWith是怎么实现呢？
```c
// replace all Use of self to other
// example: 
//   %add = add %a, %b
//   %mul = mul %add, %b
// => after replaceAllUsesWith(%add, %a)
//   %mul = mul %a, %b
void replaceAllUsesWith(Value* self, Value* other) {
	while(NULL != self.use_list){
		Use* iter = self.use_list.pop();
		Value *user = iter.val;
		for(int i =0; i < user.get_operands_num();i++){
			Value* op = user.operand[i];
			if(op == self){
				other.add_use(user);
				user.operand[i] = other;
			}
		}
	}
}

```

这里发现几个问题
1. replace 需要扫描operands
2. 需要注意Use节点内存释放
3. 遇到`%add = add %a, %a` 容易出现double free

----
那llvm如何处理呢？

先看看llvm ir的继承体系:
>https://llvm.org/doxygen/classllvm_1_1Value.html
>
>![[static/images/a63ece927e2f339e157f22cf886cd3d6bcbc8a40_2_690x474.png]]

然后查看源码，看看User实现方式：

>内联User分配，以2为例
>![[static/images/3e1c4416af8a2d18537664396f222e86b1d756d4_2_690x386.jpeg]]

>外挂Usee分配
>![[static/images/b60afe1c4150d5e7b1b71c3ebbf3a428305a103d_2_690x290.png]]


仍以这段代码为例子：
```c
%add = add %a, %b  
%mul = mul %add, %b
```

对应图：
>![[static/images/llvm-ir-use.jpeg]]
>有点复杂的图。。。

对应实现：

> 双链表，头插法插入
>![[static/images/llvm-use-list-impl.png]]

那replaceAllUsesWith实现就比较简单了：
```c
while (UseList) {
  Use &U = *UseList;
  U.set(New);
}
```


----

- branch指令:
![[static/images/llvm-branch.png]]

- phi指令：
![[static/images/llvm-phi.png]]


- switch指令
![[static/images/llvm-switch.png]]

----

绘图：exlicdraw 
![[static/images/llvm_value_use_layout.excalidraw]]