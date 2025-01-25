
+++
title = "dom tree算法介绍"
 
+++



domtree构建算法

1. domtree概念介绍

>Dom(b): A node n in the CFG dominates b if n lies on every path from the entry node of the CFG to b.
即Dom(b)是一个集合，根据定义 b in Dom(b)

> immediate dominator: b's immediate dominator is the node n in Dom(b) which is cloest to b.

IDom(b): For a node b, the set IDom(b) contains exactly one node, the immediate dominator of b. If n is b's immediate dominator, then every node in { Dom(b) - b } is also in Dom(n)
即集合IDom(b)只有一个元素。

> 例子：
> ![aa](/images/domtree/dt_image.png)
> Dom(b) = {entry, n, b}
> IDom(b) = {n}


2. iteratve way 
可以用前向数据流分析来计算domtree：
对于CFG G = (N, E, n0), N是点集，E是边集，n0是entry

```c
for n in nodes
    Dom[n] = {1...N}
bool changed = true
while (changed){
    changed = false
    for n in reverse_post_order(){
        new_set = {}
        for p in preds(n){
            new_set = new_set ∩ Dom(p)
        }
        new_set = new_set ∪ {n}
    
        if(new_set != Dom[n]){
            Dom[n] = new_set
            changed = true
        }
    }
}

```
这里用reverse post order可以保证n的所有前驱都被处理后，再处理n

3. A Simple, Fast Dominance Algorithm
前面介绍了迭代方式计算domtree算法，简单容易理解，但是效率没那么高(bitvector实现)。 bitvector每次拷贝所有节点信息。那对于稀疏的图来说，效率就难说了，所以`A Simple, Fast Dominance Algorithm`用一种sparse方式去计算domtree。

除了entry节点， Dom(b) = {b} ∪ IDom(b) ∪ IDom(IDom(b)) ∪ .... ∪ {entry}
根据这个特性，我们构建一个dom tree
```c
struct dom_tree_node{
    int order;
    cfg_node* ref;
    struct dom_tree_node *idom;
    vector<struct dom_tree_node* > children;
};

```

>![alt text](/images/domtree/dt_image-2.png)

算法实现：
```c

for (number, node) in post_order(){
    // mapping CFG node to dom tree node
    mapping[node] = create dom_tree_node(node, number) 
}
mapping[entry]->idom = mapping[entry];
changed = true
while (changed){
    changed = false
    for b in reverse_post_order(expect entry){
        new_idom = first (processed) predecessor of b
        for p in other_processors(b) {
            if mapping[p]->idom != NULL {
                new_idom = intersect(mapping[p], new_idom)
            }
        }
        if mapping[b]->idom != new_idom {
            mapping[b]->idom = new_idom
            changed = true
        }
    }
}

// order is the postorder numbers
function intersect(a, b) return dom_tree_node{
    f1 = a;
    f2 = b;
    while(f1 != f2){
        while (f1->order < f2->order ) {
            f1 = f1->idom;
        }
        while (f2->order < f1->order) {
            f2 = f2->idom;
        }
    }
    return f1;
}

```
>Remember that nodes higher in the dominator tree have higher postorder numbers, which is why intersect moves the finger whose value is less than the other finger’s.


> 其实原论文中用的是数组，但我们用树实现。
> 原因是对于部分IR来说，basicblock*指针的值就可以被看为一个id。用链表+hashmap的组合更通用。

4. Lengauer-Tarjan algorithm
TODO
5. semi-nca
TODO
6. Dominance Frontiers

SSA-construction中插入phi节点时候会用到。

> define the Dominance Frontiers of a node b as: for a node y, that b dominates a predessor of y but does not strictly dominate y.

例子：
>![alt text](/images/domtree/dt_image-3.png)
> DF(b) = {y}

```txt
for b in nodes{
    if b.preds().len >= 2 {
        for p in b.preds(){
            runner = mapping[p]
            while runner != mapping[b]->idom {
                add b to runner's dominance frontier set
                runner = runner->idom
            }
        }
    }
}

```
