
"""
* graph coloring based reg alloc
* may have some errors
* some many map here... too complicated!

"""

from collections import defaultdict
from dataclasses import dataclass
import enum
from typing import Dict, List, Optional, Set
from abc import ABC, abstractmethod


class Opcode(enum.Enum):
    ADD = "add"
    SUB = "sub"
    MUL = "mul"
    LOAD = "load"
    STORE = "store"
    MOV = "mov"


uninit_id = -1
uninit_order = -1


class Function:
    def __init__(self, blocks: Optional[List["Block"]] = None):
        if blocks is None:
            blocks = []
        self.blocks: List["Block"] = blocks

    def dump(self) -> None:
        print("function:")

        for i, block in enumerate(self.blocks):
            text = block.dump()
            print(text)

    def numbering(self):
        inst_order = 0
        for i, block in enumerate(self.blocks):
            block.block_id = i

            block.block_order = inst_order
            inst_order += 2
            for inst in block.instructions:
                inst.order = inst_order
                inst_order += 2


class Block:
    def __init__(self, instructions: Optional[List["Instruction"]] = None):
        if instructions is None:
            instructions = []
        self.instructions: List["Instruction"] = instructions
        self.block_id: int = uninit_id

        self.block_order: int = uninit_order

        self.success: List[Block] = []
        self.preds: List[Block] = []

        self.live_in: Set[str] = set()
        self.live_out: Set[str] = set()

    def dump(self) -> str:
        lines = [f"{self.dump_header()}:"]

        live_in = f"live  in: {",".join(self.live_in)}"
        live_out = f"live out: { ",".join(self.live_out)}"

        lines.append(live_in)
        lines.append(live_out)

        if self.block_order != uninit_id:
            s = f"  {self.block_order}:  "
            lines.append(s)

        for inst in self.instructions:
            lines.append(f"  {inst.dump()}")

        return "\n".join(lines)

    def dump_header(self) -> str:
        return f"bb{self.block_id}"


class Instruction:
    def __init__(
        self,
        block: Block,
        opcode: "Opcode",
        outs: Optional[List["Operand"]] = None,
        ins: Optional[List["Operand"]] = None,
    ):
        self.parent: Block = block
        self.opcode: Opcode = opcode

        if outs is None:
            outs = []
        if ins is None:
            ins = []

        self.outs: List["Operand"] = outs
        self.ins: List["Operand"] = ins
        self.order: int = uninit_id

    def dump_with_prefix(self, prefix: str, padding: int, deli: str = " | ") -> str:
        return prefix.ljust(padding) + f"{deli}" + self.dump()

    def dump(self) -> str:
        parts = []

        if self.order is not None:
            parts.append(f"{self.order}: ")

        if self.outs:
            lhs = ", ".join(str(o) for o in self.outs)
            parts.append(f"{lhs} =")

        parts.append(self.opcode.value)

        if self.ins:
            rhs = ", ".join(str(i) for i in self.ins)
            parts.append(rhs)

        return " ".join(parts)

    def uses_phys_reg(self, i: int) -> bool:
        for op in self.ins:
            if isinstance(op, RegOperand) and op.get_reg() == f"r{i}":
                return True
        return False

    def defs_phys_reg(self, r: int) -> bool:
        for op in self.outs:
            if isinstance(op, RegOperand) and op.get_reg() == f"r{r}":
                return True
        return False


class Operand(ABC):
    @abstractmethod
    def __str__(self) -> str: ...

    def is_vreg(self) -> bool:
        return False

    def is_preg(self) -> bool:
        return False


class RegOperand(Operand):
    def __init__(self, name: str):
        self.name = name  # v1 / r3

    def get_reg(self) -> str:
        return self.name

    def is_vreg(self) -> bool:
        return self.name.startswith("v")

    def is_preg(self) -> bool:
        return self.name.startswith("r")

    def __str__(self) -> str:
        return self.name


class ImmOperand(Operand):
    def __init__(self, value: int):
        self.value = value

    def __str__(self) -> str:
        return str(self.value)


class BlockOperand(Operand):
    def __init__(self, label: Block):
        self.label = label  # bb0 / bb1

    def __str__(self) -> str:
        return self.label.dump_header()


class BitSet:
    __slots__ = ("_bits",)

    def __init__(self, bits: int = 0):
        self._bits: int = bits

    # ---------- 基本操作 ----------

    def add(self, i: int) -> None:
        self._bits |= 1 << i

    def remove(self, i: int) -> None:
        self._bits &= ~(1 << i)

    def contains(self, i: int) -> bool:
        return bool(self._bits & (1 << i))

    def empty(self) -> bool:
        return self._bits == 0

    def one_num(self) -> int:
        return self._bits.bit_count()

    def bit_len(self) -> int:
        return self._bits.bit_length()

    def copy(self) -> "BitSet":
        return BitSet(self._bits)

    def is_intersect(self, other: "BitSet") -> bool:
        return (self._bits & other._bits) != 0

    # ---------- 集合运算 ----------

    def union(self, other: "BitSet") -> "BitSet":
        return BitSet(self._bits | other._bits)

    def intersect(self, other: "BitSet") -> "BitSet":
        return BitSet(self._bits & other._bits)

    def difference(self, other: "BitSet") -> "BitSet":
        return BitSet(self._bits & ~other._bits)

    # ---------- in-place（数据流分析常用） ----------

    def iunion(self, other: "BitSet") -> None:
        self._bits |= other._bits

    def iintersect(self, other: "BitSet") -> None:
        self._bits &= other._bits

    def idifference(self, other: "BitSet") -> None:
        self._bits &= ~other._bits

    # ---------- 遍历 set bits ----------

    def elements(self):
        x = self._bits
        while x:
            lsb = x & -x
            i = lsb.bit_length() - 1
            yield i
            x &= x - 1

    # ---------- Python 友好接口 ----------

    def __or__(self, other: "BitSet") -> "BitSet":
        return self.union(other)

    def __and__(self, other: "BitSet") -> "BitSet":
        return self.intersect(other)

    def __sub__(self, other: "BitSet") -> "BitSet":
        return self.difference(other)

    def __eq__(self, other) -> bool:
        return isinstance(other, BitSet) and self._bits == other._bits

    def __bool__(self) -> bool:
        return self._bits != 0

    def __repr__(self) -> str:
        elems = list(self.elements())
        return f"BitSet({elems})"


class Liveness:
    def __init__(self) -> None:
        pass

    def calc(self, func: Function):
        for block in func.blocks:
            block.live_in = set()
            block.live_out = set()
        changed = True
        while changed:
            changed = False
            for block in reversed(func.blocks):  # 逆序更快收敛
                old_in = block.live_in.copy()
                old_out = block.live_out.copy()

                # live_out = union of live_in of successors
                block.live_out = set()
                for succ in block.success:
                    block.live_out |= succ.live_in

                # live_in = uses + (live_out - defs)
                uses = set(
                    op.get_reg()
                    for inst in block.instructions
                    for op in inst.ins
                    if isinstance(op, RegOperand) and op.is_vreg()
                )
                defs = set(
                    op.get_reg()
                    for inst in block.instructions
                    for op in inst.outs
                    if isinstance(op, RegOperand) and op.is_vreg()
                )
                block.live_in = uses | (block.live_out - defs)

                if block.live_in != old_in or block.live_out != old_out:
                    changed = True


class ReachingDef:
    def __init__(self, func: Function) -> None:
        self.func = func

        self.def_num = 0
        self.inst_to_defID: dict[tuple[Instruction, str], int] = {}
        self.def_reg: list[str] = []

        self._number_defs()

        self.gen: dict[Block, BitSet] = {}
        self.kill: dict[Block, BitSet] = {}
        self.rd_in: dict[Block, BitSet] = {}
        self.rd_out: dict[Block, BitSet] = {}

        # def_ID -> (Instruction, vreg)
        self.defID_to_inst: Dict[int, tuple[Instruction, str]] = {}
        for (inst, reg), did in self.inst_to_defID.items():
            self.defID_to_inst[did] = (inst, reg)

    def _number_defs(self):
        for block in self.func.blocks:
            for inst in block.instructions:
                for op in inst.outs:
                    if isinstance(op, RegOperand) and op.is_vreg():
                        self.inst_to_defID[(inst, op.get_reg())] = self.def_num
                        self.def_reg.append(op.get_reg())
                        self.def_num += 1

    def debug_bitset(self, bs: BitSet) -> str:
        """
        bs: BitSet of def IDs
        """
        elems = []
        for did in bs.elements():
            elems.append(f"d{did}:{self.def_reg[did]}")
        return "{" + ", ".join(elems) + "}"

    def dump_defs(self):
        print("==== Reaching Definitions: Def ID Mapping ====")
        for bb in self.func.blocks:
            for inst in bb.instructions:
                prefix = []
                for out in inst.outs:
                    if isinstance(out, RegOperand) and out.is_vreg():
                        d = self.inst_to_defID[(inst, out.get_reg())]
                        prefix.append(f"d{d}")
                s = f"{",".join(prefix)}"
                print(inst.dump_with_prefix(s, 8))
        print()

    def dump_inst_rd(self):
        print("==== Instruction-level RD in ====")

        for bb in self.func.blocks:
            inst_rd = self.get_inst_rd_in_Block(bb)
            for inst in bb.instructions:
                rd = inst_rd[inst]
                print(inst.dump_with_prefix(f"{self.debug_bitset(rd)}", 16))
        print()

    def _build_gen_kill(self):
        for block in self.func.blocks:
            gen = BitSet()
            kill = BitSet()

            seen: set[str] = set()

            # 倒序扫描，保证只保留最后一次定义
            for inst in reversed(block.instructions):
                for op in inst.outs:
                    if isinstance(op, RegOperand) and op.is_vreg():
                        reg = op.get_reg()
                        did = self.inst_to_defID[(inst, reg)]

                        if reg not in seen:
                            gen.add(did)
                            seen.add(reg)

            # kill = 所有定义同一 reg 的 def
            for did, reg in enumerate(self.def_reg):
                if reg in seen:
                    kill.add(did)

            # gen ⊆ kill，应移除
            kill.idifference(gen)

            self.gen[block] = gen
            self.kill[block] = kill

    def solve(self):
        self._build_gen_kill()

        for block in self.func.blocks:
            self.rd_in[block] = BitSet()
            self.rd_out[block] = BitSet()

        changed = True
        while changed:
            changed = False

            for block in self.func.blocks:
                new_in = BitSet()
                for pred in block.preds:
                    new_in.iunion(self.rd_out[pred])

                new_out = self.gen[block].union(new_in.difference(self.kill[block]))

                if new_in != self.rd_in[block] or new_out != self.rd_out[block]:
                    self.rd_in[block] = new_in
                    self.rd_out[block] = new_out
                    changed = True

    def get_inst_rd_in_Block(self, block: Block) -> Dict[Instruction, BitSet]:
        cur = self.rd_in[block].copy()

        result = {}

        for inst in block.instructions:
            result[inst] = cur.copy()

            # kill + gen
            for op in inst.outs:
                if isinstance(op, RegOperand) and op.is_vreg():
                    reg = op.get_reg()

                    # kill same-reg defs
                    for did, r in enumerate(self.def_reg):
                        if r == reg:
                            cur.remove(did)

                    cur.add(self.inst_to_defID[(inst, reg)])

        return result

    def get_inst_rd_in(self, inst: Instruction) -> BitSet:
        a = self.get_inst_rd_in_Block(inst.parent)
        return a[inst]

    def get_inst_rd_out(self, inst: Instruction) -> BitSet:
        block = inst.parent
        inst_rd = self.get_inst_rd_in_Block(block)

        rd_in = inst_rd[inst]
        rd_out = rd_in.copy()

        # 应用 inst 的 kill + gen
        for op in inst.outs:
            if isinstance(op, RegOperand) and op.is_vreg():
                reg = op.get_reg()

                # kill: 所有同一 reg 的 defs
                for did, r in enumerate(self.def_reg):
                    if r == reg:
                        rd_out.remove(did)

                # gen: 当前 def
                rd_out.add(self.inst_to_defID[(inst, reg)])

        return rd_out


@dataclass(frozen=True)
class InstPoint:
    block_id: int
    order: int

    def __repr__(self) -> str:
        return f"InstPoint(bb{self.block_id}, {self.order})"

    def __lt__(self, other: "InstPoint") -> bool:
        if self.block_id != other.block_id:
            return self.block_id < other.block_id
        return self.order < other.order


# one def to some uses
class DUChain:
    def __init__(self, reg: str, def_id: int):
        self.reg: str = reg
        self.def_id = def_id
        self.uses: set[InstPoint] = set()

    def add_use(self, use_inst_id: InstPoint):
        self.uses.add(use_inst_id)

    def __repr__(self):
        return f"DUChain(reg={self.reg}, def_id={self.def_id}, uses={list(self.uses)})"


class Web:
    def __init__(self, du: DUChain):
        self.reg: str = du.reg
        self.defs: BitSet = BitSet()
        self.defs.add(du.def_id)

        self.uses: set[InstPoint] = du.uses

    def __repr__(self) -> str:
        return f"Web({self.reg}, defs={list(self.defs.elements())}, uses={list(self.uses)})"

    # inplace union into self
    def iunion(self, other: "Web") -> None:
        assert self.reg == other.reg
        self.defs.iunion(other.defs)
        self.uses |= other.uses

    def can_union(self, other: "Web") -> bool:
        """
        Briggs-style web merging:
        same reg + overlapping live definitions
        """
        if self.reg != other.reg:
            return False
        return not self.uses.isdisjoint(other.uses)


class WebContainers:
    def __init__(self, func: Function, rd: ReachingDef):
        self.webs: List[Web] = []
        self.func = func
        self.rd = rd

    def build_du_chains(self) -> list[DUChain]:
        du_map: dict[int, DUChain] = {}

        for block in self.func.blocks:
            inst_rd = self.rd.get_inst_rd_in_Block(block)

            for inst in block.instructions:
                rd_in: BitSet = inst_rd[inst]

                for op in inst.ins:
                    if not (isinstance(op, RegOperand) and op.is_vreg()):
                        continue

                    reg = op.get_reg()

                    for def_id in rd_in.elements():
                        def_inst, def_reg = self.rd.defID_to_inst[def_id]
                        if def_reg != reg:
                            continue

                        du = du_map.get(def_id)
                        if du is None:
                            du = DUChain(reg, def_id)
                            du_map[def_id] = du

                        du.add_use(InstPoint(block.block_id, inst.order))  # 可选
                for op in inst.outs:
                    if not (isinstance(op, RegOperand) and op.is_vreg()):
                        continue

                    reg = op.get_reg()
                    def_id = self.rd.inst_to_defID[(inst, reg)]
                    du = du_map.get(def_id)
                    if du is None:
                        du = DUChain(reg, def_id)
                        du_map[def_id] = du

        return list(du_map.values())

    def build_webs(self):
        du_chains = self.build_du_chains()

        print("DuChain:")
        print(du_chains)

        self.webs = [Web(du) for du in du_chains]

        print(f"==== Webs init with num {len(self.webs)} ====")
        for i, w in enumerate(self.webs):
            print(f"{i}: {w}")

        changed = True
        while changed:
            changed = False
            to_remove: set[int] = set()

            for i in range(len(self.webs)):
                if i in to_remove:
                    continue

                wa = self.webs[i]

                for j in range(i + 1, len(self.webs)):
                    if j in to_remove:
                        continue

                    wb = self.webs[j]

                    if wa.can_union(wb):
                        wa.iunion(wb)
                        to_remove.add(j)
                        changed = True

            self.webs = [w for idx, w in enumerate(self.webs) if idx not in to_remove]

        print(f"get {len(self.webs)} Webs")
        for i, w in enumerate(self.webs):
            print(f"{i}: {w}")


class AdjMatrix:
    """
    下三角邻接矩阵：
      matrix[i][j]  (i > j) 表示 i 与 j 是否冲突, 冲突为True
    """

    def __init__(self, num: int, num_pregs: int):
        assert 0 <= num_pregs <= num

        self.num_total = num
        self.num_pregs = num_pregs

        # 下三角矩阵：第 i 行长度为 i
        self.mat: list[list[bool]] = [[False] * i for i in range(num)]

        self._init_physical_conflicts()

    def _init_physical_conflicts(self) -> None:
        """
        初始化物理寄存器之间的完全冲突
        """
        for i in range(self.num_pregs):
            for j in range(i):
                self.mat[i][j] = True

    # ---------- 基本操作 ----------

    def _idx(self, a: int, b: int) -> tuple[int, int]:
        if a == b:
            raise ValueError("self-edge is not stored")
        return (a, b) if a > b else (b, a)

    def add_edge(self, a: int, b: int) -> None:
        i, j = self._idx(a, b)
        self.mat[i][j] = True

    def has_edge(self, a: int, b: int) -> bool:
        i, j = self._idx(a, b)
        return self.mat[i][j]

    def neighbors(self, v: int) -> set[int]:
        """
        返回与 v 冲突的所有节点
        """
        result = set()

        # 下方
        for j in range(v):
            if self.mat[v][j]:
                result.add(j)

        # 上方
        for i in range(v + 1, self.num_total):
            if self.mat[i][v]:
                result.add(i)

        return result

    def __repr__(self) -> str:
        # ---------- 节点名 ----------
        names: list[str] = []

        # 物理寄存器
        for i in range(self.num_pregs):
            names.append(f"r{i}")

        # web
        for i in range(self.num_pregs, self.num_total):
            names.append(f"web{i - self.num_pregs}")

        # ---------- 表头 ----------
        col_width = max(len(n) for n in names) + 2

        def fmt(s: str) -> str:
            return s.ljust(col_width)

        lines: list[str] = [
            f"Adj Matrix: K={self.num_pregs}, web num={self.num_total-self.num_pregs}"
        ]

        header = fmt("") + "".join(fmt(n) for n in names)
        lines.append(header)

        # ---------- 每一行 ----------
        for i in range(self.num_total):
            row = [fmt(names[i])]

            for j in range(self.num_total):
                if j >= i:
                    # 上三角 + 对角线
                    cell = "-" if j == i else ""
                else:
                    cell = "T" if self.mat[i][j] else "F"

                row.append(fmt(cell))

            lines.append("".join(row))

        return "\n".join(lines)


class InterferenceGraph:
    def __init__(self, webs: WebContainers, func: Function, K: int) -> None:
        self.wc = webs
        self.func = func
        self.K = K
        self.colors: dict[Web, int] = {}  # web -> reg idx

    def build_adjM(self):
        num_webs = len(self.wc.webs)
        num_total = num_webs + self.K

        # 1. 初始化邻接矩阵
        self.adjM = AdjMatrix(num_total, self.K)

        for i in range(self.K, num_total):
            web_i = self.wc.webs[i - self.K]
            for j in range(0, self.K):
                if self._interfere(web_i, j):
                    self.adjM.add_edge(i, j)

            for j in range(self.K, i):
                web_j = self.wc.webs[j - self.K]
                if self._live_at(web_i, web_j, self.wc.rd):
                    self.adjM.add_edge(i, j)

        print(self.adjM)

    def _interfere(self, w: Web, j: int) -> bool:
        rd = self.wc.rd

        for bb in self.func.blocks:
            inst_rd = self.wc.rd.get_inst_rd_in_Block(bb)
            for inst in bb.instructions:
                if not (inst.uses_phys_reg(j) or inst.defs_phys_reg(j)):
                    continue
                inst_rd_in = inst_rd[inst]

                # 如果 web 在该点 live，则干涉
                if inst_rd_in.is_intersect(w.defs):
                    return True

        return False

    def _live_at(self, wa: Web, wb: Web, rd: ReachingDef) -> bool:
        """
        bitset-based interference test
        """
        # 不同寄存器类别（例如 future 扩展）可以在这里提前剪枝
        if wa is wb:
            return False

        self.inst_rd_in: Dict[Instruction, BitSet] = {}

        for def_b in wb.defs.elements():
            # from def_b to inst
            (inst, _) = rd.defID_to_inst[def_b]
            # inst to reaching def live in
            inst_rd_bb = self.wc.rd.get_inst_rd_in_Block(inst.parent)

            inst_rd_in: BitSet = inst_rd_bb[inst]
            if inst_rd_in.is_intersect(wa.defs):
                return True

        return False

    def KColoring(self):
        assert self.adjM is not None

        K = self.K
        num = self.adjM.num_total

        # ---------- 预着色 ----------
        color: dict[int, int] = {}
        for r in range(K):
            color[r] = r

        # ---------- simplify ----------
        stack: list[int] = []
        removed: set[int] = set()

        # 只处理 web 节点
        worklist = set(range(K, num))

        while worklist:
            progress = False

            for v in list(worklist):
                # 计算当前度数（忽略已移除节点）
                degree = sum(1 for n in self.adjM.neighbors(v) if n not in removed)

                if degree < K:
                    stack.append(v)
                    removed.add(v)
                    worklist.remove(v)
                    progress = True
                    break

            if not progress:
                # ❗ 当前实现不做 spill，直接报错
                raise RuntimeError("spill required (not implemented)")

        # ---------- select ----------
        while stack:
            v = stack.pop()

            used = set()
            for n in self.adjM.neighbors(v):
                if n in color:
                    used.add(color[n])

            for c in range(K):
                if c not in used:
                    color[v] = c
                    break
            else:
                raise RuntimeError("spill required during select")

        # ---------- 保存结果 ----------
        self.colors.clear()
        for node_idx, c in color.items():
            if node_idx >= self.K:
                web = self.wc.webs[node_idx - self.K]
                self.colors[web] = c

        print("==== Color ====")
        print(self.colors)


class RegRewrite:
    def __init__(
        self,
        func: Function,
        webs: WebContainers,
        colors: dict[Web, int],
    ) -> None:
        self.func = func
        self.webs = webs
        self.colors = colors

    def _color_to_phys(self, color: int) -> str:
        return f"r{color}"

    def run(self) -> None:
        for block in self.func.blocks:
            for inst in block.instructions:

                # rewrite uses
                for op in inst.ins:
                    self._rewrite_operand(op, inst, False)

                # rewrite defs
                for op in inst.outs:
                    self._rewrite_operand(op, inst, True)

    def _rewrite_operand(
        self, op: Operand, inst: Instruction, reg_in_out_op: bool
    ) -> None:
        if not isinstance(op, RegOperand):
            return
        if not op.is_vreg():
            return

        # 找到所属 web
        web = self._find_web(op.get_reg(), inst, reg_in_out_op)
        if web is None:
            raise RuntimeError(f"no web found for {op.get_reg()} at {inst.dump()}")

        color = self.colors.get(web)
        if color is None:
            raise RuntimeError(f"no color for web {web}")

        # rewrite
        op.name = self._color_to_phys(color)

    def _find_web(
        self, reg: str, inst: Instruction, reg_in_out_op: bool
    ) -> Optional[Web]:

        if reg_in_out_op:
            def_id = self.webs.rd.inst_to_defID[(inst, reg)]
            for w in self.webs.webs:
                if w.defs.contains(def_id):
                    return w
        else:
            # reg in use
            for w in self.webs.webs:
                if w.reg != reg:
                    continue
                for u in w.uses:
                    if u.order == inst.order:
                        return w
        return None


class GraphRegAlloc:
    def __init__(self) -> None:
        pass

    def allocReg(self, func: Function, K: int):
        rd = ReachingDef(func)
        rd.dump_defs()
        rd.solve()
        rd.dump_inst_rd()

        webs = WebContainers(func, rd)
        webs.build_webs()

        ig = InterferenceGraph(webs, func, K)
        ig.build_adjM()

        ig.KColoring()

        RegRewrite(func, webs, ig.colors).run()


def gen_test_case1() -> Function:
    f = Function()

    blk = Block()

    # v1 = ADD r1, r2
    inst1 = Instruction(
        blk,
        opcode=Opcode.ADD,
        outs=[RegOperand("v1")],
        ins=[RegOperand("r1"), RegOperand("r2")],
    )

    # v2 = ADD v1, r2
    inst2 = Instruction(
        blk,
        opcode=Opcode.ADD,
        outs=[RegOperand("v2")],
        ins=[RegOperand("v1"), RegOperand("r2")],
    )

    # v3 = SUB r1, v2
    inst3 = Instruction(
        blk,
        opcode=Opcode.SUB,
        outs=[RegOperand("v3")],
        ins=[RegOperand("r1"), RegOperand("v2")],
    )

    blk.instructions.extend([inst1, inst2, inst3])
    f.blocks.append(blk)

    return f


f = gen_test_case1()
f.numbering()

f.dump()

alloc = GraphRegAlloc()

alloc.allocReg(f, 3)

f.dump()

# G.J. Chaitin. Register Allocation and Spilling via Graph Coloring. In SIGPLAN82, 1982.
# Preston Briggs, Keith D. Cooper, and Linda Torczon. 1994. Improvements to graph coloring register allocation. ACM Trans. Program. Lang. Syst. 16, 3 (May 1994), 428–455. https://doi.org/10.1145/177492.177575
