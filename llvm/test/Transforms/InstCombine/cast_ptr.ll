; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; Tests to make sure elimination of casts is working correctly
; RUN: opt < %s -passes=instcombine -S | FileCheck %s

target datalayout = "p:32:32-p1:32:32-p2:16:16-p3:32:32:32:16"

@global = global i8 0

; This shouldn't convert to getelementptr because the relationship
; between the arithmetic and the layout of allocated memory is
; entirely unknown.

define ptr @test1(ptr %t) {
; CHECK-LABEL: @test1(
; CHECK-NEXT:    [[TC:%.*]] = ptrtoint ptr [[T:%.*]] to i32
; CHECK-NEXT:    [[TA:%.*]] = add i32 [[TC]], 32
; CHECK-NEXT:    [[TV:%.*]] = inttoptr i32 [[TA]] to ptr
; CHECK-NEXT:    ret ptr [[TV]]
;
  %tc = ptrtoint ptr %t to i32
  %ta = add i32 %tc, 32
  %tv = inttoptr i32 %ta to ptr
  ret ptr %tv
}

; These casts should be folded away.

define i1 @test2(ptr %a, ptr %b) {
; CHECK-LABEL: @test2(
; CHECK-NEXT:    [[R:%.*]] = icmp eq ptr [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    ret i1 [[R]]
;
  %ta = ptrtoint ptr %a to i32
  %tb = ptrtoint ptr %b to i32
  %r = icmp eq i32 %ta, %tb
  ret i1 %r
}

; These casts should be folded away.

define i1 @test2_as2_same_int(ptr addrspace(2) %a, ptr addrspace(2) %b) {
; CHECK-LABEL: @test2_as2_same_int(
; CHECK-NEXT:    [[R:%.*]] = icmp eq ptr addrspace(2) [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    ret i1 [[R]]
;
  %ta = ptrtoint ptr addrspace(2) %a to i16
  %tb = ptrtoint ptr addrspace(2) %b to i16
  %r = icmp eq i16 %ta, %tb
  ret i1 %r
}

; These casts should be folded away.

define i1 @test2_as2_larger(ptr addrspace(2) %a, ptr addrspace(2) %b) {
; CHECK-LABEL: @test2_as2_larger(
; CHECK-NEXT:    [[R:%.*]] = icmp eq ptr addrspace(2) [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    ret i1 [[R]]
;
  %ta = ptrtoint ptr addrspace(2) %a to i32
  %tb = ptrtoint ptr addrspace(2) %b to i32
  %r = icmp eq i32 %ta, %tb
  ret i1 %r
}

; These casts should not be folded away.

define i1 @test2_diff_as(ptr %p, ptr addrspace(1) %q) {
; CHECK-LABEL: @test2_diff_as(
; CHECK-NEXT:    [[I0:%.*]] = ptrtoint ptr [[P:%.*]] to i32
; CHECK-NEXT:    [[I1:%.*]] = ptrtoint ptr addrspace(1) [[Q:%.*]] to i32
; CHECK-NEXT:    [[R0:%.*]] = icmp sge i32 [[I0]], [[I1]]
; CHECK-NEXT:    ret i1 [[R0]]
;
  %i0 = ptrtoint ptr %p to i32
  %i1 = ptrtoint ptr addrspace(1) %q to i32
  %r0 = icmp sge i32 %i0, %i1
  ret i1 %r0
}

; These casts should not be folded away.

define i1 @test2_diff_as_global(ptr addrspace(1) %q) {
; CHECK-LABEL: @test2_diff_as_global(
; CHECK-NEXT:    [[I1:%.*]] = ptrtoint ptr addrspace(1) [[Q:%.*]] to i32
; CHECK-NEXT:    [[R0:%.*]] = icmp sge i32 [[I1]], ptrtoint (ptr @global to i32)
; CHECK-NEXT:    ret i1 [[R0]]
;
  %i0 = ptrtoint ptr @global to i32
  %i1 = ptrtoint ptr addrspace(1) %q to i32
  %r0 = icmp sge i32 %i1, %i0
  ret i1 %r0
}

; These casts should also be folded away.

define i1 @test3(ptr %a) {
; CHECK-LABEL: @test3(
; CHECK-NEXT:    [[R:%.*]] = icmp eq ptr [[A:%.*]], @global
; CHECK-NEXT:    ret i1 [[R]]
;
  %ta = ptrtoint ptr %a to i32
  %r = icmp eq i32 %ta, ptrtoint (ptr @global to i32)
  ret i1 %r
}

define i1 @test4(i32 %A) {
; CHECK-LABEL: @test4(
; CHECK-NEXT:    [[C:%.*]] = icmp eq i32 [[A:%.*]], 0
; CHECK-NEXT:    ret i1 [[C]]
;
  %B = inttoptr i32 %A to ptr
  %C = icmp eq ptr %B, null
  ret i1 %C
}

define i1 @test4_as2(i16 %A) {
; CHECK-LABEL: @test4_as2(
; CHECK-NEXT:    [[C:%.*]] = icmp eq i16 [[A:%.*]], 0
; CHECK-NEXT:    ret i1 [[C]]
;
  %B = inttoptr i16 %A to ptr addrspace(2)
  %C = icmp eq ptr addrspace(2) %B, null
  ret i1 %C
}


; Pulling the cast out of the load allows us to eliminate the load, and then
; the whole array.

  %op = type { float }
  %unop = type { i32 }
@Array = internal constant [1 x ptr] [ ptr @foo ]

declare ptr @foo(ptr %X)

define ptr @test5(ptr %O) {
; CHECK-LABEL: @test5(
; CHECK-NEXT:    [[T_2:%.*]] = call ptr @foo(ptr [[O:%.*]])
; CHECK-NEXT:    ret ptr [[T_2]]
;
  %t = load ptr, ptr @Array; <ptr> [#uses=1]
  %t.2 = call ptr %t( ptr %O )
  ret ptr %t.2
}



; InstCombine can not 'load (cast P)' -> cast (load P)' if the cast changes
; the address space.

define i8 @test6(ptr addrspace(1) %source) {
; CHECK-LABEL: @test6(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[ARRAYIDX223:%.*]] = addrspacecast ptr addrspace(1) [[SOURCE:%.*]] to ptr
; CHECK-NEXT:    [[T4:%.*]] = load i8, ptr [[ARRAYIDX223]], align 1
; CHECK-NEXT:    ret i8 [[T4]]
;
entry:
  %arrayidx223 = addrspacecast ptr addrspace(1) %source to ptr
  %t4 = load i8, ptr %arrayidx223
  ret i8 %t4
}

define <2 x i32> @insertelt(<2 x i32> %x, ptr %p, i133 %index) {
; CHECK-LABEL: @insertelt(
; CHECK-NEXT:    [[TMP1:%.*]] = ptrtoint ptr [[P:%.*]] to i32
; CHECK-NEXT:    [[R:%.*]] = insertelement <2 x i32> [[X:%.*]], i32 [[TMP1]], i133 [[INDEX:%.*]]
; CHECK-NEXT:    ret <2 x i32> [[R]]
;
  %v = inttoptr <2 x i32> %x to <2 x ptr>
  %i = insertelement <2 x ptr> %v, ptr %p, i133 %index
  %r = ptrtoint <2 x ptr> %i to <2 x i32>
  ret <2 x i32> %r
}

define <2 x i32> @insertelt_intptr_trunc(<2 x i64> %x, ptr %p) {
; CHECK-LABEL: @insertelt_intptr_trunc(
; CHECK-NEXT:    [[TMP1:%.*]] = trunc <2 x i64> [[X:%.*]] to <2 x i32>
; CHECK-NEXT:    [[TMP2:%.*]] = ptrtoint ptr [[P:%.*]] to i32
; CHECK-NEXT:    [[R:%.*]] = insertelement <2 x i32> [[TMP1]], i32 [[TMP2]], i64 0
; CHECK-NEXT:    ret <2 x i32> [[R]]
;
  %v = inttoptr <2 x i64> %x to <2 x ptr>
  %i = insertelement <2 x ptr> %v, ptr %p, i32 0
  %r = ptrtoint <2 x ptr> %i to <2 x i32>
  ret <2 x i32> %r
}

define <2 x i32> @insertelt_intptr_zext(<2 x i8> %x, ptr %p) {
; CHECK-LABEL: @insertelt_intptr_zext(
; CHECK-NEXT:    [[TMP1:%.*]] = zext <2 x i8> [[X:%.*]] to <2 x i32>
; CHECK-NEXT:    [[TMP2:%.*]] = ptrtoint ptr [[P:%.*]] to i32
; CHECK-NEXT:    [[R:%.*]] = insertelement <2 x i32> [[TMP1]], i32 [[TMP2]], i64 1
; CHECK-NEXT:    ret <2 x i32> [[R]]
;
  %v = inttoptr <2 x i8> %x to <2 x ptr>
  %i = insertelement <2 x ptr> %v, ptr %p, i32 1
  %r = ptrtoint <2 x ptr> %i to <2 x i32>
  ret <2 x i32> %r
}

define <2 x i64> @insertelt_intptr_zext_zext(<2 x i8> %x, ptr %p) {
; CHECK-LABEL: @insertelt_intptr_zext_zext(
; CHECK-NEXT:    [[TMP1:%.*]] = zext <2 x i8> [[X:%.*]] to <2 x i32>
; CHECK-NEXT:    [[TMP2:%.*]] = ptrtoint ptr [[P:%.*]] to i32
; CHECK-NEXT:    [[TMP3:%.*]] = insertelement <2 x i32> [[TMP1]], i32 [[TMP2]], i64 0
; CHECK-NEXT:    [[R:%.*]] = zext <2 x i32> [[TMP3]] to <2 x i64>
; CHECK-NEXT:    ret <2 x i64> [[R]]
;
  %v = inttoptr <2 x i8> %x to <2 x ptr>
  %i = insertelement <2 x ptr> %v, ptr %p, i32 0
  %r = ptrtoint <2 x ptr> %i to <2 x i64>
  ret <2 x i64> %r
}

declare void @use(<2 x ptr>)

define <2 x i32> @insertelt_extra_use1(<2 x i32> %x, ptr %p) {
; CHECK-LABEL: @insertelt_extra_use1(
; CHECK-NEXT:    [[V:%.*]] = inttoptr <2 x i32> [[X:%.*]] to <2 x ptr>
; CHECK-NEXT:    call void @use(<2 x ptr> [[V]])
; CHECK-NEXT:    [[TMP1:%.*]] = ptrtoint ptr [[P:%.*]] to i32
; CHECK-NEXT:    [[R:%.*]] = insertelement <2 x i32> [[X]], i32 [[TMP1]], i64 0
; CHECK-NEXT:    ret <2 x i32> [[R]]
;
  %v = inttoptr <2 x i32> %x to <2 x ptr>
  call void @use(<2 x ptr> %v)
  %i = insertelement <2 x ptr> %v, ptr %p, i32 0
  %r = ptrtoint <2 x ptr> %i to <2 x i32>
  ret <2 x i32> %r
}

define <2 x i32> @insertelt_extra_use2(<2 x i32> %x, ptr %p) {
; CHECK-LABEL: @insertelt_extra_use2(
; CHECK-NEXT:    [[V:%.*]] = inttoptr <2 x i32> [[X:%.*]] to <2 x ptr>
; CHECK-NEXT:    [[I:%.*]] = insertelement <2 x ptr> [[V]], ptr [[P:%.*]], i64 0
; CHECK-NEXT:    call void @use(<2 x ptr> [[I]])
; CHECK-NEXT:    [[R:%.*]] = ptrtoint <2 x ptr> [[I]] to <2 x i32>
; CHECK-NEXT:    ret <2 x i32> [[R]]
;
  %v = inttoptr <2 x i32> %x to <2 x ptr>
  %i = insertelement <2 x ptr> %v, ptr %p, i32 0
  call void @use(<2 x ptr> %i)
  %r = ptrtoint <2 x ptr> %i to <2 x i32>
  ret <2 x i32> %r
}

define i32 @ptr_add_in_int(i32 %x, i32 %y) {
; CHECK-LABEL: @ptr_add_in_int(
; CHECK-NEXT:    [[R:%.*]] = add i32 [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i32 %x to ptr
  %p2 = getelementptr inbounds i8, ptr %ptr, i32 %y
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

define i32 @ptr_add_in_int_2(i32 %x, i32 %y) {
; CHECK-LABEL: @ptr_add_in_int_2(
; CHECK-NEXT:    [[P2_IDX:%.*]] = shl nsw i32 [[Y:%.*]], 2
; CHECK-NEXT:    [[R:%.*]] = add i32 [[X:%.*]], [[P2_IDX]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i32 %x to ptr
  %p2 = getelementptr inbounds i32, ptr %ptr, i32 %y
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

define i32 @ptr_add_in_int_nneg(i32 %x, i32 %y) {
; CHECK-LABEL: @ptr_add_in_int_nneg(
; CHECK-NEXT:    [[Z:%.*]] = call i32 @llvm.abs.i32(i32 [[Y:%.*]], i1 true)
; CHECK-NEXT:    [[R:%.*]] = add nuw i32 [[X:%.*]], [[Z]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %z = call i32 @llvm.abs.i32(i32 %y, i1 true)
  %ptr = inttoptr i32 %x to ptr
  %p2 = getelementptr inbounds i8, ptr %ptr, i32 %z
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

define i64 @ptr_add_in_int_different_type_1(i32 %x, i32 %y) {
; CHECK-LABEL: @ptr_add_in_int_different_type_1(
; CHECK-NEXT:    [[TMP1:%.*]] = add i32 [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[R:%.*]] = zext i32 [[TMP1]] to i64
; CHECK-NEXT:    ret i64 [[R]]
;
  %ptr = inttoptr i32 %x to ptr
  %p2 = getelementptr i8, ptr %ptr, i32 %y
  %r = ptrtoint ptr %p2 to i64
  ret i64 %r
}

define i16 @ptr_add_in_int_different_type_2(i32 %x, i32 %y) {
; CHECK-LABEL: @ptr_add_in_int_different_type_2(
; CHECK-NEXT:    [[TMP1:%.*]] = add i32 [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[R:%.*]] = trunc i32 [[TMP1]] to i16
; CHECK-NEXT:    ret i16 [[R]]
;
  %ptr = inttoptr i32 %x to ptr
  %p2 = getelementptr i8, ptr %ptr, i32 %y
  %r = ptrtoint ptr %p2 to i16
  ret i16 %r
}

define i32 @ptr_add_in_int_different_type_3(i16 %x, i32 %y) {
; CHECK-LABEL: @ptr_add_in_int_different_type_3(
; CHECK-NEXT:    [[TMP1:%.*]] = zext i16 [[X:%.*]] to i32
; CHECK-NEXT:    [[R:%.*]] = add i32 [[Y:%.*]], [[TMP1]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i16 %x to ptr
  %p2 = getelementptr i8, ptr %ptr, i32 %y
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

define i32 @ptr_add_in_int_different_type_4(i64 %x, i32 %y) {
; CHECK-LABEL: @ptr_add_in_int_different_type_4(
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i64 [[X:%.*]] to i32
; CHECK-NEXT:    [[R:%.*]] = add i32 [[Y:%.*]], [[TMP1]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i64 %x to ptr
  %p2 = getelementptr i8, ptr %ptr, i32 %y
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

define i32 @ptr_add_in_int_not_inbounds(i32 %x, i32 %y) {
; CHECK-LABEL: @ptr_add_in_int_not_inbounds(
; CHECK-NEXT:    [[Z:%.*]] = call i32 @llvm.abs.i32(i32 [[Y:%.*]], i1 true)
; CHECK-NEXT:    [[R:%.*]] = add i32 [[X:%.*]], [[Z]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %z = call i32 @llvm.abs.i32(i32 %y, i1 true)
  %ptr = inttoptr i32 %x to ptr
  %p2 = getelementptr i8, ptr %ptr, i32 %z
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

define i32 @ptr_add_in_int_nuw(i32 %x, i32 %y) {
; CHECK-LABEL: @ptr_add_in_int_nuw(
; CHECK-NEXT:    [[R:%.*]] = add nuw i32 [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i32 %x to ptr
  %p2 = getelementptr nuw i8, ptr %ptr, i32 %y
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

define i32 @ptr_add_in_int_nusw(i32 %x, i32 %y) {
; CHECK-LABEL: @ptr_add_in_int_nusw(
; CHECK-NEXT:    [[R:%.*]] = add i32 [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i32 %x to ptr
  %p2 = getelementptr nusw i8, ptr %ptr, i32 %y
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

define i32 @ptr_add_in_int_nusw_nneg(i32 %x, i32 %y) {
; CHECK-LABEL: @ptr_add_in_int_nusw_nneg(
; CHECK-NEXT:    [[NNEG:%.*]] = icmp sgt i32 [[Y:%.*]], -1
; CHECK-NEXT:    call void @llvm.assume(i1 [[NNEG]])
; CHECK-NEXT:    [[R:%.*]] = add nuw i32 [[X:%.*]], [[Y]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %nneg = icmp sge i32 %y, 0
  call void @llvm.assume(i1 %nneg)
  %ptr = inttoptr i32 %x to ptr
  %p2 = getelementptr nusw i8, ptr %ptr, i32 %y
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

define i32 @ptr_add_in_int_const(i32 %x) {
; CHECK-LABEL: @ptr_add_in_int_const(
; CHECK-NEXT:    [[R:%.*]] = add nuw i32 [[X:%.*]], 4096
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i32 %x to ptr
  %p2 = getelementptr inbounds i8, ptr %ptr, i32 4096
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

define i32 @ptr_add_in_int_const_negative(i32 %x) {
; CHECK-LABEL: @ptr_add_in_int_const_negative(
; CHECK-NEXT:    [[R:%.*]] = add i32 [[X:%.*]], -4096
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i32 %x to ptr
  %p2 = getelementptr inbounds i8, ptr %ptr, i32 -4096
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

declare void @use_ptr(ptr)

define i32 @ptr_add_in_int_extra_use1(i32 %x) {
; CHECK-LABEL: @ptr_add_in_int_extra_use1(
; CHECK-NEXT:    [[PTR:%.*]] = inttoptr i32 [[X:%.*]] to ptr
; CHECK-NEXT:    call void @use_ptr(ptr [[PTR]])
; CHECK-NEXT:    [[P2:%.*]] = getelementptr inbounds nuw i8, ptr [[PTR]], i32 4096
; CHECK-NEXT:    [[R:%.*]] = ptrtoint ptr [[P2]] to i32
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i32 %x to ptr
  call void @use_ptr(ptr %ptr)
  %p2 = getelementptr inbounds i8, ptr %ptr, i32 4096
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

define i32 @ptr_add_in_int_extra_use2(i32 %x) {
; CHECK-LABEL: @ptr_add_in_int_extra_use2(
; CHECK-NEXT:    [[PTR:%.*]] = inttoptr i32 [[X:%.*]] to ptr
; CHECK-NEXT:    [[P2:%.*]] = getelementptr inbounds nuw i8, ptr [[PTR]], i32 4096
; CHECK-NEXT:    call void @use_ptr(ptr nonnull [[P2]])
; CHECK-NEXT:    [[R:%.*]] = ptrtoint ptr [[P2]] to i32
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i32 %x to ptr
  %p2 = getelementptr inbounds i8, ptr %ptr, i32 4096
  call void @use_ptr(ptr %p2)
  %r = ptrtoint ptr %p2 to i32
  ret i32 %r
}

define i32 @ptrtoint_of_inttoptr_multiple_gep(i32 %x, i32 %y, i32 %z) {
; CHECK-LABEL: @ptrtoint_of_inttoptr_multiple_gep(
; CHECK-NEXT:    [[PTR2_IDX:%.*]] = shl nuw i32 [[Y:%.*]], 1
; CHECK-NEXT:    [[TMP1:%.*]] = add nuw i32 [[X:%.*]], [[PTR2_IDX]]
; CHECK-NEXT:    [[PTR3_IDX:%.*]] = shl i32 [[Z:%.*]], 2
; CHECK-NEXT:    [[R:%.*]] = add i32 [[TMP1]], [[PTR3_IDX]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i32 %x to ptr
  %ptr2 = getelementptr nuw i16, ptr %ptr, i32 %y
  %ptr3 = getelementptr i32, ptr %ptr2, i32 %z
  %r = ptrtoint ptr %ptr3 to i32
  ret i32 %r
}

define i32 @ptrtoint_of_inttoptr_multiple_gep_extra_use(i32 %x, i32 %y, i32 %z) {
; CHECK-LABEL: @ptrtoint_of_inttoptr_multiple_gep_extra_use(
; CHECK-NEXT:    [[PTR:%.*]] = inttoptr i32 [[X:%.*]] to ptr
; CHECK-NEXT:    [[PTR2:%.*]] = getelementptr i16, ptr [[PTR]], i32 [[Y:%.*]]
; CHECK-NEXT:    call void @use_ptr(ptr [[PTR2]])
; CHECK-NEXT:    [[PTR3:%.*]] = getelementptr i32, ptr [[PTR2]], i32 [[Z:%.*]]
; CHECK-NEXT:    [[R:%.*]] = ptrtoint ptr [[PTR3]] to i32
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i32 %x to ptr
  %ptr2 = getelementptr i16, ptr %ptr, i32 %y
  call void @use_ptr(ptr %ptr2)
  %ptr3 = getelementptr i32, ptr %ptr2, i32 %z
  %r = ptrtoint ptr %ptr3 to i32
  ret i32 %r
}

define i32 @ptrtoint_of_inttoptr_index_type(i32 %x, i16 %y) {
; CHECK-LABEL: @ptrtoint_of_inttoptr_index_type(
; CHECK-NEXT:    [[PTR:%.*]] = inttoptr i32 [[X:%.*]] to ptr addrspace(3)
; CHECK-NEXT:    [[PTR2:%.*]] = getelementptr i16, ptr addrspace(3) [[PTR]], i16 [[Y:%.*]]
; CHECK-NEXT:    [[R:%.*]] = ptrtoint ptr addrspace(3) [[PTR2]] to i32
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = inttoptr i32 %x to ptr addrspace(3)
  %ptr2 = getelementptr i16, ptr addrspace(3) %ptr, i16 %y
  %r = ptrtoint ptr addrspace(3) %ptr2 to i32
  ret i32 %r
}

define i32 @ptrtoint_of_null_multiple_gep(i32 %x, i32 %y, i32 %z) {
; CHECK-LABEL: @ptrtoint_of_null_multiple_gep(
; CHECK-NEXT:    [[PTR2_IDX:%.*]] = shl i32 [[X:%.*]], 1
; CHECK-NEXT:    [[PTR3_IDX:%.*]] = shl nuw i32 [[Y:%.*]], 2
; CHECK-NEXT:    [[TMP1:%.*]] = add nuw i32 [[PTR2_IDX]], [[PTR3_IDX]]
; CHECK-NEXT:    [[PTR4_IDX:%.*]] = shl i32 [[Z:%.*]], 3
; CHECK-NEXT:    [[R:%.*]] = add i32 [[TMP1]], [[PTR4_IDX]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr2 = getelementptr i16, ptr null, i32 %x
  %ptr3 = getelementptr nuw i32, ptr %ptr2, i32 %y
  %ptr4 = getelementptr i64, ptr %ptr3, i32 %z
  %r = ptrtoint ptr %ptr4 to i32
  ret i32 %r
}

define i32 @ptrtoint_of_null_multiple_gep_extra_use(i32 %x, i32 %y, i32 %z) {
; CHECK-LABEL: @ptrtoint_of_null_multiple_gep_extra_use(
; CHECK-NEXT:    [[PTR2:%.*]] = getelementptr i16, ptr null, i32 [[X:%.*]]
; CHECK-NEXT:    call void @use_ptr(ptr [[PTR2]])
; CHECK-NEXT:    [[PTR3:%.*]] = getelementptr nuw i32, ptr [[PTR2]], i32 [[Y:%.*]]
; CHECK-NEXT:    [[PTR4:%.*]] = getelementptr i64, ptr [[PTR3]], i32 [[Z:%.*]]
; CHECK-NEXT:    [[R:%.*]] = ptrtoint ptr [[PTR4]] to i32
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr2 = getelementptr i16, ptr null, i32 %x
  call void @use_ptr(ptr %ptr2)
  %ptr3 = getelementptr nuw i32, ptr %ptr2, i32 %y
  %ptr4 = getelementptr i64, ptr %ptr3, i32 %z
  %r = ptrtoint ptr %ptr4 to i32
  ret i32 %r
}

define i32 @ptrtoint_of_null_index_type(i16 %x) {
; CHECK-LABEL: @ptrtoint_of_null_index_type(
; CHECK-NEXT:    [[PTR_IDX:%.*]] = shl i16 [[X:%.*]], 1
; CHECK-NEXT:    [[R:%.*]] = zext i16 [[PTR_IDX]] to i32
; CHECK-NEXT:    ret i32 [[R]]
;
  %ptr = getelementptr i16, ptr addrspace(3) null, i16 %x
  %r = ptrtoint ptr addrspace(3) %ptr to i32
  ret i32 %r
}

define <2 x i32> @ptrtoint_of_null_splat(<2 x i16> %x) {
; CHECK-LABEL: @ptrtoint_of_null_splat(
; CHECK-NEXT:    [[PTR:%.*]] = getelementptr i16, ptr addrspace(3) null, <2 x i16> [[X:%.*]]
; CHECK-NEXT:    [[R:%.*]] = ptrtoint <2 x ptr addrspace(3)> [[PTR]] to <2 x i32>
; CHECK-NEXT:    ret <2 x i32> [[R]]
;
  %ptr = getelementptr i16, ptr addrspace(3) null, <2 x i16> %x
  %r = ptrtoint <2 x ptr addrspace(3)> %ptr to <2 x i32>
  ret <2 x i32> %r
}
