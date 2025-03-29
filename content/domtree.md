
+++
title = "dom tree算法介绍"
date = 2021-05-01T09:19:42+00:00

+++



domtree构建算法

# 1. domtree概念介绍

>Dom(b): A node n in the CFG dominates b if n lies on every path from the entry node of the CFG to b.
即Dom(b)是一个集合，根据定义 b in Dom(b)

> immediate dominator: b's immediate dominator is the node n in Dom(b) which is cloest to b.

IDom(b): For a node b, the set IDom(b) contains exactly one node, the immediate dominator of b. If n is b's immediate dominator, then every node in { Dom(b) - b } is also in Dom(n)
即集合IDom(b)只有一个元素。

> 例子：
> ![aa](/static/images/domtree/dt_image.png)
> Dom(b) = {entry, n, b}
> IDom(b) = {n}


# 2. iteratve way 
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

# 3. A Simple, Fast Dominance Algorithm
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

>![alt text](/static/images/domtree/dt_image-2.png)

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
> 原因是对于部分IR来说，basicblock*指针的值就可以被看为一个id。用指针+hashmap的组合更通用。

# 4. Lengauer-Tarjan algorithm

LT算法基于
1. DFS 
2. spanning-tree


基于DFS遍历顺序，LT算法提出了**semidominator**概念，简写为`sdom`(注意和strict dominator区分)。

sdom(w) = semidom(w) = min {v | there is a path v = v0, v1 ,..., vk=w such that vi > w for 1 ≤ i ≤ k-1 }
注：vi>w指的是DFS的order

对于大部分节点来说sdom和idom相同。
故我们需要
1. 计算sdom
2. sdom -> idom


计算sdom：
```c
// step 1
Create a DFS tree T
for v in V
    semi(v) = v

for v in reverse_preorder(V-{entry})
    for q in pred(v)
        z = eval(v, q)
        if semi(z) < semi(v)
            semi(v) = semi(z)

function eval(v, q){
    if v==entry return v;
    while (v < q) {
        q = semi(q)
    }
    return q;
}

```

剩下的sdom-> idom太复杂了，没看懂。。。。

# 5. semi-nca
1. 计算semi dominator
2. 利用NCA算法计算idom

idom(v) = NCA_D( parent_T(v), sdom(v))
D是dom tree， T是spanning tree
算法如下：

```text

1. T = create a DFS tree
2. Calculate semidominator for all vertex
3. D = create_dom_tree().set_root(entry)
4.
for v in preorder_T(V-{r}){
    Ascend the all the path r -> parent_T(v) in D and find the deepest vertex with which number is smaller than or equal to sdom(v). set this vertext as the parent of v in D.
}

```

图例：[参考](https://blog.csdn.net/dashuniuniu/article/details/103462147?spm=1001.2014.3001.5501)

![CFG](/static/images/domtree/dt_cfg.png)

### step 1. Spanning tree

>初始CFG: ![alt text](/static/images/domtree/dt_cfg_dfs.png)
Spanning Tree：![spanning tree](/static/images/domtree/dt_dfs.png)

### step 2. 计算sdom

![alt text](/static/images/domtree/dt_sdom.png)

### step 3. 计算domtree
![alt text](/static/images/domtree/dt_domtree.png)

>![alt text](/static/images/domtree/dt_all.png)

# 6. Dominance Frontiers

SSA-construction中插入phi节点时候会用到。

> define the Dominance Frontiers of a node b as: for a node y, that b dominates a predessor of y but does not strictly dominate y.

例子：
>![alt text](/static/images/domtree/dt_image-3.png)
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

# reference

- https://blog.csdn.net/dashuniuniu/article/details/103462147
(为数不多的CSDN能用上的时候)