---
title: "SCCP"
date: 2025-9-20

---

稀疏条件常量传播

核心是格，从def到use的传播。

有Top，Const，Bottom三类，Const其实有无穷个状态。
状态转移就是从Top 到 Const/Bottom

然后定义状态转移函数meet:
- meet(any, Top) = any
- meet(any, Bottom) = Bottom
- meet(Ci, Cj) = Ci if i==j
- meet(Ci, Cj) = Bottom if i!=j

定义evalExpr函数(不处理phi)
    - 如果操作数有Bottom， 结果是Bottom
    - 如果都是常数，计算
    - 返回Bottom


```txt

bool sccp(func){
    edgeList: vector<(BB, BB) > = [] 
    instList: vector<inst> = []
    lattice_map = {}

    edge_visited : set<(BB,BB)> = {}

    // init

    edgeList.push( null, entry )

    for arg in func.getArgs(){
        lattice_map[arg] = Bottom
    }
    for bb in func{
        lattice_map[bb] = Top
        for inst in bb{
            lattice_map[inst]  = Top
        }
    }

    while(edgeList.size() || instList.size()){
        while(instList.size() )
        {
            inst = instList.pop()
            if( is_phi(inst) ){
                visit_phi(inst)
                continue;
            }
            visit_inst(inst)
        }
        while(edgeList.size()){
            (from, to) =  edgeList.pop()

            if edge_visited.contains(from, to){
                continue;
            }
            edge_visited.inset(from,to)
            for inst in to {
                if(inst.isPhi()){
                    visit_phi(inst)
                }else{
                    visit_inst(inst)
                }
            }
        }
    }

    remove all the inst with Top lattice 
}



void visit_phi(PhiNode* phi){
    auto old = lattice_map.get(phi)

    auto (v1, bb1) = phi.incomings().begin()
    new_cell = Top    
    if edge_visited.contains(bb1, phi->getParent()) {
        new_cell = lattice_map.get(v1)
    }

    for (v, bb) in phi.incomings().else(){
        celli = Top
        if(edge_visited.contains(bb, phi->getParent()) ){
            celli =  lattice_map.get(v)
            new_cell = meet(new_cell, celli)
        }
    }
     
}

void visit_inst(inst){
    old = lattice_map.get(inst)
    switch inst.kind(){
        case BinOp:{
            a = lattice_map.get(inst.getLHS())
            b = lattice_map.get(inst.getRHS())
            new_cell = eval(a,b, inst)
            if new_cell != old {
                lattice_map[inst] = new_cell
                for u in inst.getUsers(){
                    instList.push(u)
                }
            }
            break;
        }
        case UnaryOp:{
            a = lattice_map.get(inst.getOp())
            res = evalExpr(a)
            if( a != old ){
                lattice_map[inst] = a
                for u in inst.getUsers(){
                    instList.push(u)
                }
            }
            break;
        }
        case Branch {
            auto succ = inst.getSucc()
            for i in succ{
                if edge_visited.contains(inst.getParent(), i){
                    continue;
                }
                edgeList.push(inst.getParent(), i)
                
                for phi in i.phis(){
                    visit_phi(phi)
                }
            }
        }
    }
}

```


考虑下 
bb:
    a = phi(0, b)
    b = a + 1
    jmp bb


最开始 a:T, b:T
然后a被标记为C(0), b也是C(1)
然后a = meet(C(0), C(1)) = Bottom, b: Bottom


- https://dl.acm.org/doi/pdf/10.1145/103135.103136
- https://karkare.github.io/cs738/lecturenotes/11CondConstPropSlides.pdf
