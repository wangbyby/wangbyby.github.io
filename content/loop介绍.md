+++
title = "[WIP]loop 介绍"
date = 2021-05-01T09:19:42+00:00

+++

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

- [Compilers I Chapter 1: Introduction](https://www.doc.ic.ac.uk/~phjk/Compilers/Lectures/pdfs/Ch7-part2-DominatorsAndNaturalLoops.pdf)
- [On loops, dominators, and dominance frontiers (acm.org)](https://dl.acm.org/doi/pdf/10.1145/570886.570887)
- [Microsoft PowerPoint - loopOptimization [Compatibility Mode] (utexas.edu)](https://www.cs.utexas.edu/~pingali/CS375/2010Sp/lectures/LoopOptimizations.pdf)