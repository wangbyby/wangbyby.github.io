---
title: "loop 介绍"
date: 2025-10-10
---

循环，重要性不必多说。

llvm与循环相关的优化有很多：

>- loop unroll and jam : 循环展开+ 合并
>- loop unroll
>- SCEV
>- loop invariant code motion
>- loop interchange
>- loop rotation
>- loop splitting
>- loop fusion
>- loop unswitching
>- loop vectorization
>....


- 从非结构化的CFG中识别loop：
- 识别循环迭代变量

1. Loop 定义

A loop in a control flow graph is a set of nodes S including a header node h, with the following properties:
- From any node in S there is a path leading to h 
- There is a path from h to any node in S
- There is no edge from any node outside S to any node in S other than h
1. back edge
A control flow graph edge from a node n to a node h that dominates n is called a back edge.
1. natural loop
The natural loop of a backedge (n,h), where h dominates n, is 
	• the set of nodes x such that h dominates x and 
	• there is a path from x to n not containing h. 
	The header of this loop will be h
	Each back-edge has a corresponding natural loop

1. nested loop
Suppose: 
	– A and B are loops with headers a and b, such that a != b, and b is in A 
Then 
	– The nodes of B must be a proper subset of the nodes of A 
	– We say that loop B is nested within A 
	– B is the inner loop




----

# loop识别
假设已经有domtree。
根据loop的定义，从遍历domtree开始构建loop。

用后序方式遍历domtree，即先识别内层loop，然后识别外层loop。

```cpp

void initLoopInfo(){
	stack = [root];
	while(stack.size()){

		auto*top = stack.back();

		if( !all_children_visited(top) ){
			for c in top.children(){
				stack.push(c)
			}
		}else{
			stack.pop();
			
			// 1. find back edge
			backedgs = []
			for pred in top.getBlock().pred(){
				if( top.doms( pred ) ){
					backedgs.push(pred)
				}
			}
			if (pred.size()){
				loop = createLoop()
				discoverLoop(loop, backedgs)
			}
		}
	}
}

// 有回边，loop header可以查找循环体了。
// 寻找backedges的前驱即可。
void discoverLoop(loop, backedgs){

	while(backedgs.size()){
		auto* n = backedgs.back();
		backedgs.pop_back();

		sub_loop = info.get(n)
		if(sub_loop == nullptr){
			if(!loop.getHeader().dom(n)){
				continue
			}
			loop.add(n)
			for p in n.pred(){
				backedgs.push(p)
			}
		}else{
			// 有内层循环了
			sub = sub_loop->getOuterMostLoop()
			loop.add_sub(sub)

			n = sub.getHeader()
			// 不处理sub对应的所有block
			for p in n.preds(){
				if( getLoop(p) != sub ){
					backedgs.push(p)
				}
			}
		}

	}
}

```

-----

- [Compilers I Chapter 1: Introduction](https://www.doc.ic.ac.uk/~phjk/Compilers/Lectures/pdfs/Ch7-part2-DominatorsAndNaturalLoops.pdf)
- [On loops, dominators, and dominance frontiers (acm.org)](https://dl.acm.org/doi/pdf/10.1145/570886.570887)
- [Microsoft PowerPoint - loopOptimization [Compatibility Mode] (utexas.edu)](https://www.cs.utexas.edu/~pingali/CS375/2010Sp/lectures/LoopOptimizations.pdf)