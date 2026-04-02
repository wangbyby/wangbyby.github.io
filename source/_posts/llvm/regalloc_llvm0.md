
---
title: "llvm寄存器分配0"
---

# 依赖的分析

- value number
- live range(liveness). 这块挺复杂的.
- machine dom tree/machine loop
- block frequency



例子:
```c
// clang a.c -O1 -mllvm -debug-only=regalloc
// x64
extern int foo(int);

int bar(int a, int b) {
    if(a>b) {
       a = foo(a) +  a*b;
         
    }else{
        a = foo(a)*foo(a) + b;
    }
    return a*(b-a);
}

```


输出
```txt

Computing live-in reg-units in ABI blocks.
0B	%bb.0 DIL#0 DIH#0 HDI#0 SIL#0 SIH#0 HSI#0
Created 6 new intervals.
********** INTERVALS **********
DIL [0B,32r:0)[64r,80r:2)[320r,336r:1) 0@0B-phi 1@320r 2@64r
DIH [0B,32r:0)[64r,80r:2)[320r,336r:1) 0@0B-phi 1@320r 2@64r
HDI [0B,32r:0)[64r,80r:2)[320r,336r:1) 0@0B-phi 1@320r 2@64r
SIL [0B,16r:0) 0@0B-phi
SIH [0B,16r:0) 0@0B-phi
HSI [0B,16r:0) 0@0B-phi
%1 [224r,240r:0)[240r,256r:1) 0@224r 1@240r  weight:0.000000e+00
%2 [416r,432r:0)[432r,448r:1) 0@416r 1@432r  weight:0.000000e+00
%3 [480r,544r:0) 0@480r  weight:0.000000e+00
%4 [32r,192r:0)[288B,320r:0) 0@32r  weight:0.000000e+00
%5 [16r,496r:0) 0@16r  weight:0.000000e+00
%6 [112r,224r:0)[288B,400r:0) 0@112r  weight:0.000000e+00
%8 [368r,384r:0) 0@368r  weight:0.000000e+00
%9 [384r,400r:0)[400r,416r:1) 0@384r 1@400r  weight:0.000000e+00
%10 [192r,208r:0)[208r,240r:1) 0@192r 1@208r  weight:0.000000e+00
%11 [496r,512r:0)[512r,528r:1) 0@496r 1@512r  weight:0.000000e+00
%12 [528r,544r:0)[544r,560r:1) 0@528r 1@544r  weight:0.000000e+00
%13 [256r,288B:1)[448r,464B:0)[464B,480r:2) 0@448r 1@256r 2@464B-phi  weight:0.000000e+00
RegMasks: 80r 336r
********** MACHINEINSTRS **********
# Machine code for function bar: NoPHIs, TracksLiveness, TiedOpsRewritten
Function Live Ins: $edi in %4, $esi in %5

0B	bb.0.entry:
	  successors: %bb.1(0x40000000), %bb.2(0x40000000); %bb.1(50.00%), %bb.2(50.00%)
	  liveins: $edi, $esi
	  DBG_VALUE $edi, $noreg, !"a", !DIExpression(), debug-location !22; example.c:0 line no:50
	  DBG_VALUE $esi, $noreg, !"b", !DIExpression(), debug-location !22; example.c:0 line no:50
16B	  %5:gr32 = COPY $esi
32B	  %4:gr32 = COPY $edi
48B	  ADJCALLSTACKDOWN64 0, 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !25; example.c:0
64B	  $edi = COPY %4:gr32, debug-location !25; example.c:0
80B	  CALL64pcrel32 target-flags(x86-plt) @foo, <regmask $bh $bl $bp $bph $bpl $bx $ebp $ebx $hbp $hbx $rbp $rbx $r12 $r13 $r14 $r15 $r12b $r13b $r14b $r15b $r12bh $r13bh $r14bh $r15bh $r12d $r13d $r14d $r15d $r12w $r13w $r14w $r15w $r12wh and 3 more...>, implicit $rsp, implicit $ssp, implicit $edi, implicit-def $rsp, implicit-def $ssp, implicit-def $eax, debug-location !25; example.c:0
96B	  ADJCALLSTACKUP64 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !25; example.c:0
112B	  %6:gr32 = COPY killed $eax, debug-location !25; example.c:0
128B	  CMP32rr %4:gr32, %5:gr32, implicit-def $eflags, debug-location !23; example.c:51:9
144B	  JCC_1 %bb.2, 14, implicit killed $eflags, debug-location !26; example.c:51:9
160B	  JMP_1 %bb.1, debug-location !26; example.c:51:9

176B	bb.1.if.then:
	; predecessors: %bb.0
	  successors: %bb.3(0x80000000); %bb.3(100.00%)

192B	  %10:gr32 = COPY %4:gr32, debug-location !27; example.c:52:23
208B	  %10:gr32 = nsw IMUL32rr %10:gr32(tied-def 0), %5:gr32, implicit-def dead $eflags, debug-location !27; example.c:52:23
224B	  %1:gr32 = COPY %6:gr32, debug-location !29; example.c:52:19
240B	  %1:gr32 = nsw ADD32rr %1:gr32(tied-def 0), %10:gr32, implicit-def dead $eflags, debug-instr-number 2, debug-location !29; example.c:52:19
	  DBG_INSTR_REF !"a", !DIExpression(DW_OP_LLVM_arg, 0), dbg-instr-ref(2, 0), debug-location !22; example.c:0 line no:50
256B	  %13:gr32 = COPY %1:gr32
272B	  JMP_1 %bb.3, debug-location !30; example.c:54:5

288B	bb.2.if.else:
	; predecessors: %bb.0
	  successors: %bb.3(0x80000000); %bb.3(100.00%)

304B	  ADJCALLSTACKDOWN64 0, 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !31; example.c:55:20
320B	  $edi = COPY %4:gr32, debug-location !31; example.c:55:20
336B	  CALL64pcrel32 target-flags(x86-plt) @foo, <regmask $bh $bl $bp $bph $bpl $bx $ebp $ebx $hbp $hbx $rbp $rbx $r12 $r13 $r14 $r15 $r12b $r13b $r14b $r15b $r12bh $r13bh $r14bh $r15bh $r12d $r13d $r14d $r15d $r12w $r13w $r14w $r15w $r12wh and 3 more...>, implicit $rsp, implicit $ssp, implicit $edi, implicit-def $rsp, implicit-def $ssp, implicit-def $eax, debug-location !31; example.c:55:20
352B	  ADJCALLSTACKUP64 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !31; example.c:55:20
368B	  %8:gr32 = COPY killed $eax, debug-location !31; example.c:55:20
384B	  %9:gr32 = COPY %8:gr32, debug-location !33; example.c:55:19
400B	  %9:gr32 = nsw IMUL32rr %9:gr32(tied-def 0), %6:gr32, implicit-def dead $eflags, debug-location !33; example.c:55:19
416B	  %2:gr32 = COPY %9:gr32, debug-location !34; example.c:55:27
432B	  %2:gr32 = nsw ADD32rr %2:gr32(tied-def 0), %5:gr32, implicit-def dead $eflags, debug-instr-number 1, debug-location !34; example.c:55:27
	  DBG_INSTR_REF !"a", !DIExpression(DW_OP_LLVM_arg, 0), dbg-instr-ref(1, 0), debug-location !22; example.c:0 line no:50
448B	  %13:gr32 = COPY %2:gr32

464B	bb.3.if.end:
	; predecessors: %bb.2, %bb.1

480B	  %3:gr32 = COPY %13:gr32, debug-location !25; example.c:0
	  DBG_INSTR_REF !"a", !DIExpression(DW_OP_LLVM_arg, 0), dbg-instr-ref(3, 0), debug-location !22; example.c:0 line no:50
496B	  %11:gr32 = COPY %5:gr32, debug-location !35; example.c:57:16
512B	  %11:gr32 = nsw SUB32rr %11:gr32(tied-def 0), %3:gr32, implicit-def dead $eflags, debug-location !35; example.c:57:16
528B	  %12:gr32 = COPY %11:gr32, debug-location !36; example.c:57:13
544B	  %12:gr32 = nsw IMUL32rr %12:gr32(tied-def 0), %3:gr32, implicit-def dead $eflags, debug-location !36; example.c:57:13
560B	  $eax = COPY %12:gr32, debug-location !37; example.c:57:5
576B	  RET 0, killed $eax, debug-location !37; example.c:57:5

# End machine code for function bar.

********** REGISTER COALESCER **********
********** Function: bar
********** JOINING INTERVALS ***********
entry:
16B	%5:gr32 = COPY $esi
	Considering merging %5 with $esi
	Can only merge into reserved registers.
32B	%4:gr32 = COPY $edi
	Considering merging %4 with $edi
	Can only merge into reserved registers.
64B	$edi = COPY %4:gr32, debug-location !25; example.c:0
	Considering merging %4 with $edi
	Can only merge into reserved registers.
112B	%6:gr32 = COPY killed $eax, debug-location !25; example.c:0
	Considering merging %6 with $eax
	Can only merge into reserved registers.
if.then:
if.else:
320B	$edi = COPY %4:gr32, debug-location !31; example.c:55:20
	Considering merging %4 with $edi
	Can only merge into reserved registers.
368B	%8:gr32 = COPY killed $eax, debug-location !31; example.c:55:20
	Considering merging %8 with $eax
	Can only merge into reserved registers.
if.end:
560B	$eax = COPY %12:gr32, debug-location !37; example.c:57:5
	Considering merging %12 with $eax
	Can only merge into reserved registers.
192B	%10:gr32 = COPY %4:gr32, debug-location !27; example.c:52:23
AllocationOrder(GR32) = [ $eax $ecx $edx $esi $edi $r8d $r9d $r10d $r11d $ebx $ebp $r14d $r15d $r12d $r13d ]
	Considering merging to GR32 with %4 in %10
		RHS = %4 [32r,192r:0)[288B,320r:0) 0@32r  weight:0.000000e+00
		LHS = %10 [192r,208r:0)[208r,240r:1) 0@192r 1@208r  weight:0.000000e+00
		merge %10:0@192r into %4:0@32r --> @32r
		erased:	192r	%10:gr32 = COPY %4:gr32, debug-location !27; example.c:52:23
		updated: 32B	%10:gr32 = COPY $edi
		updated: 64B	$edi = COPY %10:gr32, debug-location !25; example.c:0
		updated: 128B	CMP32rr %10:gr32, %5:gr32, implicit-def $eflags, debug-location !23; example.c:51:9
		updated: 320B	$edi = COPY %10:gr32, debug-location !31; example.c:55:20
	Success: %4 -> %10
	Result = %10 [32r,208r:0)[208r,240r:1)[288B,320r:0) 0@32r 1@208r  weight:0.000000e+00
224B	%1:gr32 = COPY %6:gr32, debug-location !29; example.c:52:19
	Considering merging to GR32 with %6 in %1
		RHS = %6 [112r,224r:0)[288B,400r:0) 0@112r  weight:0.000000e+00
		LHS = %1 [224r,240r:0)[240r,256r:1) 0@224r 1@240r  weight:0.000000e+00
		merge %1:0@224r into %6:0@112r --> @112r
		erased:	224r	%1:gr32 = COPY %6:gr32, debug-location !29; example.c:52:19
		updated: 112B	%1:gr32 = COPY killed $eax, debug-location !25; example.c:0
		updated: 400B	%9:gr32 = nsw IMUL32rr %9:gr32(tied-def 0), %1:gr32, implicit-def dead $eflags, debug-location !33; example.c:55:19
	Success: %6 -> %1
	Result = %1 [112r,240r:0)[240r,256r:1)[288B,400r:0) 0@112r 1@240r  weight:0.000000e+00
256B	%13:gr32 = COPY %1:gr32
	Considering merging to GR32 with %1 in %13
		RHS = %1 [112r,240r:0)[240r,256r:1)[288B,400r:0) 0@112r 1@240r  weight:0.000000e+00
		LHS = %13 [256r,288B:1)[448r,464B:0)[464B,480r:2) 0@448r 1@256r 2@464B-phi  weight:0.000000e+00
		merge %13:1@256r into %1:1@240r --> @240r
		erased:	256r	%13:gr32 = COPY %1:gr32
		updated: 112B	%13:gr32 = COPY killed $eax, debug-location !25; example.c:0
		updated: 240B	%13:gr32 = nsw ADD32rr %13:gr32(tied-def 0), %10:gr32, implicit-def dead $eflags, debug-instr-number 2, debug-location !29; example.c:52:19
		updated: 400B	%9:gr32 = nsw IMUL32rr %9:gr32(tied-def 0), %13:gr32, implicit-def dead $eflags, debug-location !33; example.c:55:19
	Success: %1 -> %13
	Result = %13 [112r,240r:3)[240r,288B:1)[288B,400r:3)[448r,464B:0)[464B,480r:2) 0@448r 1@240r 2@464B-phi 3@112r  weight:0.000000e+00
384B	%9:gr32 = COPY %8:gr32, debug-location !33; example.c:55:19
	Considering merging to GR32 with %8 in %9
		RHS = %8 [368r,384r:0) 0@368r  weight:0.000000e+00
		LHS = %9 [384r,400r:0)[400r,416r:1) 0@384r 1@400r  weight:0.000000e+00
		merge %9:0@384r into %8:0@368r --> @368r
		erased:	384r	%9:gr32 = COPY %8:gr32, debug-location !33; example.c:55:19
		updated: 368B	%9:gr32 = COPY killed $eax, debug-location !31; example.c:55:20
	Success: %8 -> %9
	Result = %9 [368r,400r:0)[400r,416r:1) 0@368r 1@400r  weight:0.000000e+00
416B	%2:gr32 = COPY %9:gr32, debug-location !34; example.c:55:27
	Considering merging to GR32 with %9 in %2
		RHS = %9 [368r,400r:0)[400r,416r:1) 0@368r 1@400r  weight:0.000000e+00
		LHS = %2 [416r,432r:0)[432r,448r:1) 0@416r 1@432r  weight:0.000000e+00
		merge %2:0@416r into %9:1@400r --> @400r
		erased:	416r	%2:gr32 = COPY %9:gr32, debug-location !34; example.c:55:27
		updated: 368B	%2:gr32 = COPY killed $eax, debug-location !31; example.c:55:20
		updated: 400B	%2:gr32 = nsw IMUL32rr %2:gr32(tied-def 0), %13:gr32, implicit-def dead $eflags, debug-location !33; example.c:55:19
	Success: %9 -> %2
	Result = %2 [368r,400r:2)[400r,432r:0)[432r,448r:1) 0@400r 1@432r 2@368r  weight:0.000000e+00
448B	%13:gr32 = COPY %2:gr32
	Considering merging to GR32 with %2 in %13
		RHS = %2 [368r,400r:2)[400r,432r:0)[432r,448r:1) 0@400r 1@432r 2@368r  weight:0.000000e+00
		LHS = %13 [112r,240r:3)[240r,288B:1)[288B,400r:3)[448r,464B:0)[464B,480r:2) 0@448r 1@240r 2@464B-phi 3@112r  weight:0.000000e+00
		merge %13:0@448r into %2:1@432r --> @432r
		interference at %2:2@368r
	Interference!
480B	%3:gr32 = COPY %13:gr32, debug-location !25; example.c:0
	Considering merging to GR32 with %3 in %13
		RHS = %3 [480r,544r:0) 0@480r  weight:0.000000e+00
		LHS = %13 [112r,240r:3)[240r,288B:1)[288B,400r:3)[448r,464B:0)[464B,480r:2) 0@448r 1@240r 2@464B-phi 3@112r  weight:0.000000e+00
		merge %3:0@480r into %13:2@464B --> @464B
		erased:	480r	%3:gr32 = COPY %13:gr32, debug-location !25; example.c:0
		updated: 512B	%11:gr32 = nsw SUB32rr %11:gr32(tied-def 0), %13:gr32, implicit-def dead $eflags, debug-location !35; example.c:57:16
		updated: 544B	%12:gr32 = nsw IMUL32rr %12:gr32(tied-def 0), %13:gr32, implicit-def dead $eflags, debug-location !36; example.c:57:13
	Success: %3 -> %13
	Result = %13 [112r,240r:3)[240r,288B:1)[288B,400r:3)[448r,464B:0)[464B,544r:2) 0@448r 1@240r 2@464B-phi 3@112r  weight:0.000000e+00
496B	%11:gr32 = COPY %5:gr32, debug-location !35; example.c:57:16
	Considering merging to GR32 with %5 in %11
		RHS = %5 [16r,496r:0) 0@16r  weight:0.000000e+00
		LHS = %11 [496r,512r:0)[512r,528r:1) 0@496r 1@512r  weight:0.000000e+00
		merge %11:0@496r into %5:0@16r --> @16r
		erased:	496r	%11:gr32 = COPY %5:gr32, debug-location !35; example.c:57:16
		updated: 16B	%11:gr32 = COPY $esi
		updated: 128B	CMP32rr %10:gr32, %11:gr32, implicit-def $eflags, debug-location !23; example.c:51:9
		updated: 432B	%2:gr32 = nsw ADD32rr %2:gr32(tied-def 0), %11:gr32, implicit-def dead $eflags, debug-instr-number 1, debug-location !34; example.c:55:27
		updated: 208B	%10:gr32 = nsw IMUL32rr %10:gr32(tied-def 0), %11:gr32, implicit-def dead $eflags, debug-location !27; example.c:52:23
	Success: %5 -> %11
	Result = %11 [16r,512r:0)[512r,528r:1) 0@16r 1@512r  weight:0.000000e+00
528B	%12:gr32 = COPY %11:gr32, debug-location !36; example.c:57:13
	Considering merging to GR32 with %11 in %12
		RHS = %11 [16r,512r:0)[512r,528r:1) 0@16r 1@512r  weight:0.000000e+00
		LHS = %12 [528r,544r:0)[544r,560r:1) 0@528r 1@544r  weight:0.000000e+00
		merge %12:0@528r into %11:1@512r --> @512r
		erased:	528r	%12:gr32 = COPY %11:gr32, debug-location !36; example.c:57:13
		updated: 16B	%12:gr32 = COPY $esi
		updated: 512B	%12:gr32 = nsw SUB32rr %12:gr32(tied-def 0), %13:gr32, implicit-def dead $eflags, debug-location !35; example.c:57:16
		updated: 128B	CMP32rr %10:gr32, %12:gr32, implicit-def $eflags, debug-location !23; example.c:51:9
		updated: 432B	%2:gr32 = nsw ADD32rr %2:gr32(tied-def 0), %12:gr32, implicit-def dead $eflags, debug-instr-number 1, debug-location !34; example.c:55:27
		updated: 208B	%10:gr32 = nsw IMUL32rr %10:gr32(tied-def 0), %12:gr32, implicit-def dead $eflags, debug-location !27; example.c:52:23
	Success: %11 -> %12
	Result = %12 [16r,512r:2)[512r,544r:0)[544r,560r:1) 0@512r 1@544r 2@16r  weight:0.000000e+00
64B	$edi = COPY %10:gr32, debug-location !25; example.c:0
	Considering merging %10 with $edi
	Can only merge into reserved registers.
320B	$edi = COPY %10:gr32, debug-location !31; example.c:55:20
	Considering merging %10 with $edi
	Can only merge into reserved registers.
448B	%13:gr32 = COPY %2:gr32
	Considering merging to GR32 with %2 in %13
		RHS = %2 [368r,400r:2)[400r,432r:0)[432r,448r:1) 0@400r 1@432r 2@368r  weight:0.000000e+00
		LHS = %13 [112r,240r:3)[240r,288B:1)[288B,400r:3)[448r,464B:0)[464B,544r:2) 0@448r 1@240r 2@464B-phi 3@112r  weight:0.000000e+00
		merge %13:0@448r into %2:1@432r --> @432r
		interference at %2:2@368r
	Interference!
Trying to inflate 0 regs.
********** INTERVALS **********
DIL [0B,32r:0)[64r,80r:2)[320r,336r:1) 0@0B-phi 1@320r 2@64r
DIH [0B,32r:0)[64r,80r:2)[320r,336r:1) 0@0B-phi 1@320r 2@64r
HDI [0B,32r:0)[64r,80r:2)[320r,336r:1) 0@0B-phi 1@320r 2@64r
SIL [0B,16r:0) 0@0B-phi
SIH [0B,16r:0) 0@0B-phi
HSI [0B,16r:0) 0@0B-phi
%2 [368r,400r:2)[400r,432r:0)[432r,448r:1) 0@400r 1@432r 2@368r  weight:0.000000e+00
%10 [32r,208r:0)[208r,240r:1)[288B,320r:0) 0@32r 1@208r  weight:0.000000e+00
%12 [16r,512r:2)[512r,544r:0)[544r,560r:1) 0@512r 1@544r 2@16r  weight:0.000000e+00
%13 [112r,240r:3)[240r,288B:1)[288B,400r:3)[448r,464B:0)[464B,544r:2) 0@448r 1@240r 2@464B-phi 3@112r  weight:0.000000e+00
RegMasks: 80r 336r
********** MACHINEINSTRS **********
# Machine code for function bar: NoPHIs, TracksLiveness, TiedOpsRewritten
Function Live Ins: $edi in %4, $esi in %5

0B	bb.0.entry:
	  successors: %bb.1(0x40000000), %bb.2(0x40000000); %bb.1(50.00%), %bb.2(50.00%)
	  liveins: $edi, $esi
	  DBG_VALUE $edi, $noreg, !"a", !DIExpression(), debug-location !22; example.c:0 line no:50
	  DBG_VALUE $esi, $noreg, !"b", !DIExpression(), debug-location !22; example.c:0 line no:50
16B	  %12:gr32 = COPY $esi
32B	  %10:gr32 = COPY $edi
48B	  ADJCALLSTACKDOWN64 0, 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !25; example.c:0
64B	  $edi = COPY %10:gr32, debug-location !25; example.c:0
80B	  CALL64pcrel32 target-flags(x86-plt) @foo, <regmask $bh $bl $bp $bph $bpl $bx $ebp $ebx $hbp $hbx $rbp $rbx $r12 $r13 $r14 $r15 $r12b $r13b $r14b $r15b $r12bh $r13bh $r14bh $r15bh $r12d $r13d $r14d $r15d $r12w $r13w $r14w $r15w $r12wh and 3 more...>, implicit $rsp, implicit $ssp, implicit $edi, implicit-def $rsp, implicit-def $ssp, implicit-def $eax, debug-location !25; example.c:0
96B	  ADJCALLSTACKUP64 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !25; example.c:0
112B	  %13:gr32 = COPY killed $eax, debug-location !25; example.c:0
128B	  CMP32rr %10:gr32, %12:gr32, implicit-def $eflags, debug-location !23; example.c:51:9
144B	  JCC_1 %bb.2, 14, implicit killed $eflags, debug-location !26; example.c:51:9
160B	  JMP_1 %bb.1, debug-location !26; example.c:51:9

176B	bb.1.if.then:
	; predecessors: %bb.0
	  successors: %bb.3(0x80000000); %bb.3(100.00%)

208B	  %10:gr32 = nsw IMUL32rr %10:gr32(tied-def 0), %12:gr32, implicit-def dead $eflags, debug-location !27; example.c:52:23
240B	  %13:gr32 = nsw ADD32rr %13:gr32(tied-def 0), %10:gr32, implicit-def dead $eflags, debug-instr-number 2, debug-location !29; example.c:52:19
	  DBG_INSTR_REF !"a", !DIExpression(DW_OP_LLVM_arg, 0), dbg-instr-ref(2, 0), debug-location !22; example.c:0 line no:50
272B	  JMP_1 %bb.3, debug-location !30; example.c:54:5

288B	bb.2.if.else:
	; predecessors: %bb.0
	  successors: %bb.3(0x80000000); %bb.3(100.00%)

304B	  ADJCALLSTACKDOWN64 0, 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !31; example.c:55:20
320B	  $edi = COPY %10:gr32, debug-location !31; example.c:55:20
336B	  CALL64pcrel32 target-flags(x86-plt) @foo, <regmask $bh $bl $bp $bph $bpl $bx $ebp $ebx $hbp $hbx $rbp $rbx $r12 $r13 $r14 $r15 $r12b $r13b $r14b $r15b $r12bh $r13bh $r14bh $r15bh $r12d $r13d $r14d $r15d $r12w $r13w $r14w $r15w $r12wh and 3 more...>, implicit $rsp, implicit $ssp, implicit $edi, implicit-def $rsp, implicit-def $ssp, implicit-def $eax, debug-location !31; example.c:55:20
352B	  ADJCALLSTACKUP64 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !31; example.c:55:20
368B	  %2:gr32 = COPY killed $eax, debug-location !31; example.c:55:20
400B	  %2:gr32 = nsw IMUL32rr %2:gr32(tied-def 0), %13:gr32, implicit-def dead $eflags, debug-location !33; example.c:55:19
432B	  %2:gr32 = nsw ADD32rr %2:gr32(tied-def 0), %12:gr32, implicit-def dead $eflags, debug-instr-number 1, debug-location !34; example.c:55:27
	  DBG_INSTR_REF !"a", !DIExpression(DW_OP_LLVM_arg, 0), dbg-instr-ref(1, 0), debug-location !22; example.c:0 line no:50
448B	  %13:gr32 = COPY %2:gr32

464B	bb.3.if.end:
	; predecessors: %bb.2, %bb.1

	  DBG_INSTR_REF !"a", !DIExpression(DW_OP_LLVM_arg, 0), dbg-instr-ref(3, 0), debug-location !22; example.c:0 line no:50
512B	  %12:gr32 = nsw SUB32rr %12:gr32(tied-def 0), %13:gr32, implicit-def dead $eflags, debug-location !35; example.c:57:16
544B	  %12:gr32 = nsw IMUL32rr %12:gr32(tied-def 0), %13:gr32, implicit-def dead $eflags, debug-location !36; example.c:57:13
560B	  $eax = COPY %12:gr32, debug-location !37; example.c:57:5
576B	  RET 0, killed $eax, debug-location !37; example.c:57:5

# End machine code for function bar.

AllocationOrder(GR64) = [ $rax $rcx $rdx $rsi $rdi $r8 $r9 $r10 $r11 $rbx $r14 $r15 $r12 $r13 $rbp ]
********** GREEDY REGISTER ALLOCATION **********
********** Function: bar
********** GREEDY REGISTER ALLOCATION **********
********** Function: bar
********** INTERVALS **********
DIL [0B,32r:0)[64r,80r:2)[320r,336r:1) 0@0B-phi 1@320r 2@64r
DIH [0B,32r:0)[64r,80r:2)[320r,336r:1) 0@0B-phi 1@320r 2@64r
HDI [0B,32r:0)[64r,80r:2)[320r,336r:1) 0@0B-phi 1@320r 2@64r
SIL [0B,16r:0) 0@0B-phi
SIH [0B,16r:0) 0@0B-phi
HSI [0B,16r:0) 0@0B-phi
%2 [368r,400r:2)[400r,432r:0)[432r,448r:1) 0@400r 1@432r 2@368r  weight:INF
%10 [32r,208r:0)[208r,240r:1)[288B,320r:0) 0@32r 1@208r  weight:7.866044e-03
%12 [16r,512r:2)[512r,544r:0)[544r,560r:1) 0@512r 1@544r 2@16r  weight:8.559322e-03
%13 [112r,240r:3)[240r,288B:1)[288B,400r:3)[448r,464B:0)[464B,544r:2) 0@448r 1@240r 2@464B-phi 3@112r  weight:6.441327e-03
RegMasks: 80r 336r
********** MACHINEINSTRS **********
# Machine code for function bar: NoPHIs, TracksLiveness, TiedOpsRewritten, TracksDebugUserValues
Function Live Ins: $edi in %4, $esi in %5

0B	bb.0.entry:
	  successors: %bb.1(0x40000000), %bb.2(0x40000000); %bb.1(50.00%), %bb.2(50.00%)
	  liveins: $edi, $esi
16B	  %12:gr32 = COPY $esi
32B	  %10:gr32 = COPY $edi
48B	  ADJCALLSTACKDOWN64 0, 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !25; example.c:0
64B	  $edi = COPY %10:gr32, debug-location !25; example.c:0
80B	  CALL64pcrel32 target-flags(x86-plt) @foo, <regmask $bh $bl $bp $bph $bpl $bx $ebp $ebx $hbp $hbx $rbp $rbx $r12 $r13 $r14 $r15 $r12b $r13b $r14b $r15b $r12bh $r13bh $r14bh $r15bh $r12d $r13d $r14d $r15d $r12w $r13w $r14w $r15w $r12wh and 3 more...>, implicit $rsp, implicit $ssp, implicit $edi, implicit-def $rsp, implicit-def $ssp, implicit-def $eax, debug-location !25; example.c:0
96B	  ADJCALLSTACKUP64 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !25; example.c:0
112B	  %13:gr32 = COPY killed $eax, debug-location !25; example.c:0
128B	  CMP32rr %10:gr32, %12:gr32, implicit-def $eflags, debug-location !23; example.c:51:9
144B	  JCC_1 %bb.2, 14, implicit killed $eflags, debug-location !26; example.c:51:9
160B	  JMP_1 %bb.1, debug-location !26; example.c:51:9

176B	bb.1.if.then:
	; predecessors: %bb.0
	  successors: %bb.3(0x80000000); %bb.3(100.00%)

208B	  %10:gr32 = nsw IMUL32rr %10:gr32(tied-def 0), %12:gr32, implicit-def dead $eflags, debug-location !27; example.c:52:23
240B	  %13:gr32 = nsw ADD32rr %13:gr32(tied-def 0), %10:gr32, implicit-def dead $eflags, debug-instr-number 2, debug-location !29; example.c:52:19
272B	  JMP_1 %bb.3, debug-location !30; example.c:54:5

288B	bb.2.if.else:
	; predecessors: %bb.0
	  successors: %bb.3(0x80000000); %bb.3(100.00%)

304B	  ADJCALLSTACKDOWN64 0, 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !31; example.c:55:20
320B	  $edi = COPY %10:gr32, debug-location !31; example.c:55:20
336B	  CALL64pcrel32 target-flags(x86-plt) @foo, <regmask $bh $bl $bp $bph $bpl $bx $ebp $ebx $hbp $hbx $rbp $rbx $r12 $r13 $r14 $r15 $r12b $r13b $r14b $r15b $r12bh $r13bh $r14bh $r15bh $r12d $r13d $r14d $r15d $r12w $r13w $r14w $r15w $r12wh and 3 more...>, implicit $rsp, implicit $ssp, implicit $edi, implicit-def $rsp, implicit-def $ssp, implicit-def $eax, debug-location !31; example.c:55:20
352B	  ADJCALLSTACKUP64 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !31; example.c:55:20
368B	  %2:gr32 = COPY killed $eax, debug-location !31; example.c:55:20
400B	  %2:gr32 = nsw IMUL32rr %2:gr32(tied-def 0), %13:gr32, implicit-def dead $eflags, debug-location !33; example.c:55:19
432B	  %2:gr32 = nsw ADD32rr %2:gr32(tied-def 0), %12:gr32, implicit-def dead $eflags, debug-instr-number 1, debug-location !34; example.c:55:27
448B	  %13:gr32 = COPY %2:gr32

464B	bb.3.if.end:
	; predecessors: %bb.2, %bb.1

512B	  %12:gr32 = nsw SUB32rr %12:gr32(tied-def 0), %13:gr32, implicit-def dead $eflags, debug-location !35; example.c:57:16
544B	  %12:gr32 = nsw IMUL32rr %12:gr32(tied-def 0), %13:gr32, implicit-def dead $eflags, debug-location !36; example.c:57:13
560B	  $eax = COPY %12:gr32, debug-location !37; example.c:57:5
576B	  RET 0, killed $eax, debug-location !37; example.c:57:5

# End machine code for function bar.

Enqueuing %2
AllocationOrder(GR32) = [ $eax $ecx $edx $esi $edi $r8d $r9d $r10d $r11d $ebx $ebp $r14d $r15d $r12d $r13d ]
Enqueuing %10
Enqueuing %12
Enqueuing %13

selectOrSplit GR32:%12 [16r,512r:2)[512r,544r:0)[544r,560r:1) 0@512r 1@544r 2@16r  weight:8.559322e-03
hints: $eax $esi
missed hint $eax
Analyze counted 7 instrs in 4 blocks, through 0 blocks.
$eax	static = 1.5 worse than no bundles
assigning %12 to $ebx: BH [16r,512r:2)[512r,544r:0)[544r,560r:1) 0@512r 1@544r 2@16r BL [16r,512r:2)[512r,544r:0)[544r,560r:1) 0@512r 1@544r 2@16r HBX [16r,512r:2)[512r,544r:0)[544r,560r:1) 0@512r 1@544r 2@16r

selectOrSplit GR32:%13 [112r,240r:3)[240r,288B:1)[288B,400r:3)[448r,464B:0)[464B,544r:2) 0@448r 1@240r 2@464B-phi 3@112r  weight:6.441327e-03
hints: $eax
missed hint $eax
Analyze counted 6 instrs in 5 blocks, through 0 blocks.
$eax	static = 0.5, v=0, total = 1.0 with bundles EB#1 EB#2.
assigning %13 to $ebp: BPL [112r,240r:3)[240r,288B:1)[288B,400r:3)[448r,464B:0)[464B,544r:2) 0@448r 1@240r 2@464B-phi 3@112r BPH [112r,240r:3)[240r,288B:1)[288B,400r:3)[448r,464B:0)[464B,544r:2) 0@448r 1@240r 2@464B-phi 3@112r HBP [112r,240r:3)[240r,288B:1)[288B,400r:3)[448r,464B:0)[464B,544r:2) 0@448r 1@240r 2@464B-phi 3@112r

selectOrSplit GR32:%10 [32r,208r:0)[208r,240r:1)[288B,320r:0) 0@32r 1@208r  weight:7.866044e-03
hints: $edi
missed hint $edi
Analyze counted 6 instrs in 3 blocks, through 0 blocks.
$edi	static = 1.0, v=0, total = 1.0 with bundles EB#1.
Split for $edi in 1 bundles, intv 1.
splitAroundRegion with 2 globals.
%bb.0 [0B;176B), uses 32r-128r, reg-out 1, enter after 80d, defined in block, interference overlaps uses.
    selectIntv 1 -> 1
    enterIntvAfter 80d: valno 0
    useIntv [88r;176B): [88r;176B):1
    enterIntvBefore 32r: not live
    useIntv [32B;88r): [32B;88r):2 [88r;176B):1
%bb.1 [176B;288B), uses 208r-240r, reg-in 1, leave before invalid, killed in block before interference.
    selectIntv 2 -> 1
    useIntv [176B;240r): [32B;88r):2 [88r;240r):1
%bb.2 [288B;464B), uses 320r-320r, reg-in 1, leave before 320r, killed in block before interference.
    selectIntv 1 -> 1
    useIntv [288B;320r): [32B;88r):2 [88r;240r):1 [288B;320r):1
Removing 0 back-copies.
  blit [32r,208r:0): [32r;88r)=2(%16):0 [88r;208r)=1(%15):0
  blit [208r,240r:1): [208r;240r)=1(%15):1
  blit [288B,320r:0): [288B;320r)=1(%15):0
  rewr %bb.0	32r:2	%16:gr32 = COPY $edi
  rewr %bb.1	208r:1	%15:gr32 = nsw IMUL32rr %10:gr32(tied-def 0), %12:gr32, implicit-def dead $eflags, debug-location !27; example.c:52:23
  rewr %bb.1	240B:1	%13:gr32 = nsw ADD32rr %13:gr32(tied-def 0), %15:gr32, implicit-def dead $eflags, debug-instr-number 2, debug-location !29; example.c:52:19
  rewr %bb.1	208B:1	%15:gr32 = nsw IMUL32rr %15:gr32(tied-def 0), %12:gr32, implicit-def dead $eflags, debug-location !27; example.c:52:23
  rewr %bb.0	64B:2	$edi = COPY %16:gr32, debug-location !25; example.c:0
  rewr %bb.0	128B:1	CMP32rr %15:gr32, %12:gr32, implicit-def $eflags, debug-location !23; example.c:51:9
  rewr %bb.2	320B:1	$edi = COPY %15:gr32, debug-location !31; example.c:55:20
  rewr %bb.0	88B:2	%15:gr32 = COPY %16:gr32
Main interval covers the same 3 blocks as original.
not queueing unused  %14 EMPTY  weight:INF
queuing new interval: %15 [88r,208r:0)[208r,240r:1)[288B,320r:0) 0@88r 1@208r  weight:6.894198e-03
Enqueuing %15
queuing new interval: %16 [32r,88r:0) 0@32r  weight:6.644737e-03
Enqueuing %16

selectOrSplit GR32:%15 [88r,208r:0)[208r,240r:1)[288B,320r:0) 0@88r 1@208r  weight:6.894198e-03
hints: $edi
assigning %15 to $edi: DIL [88r,208r:0)[208r,240r:1)[288B,320r:0) 0@88r 1@208r DIH [88r,208r:0)[208r,240r:1)[288B,320r:0) 0@88r 1@208r HDI [88r,208r:0)[208r,240r:1)[288B,320r:0) 0@88r 1@208r

selectOrSplit GR32:%16 [32r,88r:0) 0@32r  weight:6.644737e-03
hints: $edi
missed hint $edi
Analyze counted 3 instrs in 1 blocks, through 0 blocks.
$edi	no positive bundles
assigning %16 to $ebp: BPL [32r,88r:0) 0@32r BPH [32r,88r:0) 0@32r HBP [32r,88r:0) 0@32r

selectOrSplit GR32:%2 [368r,400r:2)[400r,432r:0)[432r,448r:1) 0@400r 1@432r 2@368r  weight:INF
hints: $eax $ebp
assigning %2 to $eax: AH [368r,400r:2)[400r,432r:0)[432r,448r:1) 0@400r 1@432r 2@368r AL [368r,400r:2)[400r,432r:0)[432r,448r:1) 0@400r 1@432r 2@368r HAX [368r,400r:2)[400r,432r:0)[432r,448r:1) 0@400r 1@432r 2@368r
Trying to reconcile hints for: %12($ebx)
%12($ebx) is recolorable.
Trying to reconcile hints for: %13($ebp)
%13($ebp) is recolorable.
Trying to reconcile hints for: %16($ebp)
%16($ebp) is recolorable.
********** REWRITE VIRTUAL REGISTERS **********
********** Function: bar
********** REGISTER MAP **********
[%2 -> $eax] GR32
[%12 -> $ebx] GR32
[%13 -> $ebp] GR32
[%15 -> $edi] GR32
[%16 -> $ebp] GR32

0B	bb.0.entry:
	  successors: %bb.1(0x40000000), %bb.2(0x40000000); %bb.1(50.00%), %bb.2(50.00%)
	  liveins: $edi, $esi
16B	  %12:gr32 = COPY $esi
32B	  %16:gr32 = COPY $edi
48B	  ADJCALLSTACKDOWN64 0, 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !25; example.c:0
64B	  $edi = COPY %16:gr32, debug-location !25; example.c:0
80B	  CALL64pcrel32 target-flags(x86-plt) @foo, <regmask $bh $bl $bp $bph $bpl $bx $ebp $ebx $hbp $hbx $rbp $rbx $r12 $r13 $r14 $r15 $r12b $r13b $r14b $r15b $r12bh $r13bh $r14bh $r15bh $r12d $r13d $r14d $r15d $r12w $r13w $r14w $r15w $r12wh and 3 more...>, implicit $rsp, implicit $ssp, implicit $edi, implicit-def $rsp, implicit-def $ssp, implicit-def $eax, debug-location !25; example.c:0
88B	  %15:gr32 = COPY killed %16:gr32
96B	  ADJCALLSTACKUP64 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !25; example.c:0
112B	  %13:gr32 = COPY $eax, debug-location !25; example.c:0
128B	  CMP32rr %15:gr32, %12:gr32, implicit-def $eflags, debug-location !23; example.c:51:9
144B	  JCC_1 %bb.2, 14, implicit killed $eflags, debug-location !26; example.c:51:9
160B	  JMP_1 %bb.1, debug-location !26; example.c:51:9
> renamable $ebx = COPY $esi
> renamable $ebp = COPY $edi
> ADJCALLSTACKDOWN64 0, 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !25; example.c:0
> $edi = COPY renamable $ebp, debug-location !25; example.c:0
> CALL64pcrel32 target-flags(x86-plt) @foo, <regmask $bh $bl $bp $bph $bpl $bx $ebp $ebx $hbp $hbx $rbp $rbx $r12 $r13 $r14 $r15 $r12b $r13b $r14b $r15b $r12bh $r13bh $r14bh $r15bh $r12d $r13d $r14d $r15d $r12w $r13w $r14w $r15w $r12wh and 3 more...>, implicit $rsp, implicit $ssp, implicit $edi, implicit-def $rsp, implicit-def $ssp, implicit-def $eax, debug-location !25; example.c:0
> renamable $edi = COPY killed renamable $ebp
> ADJCALLSTACKUP64 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !25; example.c:0
> renamable $ebp = COPY $eax, debug-location !25; example.c:0
> CMP32rr renamable $edi, renamable $ebx, implicit-def $eflags, debug-location !23; example.c:51:9
> JCC_1 %bb.2, 14, implicit killed $eflags, debug-location !26; example.c:51:9
> JMP_1 %bb.1, debug-location !26; example.c:51:9
176B	bb.1.if.then:
	; predecessors: %bb.0
	  successors: %bb.3(0x80000000); %bb.3(100.00%)
	  liveins: $ebp, $ebx, $edi
208B	  %15:gr32 = nsw IMUL32rr killed %15:gr32(tied-def 0), %12:gr32, implicit-def dead $eflags, debug-location !27; example.c:52:23
240B	  %13:gr32 = nsw ADD32rr killed %13:gr32(tied-def 0), killed %15:gr32, implicit-def dead $eflags, debug-instr-number 2, debug-location !29; example.c:52:19
272B	  JMP_1 %bb.3, debug-location !30; example.c:54:5
> renamable $edi = nsw IMUL32rr killed renamable $edi(tied-def 0), renamable $ebx, implicit-def dead $eflags, debug-location !27; example.c:52:23
> renamable $ebp = nsw ADD32rr killed renamable $ebp(tied-def 0), killed renamable $edi, implicit-def dead $eflags, debug-instr-number 2, debug-location !29; example.c:52:19
> JMP_1 %bb.3, debug-location !30; example.c:54:5
288B	bb.2.if.else:
	; predecessors: %bb.0
	  successors: %bb.3(0x80000000); %bb.3(100.00%)
	  liveins: $ebp, $ebx, $edi
304B	  ADJCALLSTACKDOWN64 0, 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !31; example.c:55:20
320B	  $edi = COPY killed %15:gr32, debug-location !31; example.c:55:20
336B	  CALL64pcrel32 target-flags(x86-plt) @foo, <regmask $bh $bl $bp $bph $bpl $bx $ebp $ebx $hbp $hbx $rbp $rbx $r12 $r13 $r14 $r15 $r12b $r13b $r14b $r15b $r12bh $r13bh $r14bh $r15bh $r12d $r13d $r14d $r15d $r12w $r13w $r14w $r15w $r12wh and 3 more...>, implicit $rsp, implicit $ssp, implicit $edi, implicit-def $rsp, implicit-def $ssp, implicit-def $eax, debug-location !31; example.c:55:20
352B	  ADJCALLSTACKUP64 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !31; example.c:55:20
368B	  %2:gr32 = COPY $eax, debug-location !31; example.c:55:20
400B	  %2:gr32 = nsw IMUL32rr killed %2:gr32(tied-def 0), killed %13:gr32, implicit-def dead $eflags, debug-location !33; example.c:55:19
432B	  %2:gr32 = nsw ADD32rr killed %2:gr32(tied-def 0), %12:gr32, implicit-def dead $eflags, debug-instr-number 1, debug-location !34; example.c:55:27
448B	  %13:gr32 = COPY killed %2:gr32
> ADJCALLSTACKDOWN64 0, 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !31; example.c:55:20
> $edi = COPY killed renamable $edi, debug-location !31; example.c:55:20
Identity copy: $edi = COPY killed renamable $edi, debug-location !31; example.c:55:20
  deleted.
> CALL64pcrel32 target-flags(x86-plt) @foo, <regmask $bh $bl $bp $bph $bpl $bx $ebp $ebx $hbp $hbx $rbp $rbx $r12 $r13 $r14 $r15 $r12b $r13b $r14b $r15b $r12bh $r13bh $r14bh $r15bh $r12d $r13d $r14d $r15d $r12w $r13w $r14w $r15w $r12wh and 3 more...>, implicit $rsp, implicit $ssp, implicit $edi, implicit-def $rsp, implicit-def $ssp, implicit-def $eax, debug-location !31; example.c:55:20
> ADJCALLSTACKUP64 0, 0, implicit-def dead $rsp, implicit-def dead $eflags, implicit-def dead $ssp, implicit $rsp, implicit $ssp, debug-location !31; example.c:55:20
> renamable $eax = COPY $eax, debug-location !31; example.c:55:20
Identity copy: renamable $eax = COPY $eax, debug-location !31; example.c:55:20
  deleted.
> renamable $eax = nsw IMUL32rr killed renamable $eax(tied-def 0), killed renamable $ebp, implicit-def dead $eflags, debug-location !33; example.c:55:19
> renamable $eax = nsw ADD32rr killed renamable $eax(tied-def 0), renamable $ebx, implicit-def dead $eflags, debug-instr-number 1, debug-location !34; example.c:55:27
> renamable $ebp = COPY killed renamable $eax
464B	bb.3.if.end:
	; predecessors: %bb.2, %bb.1
	  liveins: $ebp, $ebx
512B	  %12:gr32 = nsw SUB32rr killed %12:gr32(tied-def 0), %13:gr32, implicit-def dead $eflags, debug-location !35; example.c:57:16
544B	  %12:gr32 = nsw IMUL32rr killed %12:gr32(tied-def 0), killed %13:gr32, implicit-def dead $eflags, debug-location !36; example.c:57:13
560B	  $eax = COPY killed %12:gr32, debug-location !37; example.c:57:5
576B	  RET 0, $eax, debug-location !37; example.c:57:5
> renamable $ebx = nsw SUB32rr killed renamable $ebx(tied-def 0), renamable $ebp, implicit-def dead $eflags, debug-location !35; example.c:57:16
> renamable $ebx = nsw IMUL32rr killed renamable $ebx(tied-def 0), killed renamable $ebp, implicit-def dead $eflags, debug-location !36; example.c:57:13
> $eax = COPY killed renamable $ebx, debug-location !37; example.c:57:5
> RET 0, $eax, debug-location !37; example.c:57:5
Compiler returned: 0

```

可以看到Vninfo是以 ssa形式进行命名的. 每次def,每次live in 都是一个新的ID.

## liveness

先看有哪些数据结构

1. vninfo, SlotIndex
2. Segment, LiveRange, LiveInterval, LiveRangeUpdater
3. LiveRangeCalc, LiveIntervalCalc

接下来依次说明.

VNInfo,给define标个号. 每个虚拟变量之间标号是独立的. 比如:
```txt
%1 [224r,240r:0)[240r,256r:1) 0@224r 1@240r  weight:0.000000e+00
%2 [416r,432r:0)[432r,448r:1) 0@416r 1@432r  weight:0.000000e+00
```

```cpp

// llvm/include/llvm/CodeGen/LiveInterval.h
class VNInfo {
  public:
    /// The ID number of this value.
    unsigned id;

    /// The index of the defining instruction.
    SlotIndex def;

    /// Copy from the parameter into this VNInfo.
    void copyFrom(VNInfo &src) {
      def = src.def;
    }

    /// Returns true if this value is defined by a PHI instruction (or was,
    /// PHI instructions may have been eliminated).
    /// PHI-defs begin at a block boundary, all other defs begin at register or
    /// EC slots.
    bool isPHIDef() const { return def.isBlock(); }

};

// llvm/CodeGen/SlotIndexes.h
class SlotIndex {
    enum Slot {
    /// Basic block boundary.  Used for live ranges entering and leaving a
    /// block without being live in the layout neighbor.  Also used as the
    /// def slot of PHI-defs.
    Slot_Block,

    /// Early-clobber register use/def slot.  A live range defined at
    /// Slot_EarlyClobber interferes with normal live ranges killed at
    /// Slot_Register.  Also used as the kill slot for live ranges tied to an
    /// early-clobber def.
    Slot_EarlyClobber,

    /// Normal register use/def slot.  Normal instructions kill and define
    /// register live ranges at this slot.
    Slot_Register,

    /// Dead def kill point.  Kill slot for a live range that is defined by
    /// the same instruction (Slot_Register or Slot_EarlyClobber), but isn't
    /// used anywhere.
    Slot_Dead,

    Slot_Count
    };

    

    PointerIntPair<IndexListEntry*, 2, unsigned> lie;  // 复用了低2bits放置Slot
}
class IndexListEntry : public ilist_node<IndexListEntry> {
    MachineInstr *mi;
    unsigned index;
}

// slot index管理类， 函数级别
class SlotIndexes{
  using IndexList = simple_ilist<IndexListEntry>;
  IndexList indexList; 
  DenseMap<const MachineInstr *, SlotIndex> mi2iMap;
  SmallVector<std::pair<SlotIndex, SlotIndex>, 8> MBBRanges;  /// MBBRanges - Map MBB number to (start, stop) indexes.
  SmallVector<std::pair<SlotIndex, MachineBasicBlock *>, 8> idx2MBBMap; // sorted list, <first-inst, mbb>

};

```

---------------------


- segment表示在一个block块内,某个def-use的生命周期
- LiveRange是以ssa形式组织segments的,即一个def对应一个value number, livein/phi也是一个def
- LiveInterval是liverange+register
- LiveRangeUpdater: 更新segments时候的缓存

```cpp
// [start, end)
// segment表示
// llvm/include/llvm/CodeGen/LiveInterval.h
struct Segment {
    SlotIndex start;  // Start point of the interval (inclusive)
    SlotIndex end;    // End point of the interval (exclusive)
    VNInfo *valno = nullptr; // identifier for the value contained in this
                            // segment.

    /// Return true if the index is covered by this segment.
    bool contains(SlotIndex I) const {
        return start <= I && I < end;
    }

    /// Return true if the given interval, [S, E), is covered by this segment.
    bool containsInterval(SlotIndex S, SlotIndex E) const {
        assert((S < E) && "Backwards interval?");
        return (start <= S && S < end) && (start < E && E <= end);
    }

    bool operator<(const Segment &Other) const {
    return std::tie(start, end) < std::tie(Other.start, Other.end);
    }
    bool operator==(const Segment &Other) const {
    return start == Other.start && end == Other.end;
    }


    void dump() const;
};

/// This class represents the liveness of a register, stack slot, etc.
/// It manages an ordered list of Segment objects.
/// The Segments are organized in a static single assignment form: At places
/// where a new value is defined or different values reach a CFG join a new
/// segment with a new value number is used.
class LiveRange {
  public:

    using Segments = SmallVector<Segment, 2>;
    using VNInfoList = SmallVector<VNInfo *, 2>;

    Segments segments;   // the liveness segments
    VNInfoList valnos;   // value#'s
}

/// Helper class for performant LiveRange bulk updates.
///
/// Calling LiveRange::addSegment() repeatedly can be expensive on large
/// live ranges because segments after the insertion point may need to be
/// shifted. The LiveRangeUpdater class can defer the shifting when adding
/// many segments in order.
///
/// The LiveRange will be in an invalid state until flush() is called.
class LiveRangeUpdater {
    LiveRange *LR;
    SlotIndex LastStart;
    LiveRange::iterator WriteI;
    LiveRange::iterator ReadI;
    SmallVector<LiveRange::Segment, 16> Spills;
    void mergeSpills();

  public:
    /// Create a LiveRangeUpdater for adding segments to LR.
    /// LR will temporarily be in an invalid state until flush() is called.
    LiveRangeUpdater(LiveRange *lr = nullptr) : LR(lr) {}

    ~LiveRangeUpdater() { flush(); }

    /// Add a segment to LR and coalesce when possible, just like
    /// LR.addSegment(). Segments should be added in increasing start order for
    /// best performance.
    void add(LiveRange::Segment);

    void add(SlotIndex Start, SlotIndex End, VNInfo *VNI) {
      add(LiveRange::Segment(Start, End, VNI));
    }

    /// Return true if the LR is currently in an invalid state, and flush()
    /// needs to be called.
    bool isDirty() const { return LastStart.isValid(); }

    /// Flush the updater state to LR so it is valid and contains all added
    /// segments.
    void flush();

    /// Select a different destination live range.
    void setDest(LiveRange *lr) {
      if (LR != lr && isDirty())
        flush();
      LR = lr;
    }

    /// Get the current destination live range.
    LiveRange *getDest() const { return LR; }

};


class LiveInterval : public LiveRange {
  public:
    using super = LiveRange;

    /// A live range for subregisters. The LaneMask specifies which parts of the
    /// super register are covered by the interval.
    /// (@sa TargetRegisterInfo::getSubRegIndexLaneMask()).
    class SubRange : public LiveRange {
    public:
      SubRange *Next = nullptr;
      LaneBitmask LaneMask;

      /// Constructs a new SubRange object.
      SubRange(LaneBitmask LaneMask) : LaneMask(LaneMask) {}

      /// Constructs a new SubRange object by copying liveness from @p Other.
      SubRange(LaneBitmask LaneMask, const LiveRange &Other,
               BumpPtrAllocator &Allocator)
        : LiveRange(Other, Allocator), LaneMask(LaneMask) {}

      void print(raw_ostream &OS) const;
      void dump() const;
    };

  private:
    SubRange *SubRanges = nullptr; ///< Single linked list of subregister live
                                   /// ranges.
    const Register Reg; // the register or stack slot of this interval.
    float Weight = 0.0; // weight of this interval
}

```


------------------

- LiveRangeCalc, LiveIntervalCalc: 计算和查询接口, 采用增量式更新

```cpp

// llvm/CodeGen/LiveRangeCalc.cpp
LiveRangeCalc::calculateValues(){
    updateSSA() // 依据domtree来迭代至不动点, (为啥用domtree不太懂)
    updateFromLiveIns() // livein --> LiveRangeUpdater::add
}

```

