
> 寄存器分配简介

## 前置技术 Liveness Analysis， Live Interval

### Liveness Analysis

经典的数据流分析

```txt

live_out[b] = ⋃ (live_in[s] for s ∈ succ(b))
live_in[b]  = use[b] ∪ (live_out[b] − def[b])

```



# 全局的图着色

```txt

fn alloc_reg(){
    bool success = false;
    do{
        bool coalesce = false;
        do{
            make_web()
            build_adj_matrix()
            coalesce = coalesce_regs()
        }while(!coalesce);

        build_adj_list()
        compute_spill_costs()
        prune_graph()
        success = assign_regs()
        if(success){
            modify_code()
        }else{
            gen_spill_code()
        }

    }while(success);
}

```