
; llc vn.ll -march=aarch64 --stop-after=register-coalescer 

declare void @print(i32);

define i32 @foo(i32 %a, i1 %c) {

bb0:
    br i1 %c, label %bb1, label %bb2

bb2:
    %a2 = add i32 %a, 1
    br label %bb3

bb1:
    call void @print(i32 %a)
    br label %bb3

bb3:
    %a3 = phi i32 [%a, %bb1], [%a2, %bb2]
    ret i32 %a3
}
