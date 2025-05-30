; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc --mtriple=loongarch64 -mattr=+d,-scq,-ld-seq-sa < %s | FileCheck %s --check-prefix=LA64
; RUN: llc --mtriple=loongarch64 -mattr=+d,+scq,-ld-seq-sa --verify-machineinstrs < %s | FileCheck %s --check-prefixes=LA64-SCQ,NO-LD-SEQ-SA
; RUN: llc --mtriple=loongarch64 -mattr=+d,+scq,+ld-seq-sa --verify-machineinstrs < %s | FileCheck %s --check-prefixes=LA64-SCQ,LD-SEQ-SA

define void @cmpxchg_i128_acquire_acquire(ptr %ptr, i128 %cmp, i128 %val) nounwind {
; LA64-LABEL: cmpxchg_i128_acquire_acquire:
; LA64:       # %bb.0:
; LA64-NEXT:    addi.d $sp, $sp, -32
; LA64-NEXT:    st.d $ra, $sp, 24 # 8-byte Folded Spill
; LA64-NEXT:    move $a6, $a4
; LA64-NEXT:    st.d $a2, $sp, 8
; LA64-NEXT:    st.d $a1, $sp, 0
; LA64-NEXT:    addi.d $a1, $sp, 0
; LA64-NEXT:    ori $a4, $zero, 2
; LA64-NEXT:    ori $a5, $zero, 2
; LA64-NEXT:    move $a2, $a3
; LA64-NEXT:    move $a3, $a6
; LA64-NEXT:    pcaddu18i $ra, %call36(__atomic_compare_exchange_16)
; LA64-NEXT:    jirl $ra, $ra, 0
; LA64-NEXT:    ld.d $ra, $sp, 24 # 8-byte Folded Reload
; LA64-NEXT:    addi.d $sp, $sp, 32
; LA64-NEXT:    ret
;
; LA64-SCQ-LABEL: cmpxchg_i128_acquire_acquire:
; LA64-SCQ:       # %bb.0:
; LA64-SCQ-NEXT:  .LBB0_1: # =>This Inner Loop Header: Depth=1
; LA64-SCQ-NEXT:    ll.d $a5, $a0, 0
; LA64-SCQ-NEXT:    dbar 20
; LA64-SCQ-NEXT:    ld.d $a6, $a0, 8
; LA64-SCQ-NEXT:    bne $a5, $a1, .LBB0_3
; LA64-SCQ-NEXT:    bne $a6, $a2, .LBB0_3
; LA64-SCQ-NEXT:  # %bb.2: # in Loop: Header=BB0_1 Depth=1
; LA64-SCQ-NEXT:    move $a7, $a3
; LA64-SCQ-NEXT:    sc.q $a7, $a4, $a0
; LA64-SCQ-NEXT:    beq $a7, $zero, .LBB0_1
; LA64-SCQ-NEXT:    b .LBB0_4
; LA64-SCQ-NEXT:  .LBB0_3:
; LA64-SCQ-NEXT:    dbar 20
; LA64-SCQ-NEXT:  .LBB0_4:
; LA64-SCQ-NEXT:    ret
  %res = cmpxchg ptr %ptr, i128 %cmp, i128 %val acquire acquire
  ret void
}

define void @cmpxchg_i128_acquire_monotonic(ptr %ptr, i128 %cmp, i128 %val) nounwind {
; LA64-LABEL: cmpxchg_i128_acquire_monotonic:
; LA64:       # %bb.0:
; LA64-NEXT:    addi.d $sp, $sp, -32
; LA64-NEXT:    st.d $ra, $sp, 24 # 8-byte Folded Spill
; LA64-NEXT:    move $a5, $a4
; LA64-NEXT:    st.d $a2, $sp, 8
; LA64-NEXT:    st.d $a1, $sp, 0
; LA64-NEXT:    addi.d $a1, $sp, 0
; LA64-NEXT:    ori $a4, $zero, 2
; LA64-NEXT:    move $a2, $a3
; LA64-NEXT:    move $a3, $a5
; LA64-NEXT:    move $a5, $zero
; LA64-NEXT:    pcaddu18i $ra, %call36(__atomic_compare_exchange_16)
; LA64-NEXT:    jirl $ra, $ra, 0
; LA64-NEXT:    ld.d $ra, $sp, 24 # 8-byte Folded Reload
; LA64-NEXT:    addi.d $sp, $sp, 32
; LA64-NEXT:    ret
;
; LA64-SCQ-LABEL: cmpxchg_i128_acquire_monotonic:
; LA64-SCQ:       # %bb.0:
; LA64-SCQ-NEXT:  .LBB1_1: # =>This Inner Loop Header: Depth=1
; LA64-SCQ-NEXT:    ll.d $a5, $a0, 0
; LA64-SCQ-NEXT:    dbar 20
; LA64-SCQ-NEXT:    ld.d $a6, $a0, 8
; LA64-SCQ-NEXT:    bne $a5, $a1, .LBB1_3
; LA64-SCQ-NEXT:    bne $a6, $a2, .LBB1_3
; LA64-SCQ-NEXT:  # %bb.2: # in Loop: Header=BB1_1 Depth=1
; LA64-SCQ-NEXT:    move $a7, $a3
; LA64-SCQ-NEXT:    sc.q $a7, $a4, $a0
; LA64-SCQ-NEXT:    beq $a7, $zero, .LBB1_1
; LA64-SCQ-NEXT:    b .LBB1_4
; LA64-SCQ-NEXT:  .LBB1_3:
; LA64-SCQ-NEXT:    dbar 20
; LA64-SCQ-NEXT:  .LBB1_4:
; LA64-SCQ-NEXT:    ret
  %res = cmpxchg ptr %ptr, i128 %cmp, i128 %val acquire monotonic
  ret void
}

define i128 @cmpxchg_i128_acquire_acquire_reti128(ptr %ptr, i128 %cmp, i128 %val) nounwind {
; LA64-LABEL: cmpxchg_i128_acquire_acquire_reti128:
; LA64:       # %bb.0:
; LA64-NEXT:    addi.d $sp, $sp, -32
; LA64-NEXT:    st.d $ra, $sp, 24 # 8-byte Folded Spill
; LA64-NEXT:    move $a6, $a4
; LA64-NEXT:    st.d $a2, $sp, 8
; LA64-NEXT:    st.d $a1, $sp, 0
; LA64-NEXT:    addi.d $a1, $sp, 0
; LA64-NEXT:    ori $a4, $zero, 2
; LA64-NEXT:    ori $a5, $zero, 2
; LA64-NEXT:    move $a2, $a3
; LA64-NEXT:    move $a3, $a6
; LA64-NEXT:    pcaddu18i $ra, %call36(__atomic_compare_exchange_16)
; LA64-NEXT:    jirl $ra, $ra, 0
; LA64-NEXT:    ld.d $a1, $sp, 8
; LA64-NEXT:    ld.d $a0, $sp, 0
; LA64-NEXT:    ld.d $ra, $sp, 24 # 8-byte Folded Reload
; LA64-NEXT:    addi.d $sp, $sp, 32
; LA64-NEXT:    ret
;
; LA64-SCQ-LABEL: cmpxchg_i128_acquire_acquire_reti128:
; LA64-SCQ:       # %bb.0:
; LA64-SCQ-NEXT:  .LBB2_1: # =>This Inner Loop Header: Depth=1
; LA64-SCQ-NEXT:    ll.d $a5, $a0, 0
; LA64-SCQ-NEXT:    dbar 20
; LA64-SCQ-NEXT:    ld.d $a6, $a0, 8
; LA64-SCQ-NEXT:    bne $a5, $a1, .LBB2_3
; LA64-SCQ-NEXT:    bne $a6, $a2, .LBB2_3
; LA64-SCQ-NEXT:  # %bb.2: # in Loop: Header=BB2_1 Depth=1
; LA64-SCQ-NEXT:    move $a7, $a3
; LA64-SCQ-NEXT:    sc.q $a7, $a4, $a0
; LA64-SCQ-NEXT:    beq $a7, $zero, .LBB2_1
; LA64-SCQ-NEXT:    b .LBB2_4
; LA64-SCQ-NEXT:  .LBB2_3:
; LA64-SCQ-NEXT:    dbar 20
; LA64-SCQ-NEXT:  .LBB2_4:
; LA64-SCQ-NEXT:    move $a0, $a5
; LA64-SCQ-NEXT:    move $a1, $a6
; LA64-SCQ-NEXT:    ret
  %tmp = cmpxchg ptr %ptr, i128 %cmp, i128 %val acquire acquire
  %res = extractvalue { i128, i1 } %tmp, 0
  ret i128 %res
}

define i1 @cmpxchg_i128_acquire_acquire_reti1(ptr %ptr, i128 %cmp, i128 %val) nounwind {
; LA64-LABEL: cmpxchg_i128_acquire_acquire_reti1:
; LA64:       # %bb.0:
; LA64-NEXT:    addi.d $sp, $sp, -32
; LA64-NEXT:    st.d $ra, $sp, 24 # 8-byte Folded Spill
; LA64-NEXT:    move $a6, $a4
; LA64-NEXT:    st.d $a2, $sp, 8
; LA64-NEXT:    st.d $a1, $sp, 0
; LA64-NEXT:    addi.d $a1, $sp, 0
; LA64-NEXT:    ori $a4, $zero, 2
; LA64-NEXT:    ori $a5, $zero, 2
; LA64-NEXT:    move $a2, $a3
; LA64-NEXT:    move $a3, $a6
; LA64-NEXT:    pcaddu18i $ra, %call36(__atomic_compare_exchange_16)
; LA64-NEXT:    jirl $ra, $ra, 0
; LA64-NEXT:    ld.d $ra, $sp, 24 # 8-byte Folded Reload
; LA64-NEXT:    addi.d $sp, $sp, 32
; LA64-NEXT:    ret
;
; LA64-SCQ-LABEL: cmpxchg_i128_acquire_acquire_reti1:
; LA64-SCQ:       # %bb.0:
; LA64-SCQ-NEXT:  .LBB3_1: # =>This Inner Loop Header: Depth=1
; LA64-SCQ-NEXT:    ll.d $a5, $a0, 0
; LA64-SCQ-NEXT:    dbar 20
; LA64-SCQ-NEXT:    ld.d $a6, $a0, 8
; LA64-SCQ-NEXT:    bne $a5, $a1, .LBB3_3
; LA64-SCQ-NEXT:    bne $a6, $a2, .LBB3_3
; LA64-SCQ-NEXT:  # %bb.2: # in Loop: Header=BB3_1 Depth=1
; LA64-SCQ-NEXT:    move $a7, $a3
; LA64-SCQ-NEXT:    sc.q $a7, $a4, $a0
; LA64-SCQ-NEXT:    beq $a7, $zero, .LBB3_1
; LA64-SCQ-NEXT:    b .LBB3_4
; LA64-SCQ-NEXT:  .LBB3_3:
; LA64-SCQ-NEXT:    dbar 20
; LA64-SCQ-NEXT:  .LBB3_4:
; LA64-SCQ-NEXT:    xor $a0, $a6, $a2
; LA64-SCQ-NEXT:    xor $a1, $a5, $a1
; LA64-SCQ-NEXT:    or $a0, $a1, $a0
; LA64-SCQ-NEXT:    sltui $a0, $a0, 1
; LA64-SCQ-NEXT:    ret
  %tmp = cmpxchg ptr %ptr, i128 %cmp, i128 %val acquire acquire
  %res = extractvalue { i128, i1 } %tmp, 1
  ret i1 %res
}


define void @cmpxchg_i128_monotonic_monotonic(ptr %ptr, i128 %cmp, i128 %val) nounwind {
; LA64-LABEL: cmpxchg_i128_monotonic_monotonic:
; LA64:       # %bb.0:
; LA64-NEXT:    addi.d $sp, $sp, -32
; LA64-NEXT:    st.d $ra, $sp, 24 # 8-byte Folded Spill
; LA64-NEXT:    st.d $a2, $sp, 8
; LA64-NEXT:    st.d $a1, $sp, 0
; LA64-NEXT:    addi.d $a1, $sp, 0
; LA64-NEXT:    move $a2, $a3
; LA64-NEXT:    move $a3, $a4
; LA64-NEXT:    move $a4, $zero
; LA64-NEXT:    move $a5, $zero
; LA64-NEXT:    pcaddu18i $ra, %call36(__atomic_compare_exchange_16)
; LA64-NEXT:    jirl $ra, $ra, 0
; LA64-NEXT:    ld.d $ra, $sp, 24 # 8-byte Folded Reload
; LA64-NEXT:    addi.d $sp, $sp, 32
; LA64-NEXT:    ret
;
; NO-LD-SEQ-SA-LABEL: cmpxchg_i128_monotonic_monotonic:
; NO-LD-SEQ-SA:       # %bb.0:
; NO-LD-SEQ-SA-NEXT:  .LBB4_1: # =>This Inner Loop Header: Depth=1
; NO-LD-SEQ-SA-NEXT:    ll.d $a5, $a0, 0
; NO-LD-SEQ-SA-NEXT:    dbar 20
; NO-LD-SEQ-SA-NEXT:    ld.d $a6, $a0, 8
; NO-LD-SEQ-SA-NEXT:    bne $a5, $a1, .LBB4_3
; NO-LD-SEQ-SA-NEXT:    bne $a6, $a2, .LBB4_3
; NO-LD-SEQ-SA-NEXT:  # %bb.2: # in Loop: Header=BB4_1 Depth=1
; NO-LD-SEQ-SA-NEXT:    move $a7, $a3
; NO-LD-SEQ-SA-NEXT:    sc.q $a7, $a4, $a0
; NO-LD-SEQ-SA-NEXT:    beq $a7, $zero, .LBB4_1
; NO-LD-SEQ-SA-NEXT:    b .LBB4_4
; NO-LD-SEQ-SA-NEXT:  .LBB4_3:
; NO-LD-SEQ-SA-NEXT:    dbar 1792
; NO-LD-SEQ-SA-NEXT:  .LBB4_4:
; NO-LD-SEQ-SA-NEXT:    ret
;
; LD-SEQ-SA-LABEL: cmpxchg_i128_monotonic_monotonic:
; LD-SEQ-SA:       # %bb.0:
; LD-SEQ-SA-NEXT:  .LBB4_1: # =>This Inner Loop Header: Depth=1
; LD-SEQ-SA-NEXT:    ll.d $a5, $a0, 0
; LD-SEQ-SA-NEXT:    dbar 20
; LD-SEQ-SA-NEXT:    ld.d $a6, $a0, 8
; LD-SEQ-SA-NEXT:    bne $a5, $a1, .LBB4_3
; LD-SEQ-SA-NEXT:    bne $a6, $a2, .LBB4_3
; LD-SEQ-SA-NEXT:  # %bb.2: # in Loop: Header=BB4_1 Depth=1
; LD-SEQ-SA-NEXT:    move $a7, $a3
; LD-SEQ-SA-NEXT:    sc.q $a7, $a4, $a0
; LD-SEQ-SA-NEXT:    beq $a7, $zero, .LBB4_1
; LD-SEQ-SA-NEXT:    b .LBB4_4
; LD-SEQ-SA-NEXT:  .LBB4_3:
; LD-SEQ-SA-NEXT:  .LBB4_4:
; LD-SEQ-SA-NEXT:    ret
  %res = cmpxchg ptr %ptr, i128 %cmp, i128 %val monotonic monotonic
  ret void
}

define i128 @cmpxchg_i128_monotonic_monotonic_reti128(ptr %ptr, i128 %cmp, i128 %val) nounwind {
; LA64-LABEL: cmpxchg_i128_monotonic_monotonic_reti128:
; LA64:       # %bb.0:
; LA64-NEXT:    addi.d $sp, $sp, -32
; LA64-NEXT:    st.d $ra, $sp, 24 # 8-byte Folded Spill
; LA64-NEXT:    st.d $a2, $sp, 8
; LA64-NEXT:    st.d $a1, $sp, 0
; LA64-NEXT:    addi.d $a1, $sp, 0
; LA64-NEXT:    move $a2, $a3
; LA64-NEXT:    move $a3, $a4
; LA64-NEXT:    move $a4, $zero
; LA64-NEXT:    move $a5, $zero
; LA64-NEXT:    pcaddu18i $ra, %call36(__atomic_compare_exchange_16)
; LA64-NEXT:    jirl $ra, $ra, 0
; LA64-NEXT:    ld.d $a1, $sp, 8
; LA64-NEXT:    ld.d $a0, $sp, 0
; LA64-NEXT:    ld.d $ra, $sp, 24 # 8-byte Folded Reload
; LA64-NEXT:    addi.d $sp, $sp, 32
; LA64-NEXT:    ret
;
; NO-LD-SEQ-SA-LABEL: cmpxchg_i128_monotonic_monotonic_reti128:
; NO-LD-SEQ-SA:       # %bb.0:
; NO-LD-SEQ-SA-NEXT:  .LBB5_1: # =>This Inner Loop Header: Depth=1
; NO-LD-SEQ-SA-NEXT:    ll.d $a5, $a0, 0
; NO-LD-SEQ-SA-NEXT:    dbar 20
; NO-LD-SEQ-SA-NEXT:    ld.d $a6, $a0, 8
; NO-LD-SEQ-SA-NEXT:    bne $a5, $a1, .LBB5_3
; NO-LD-SEQ-SA-NEXT:    bne $a6, $a2, .LBB5_3
; NO-LD-SEQ-SA-NEXT:  # %bb.2: # in Loop: Header=BB5_1 Depth=1
; NO-LD-SEQ-SA-NEXT:    move $a7, $a3
; NO-LD-SEQ-SA-NEXT:    sc.q $a7, $a4, $a0
; NO-LD-SEQ-SA-NEXT:    beq $a7, $zero, .LBB5_1
; NO-LD-SEQ-SA-NEXT:    b .LBB5_4
; NO-LD-SEQ-SA-NEXT:  .LBB5_3:
; NO-LD-SEQ-SA-NEXT:    dbar 1792
; NO-LD-SEQ-SA-NEXT:  .LBB5_4:
; NO-LD-SEQ-SA-NEXT:    move $a0, $a5
; NO-LD-SEQ-SA-NEXT:    move $a1, $a6
; NO-LD-SEQ-SA-NEXT:    ret
;
; LD-SEQ-SA-LABEL: cmpxchg_i128_monotonic_monotonic_reti128:
; LD-SEQ-SA:       # %bb.0:
; LD-SEQ-SA-NEXT:  .LBB5_1: # =>This Inner Loop Header: Depth=1
; LD-SEQ-SA-NEXT:    ll.d $a5, $a0, 0
; LD-SEQ-SA-NEXT:    dbar 20
; LD-SEQ-SA-NEXT:    ld.d $a6, $a0, 8
; LD-SEQ-SA-NEXT:    bne $a5, $a1, .LBB5_3
; LD-SEQ-SA-NEXT:    bne $a6, $a2, .LBB5_3
; LD-SEQ-SA-NEXT:  # %bb.2: # in Loop: Header=BB5_1 Depth=1
; LD-SEQ-SA-NEXT:    move $a7, $a3
; LD-SEQ-SA-NEXT:    sc.q $a7, $a4, $a0
; LD-SEQ-SA-NEXT:    beq $a7, $zero, .LBB5_1
; LD-SEQ-SA-NEXT:    b .LBB5_4
; LD-SEQ-SA-NEXT:  .LBB5_3:
; LD-SEQ-SA-NEXT:  .LBB5_4:
; LD-SEQ-SA-NEXT:    move $a0, $a5
; LD-SEQ-SA-NEXT:    move $a1, $a6
; LD-SEQ-SA-NEXT:    ret
  %tmp = cmpxchg ptr %ptr, i128 %cmp, i128 %val monotonic monotonic
  %res = extractvalue { i128, i1 } %tmp, 0
  ret i128 %res
}

define i1 @cmpxchg_i128_monotonic_monotonic_reti1(ptr %ptr, i128 %cmp, i128 %val) nounwind {
; LA64-LABEL: cmpxchg_i128_monotonic_monotonic_reti1:
; LA64:       # %bb.0:
; LA64-NEXT:    addi.d $sp, $sp, -32
; LA64-NEXT:    st.d $ra, $sp, 24 # 8-byte Folded Spill
; LA64-NEXT:    st.d $a2, $sp, 8
; LA64-NEXT:    st.d $a1, $sp, 0
; LA64-NEXT:    addi.d $a1, $sp, 0
; LA64-NEXT:    move $a2, $a3
; LA64-NEXT:    move $a3, $a4
; LA64-NEXT:    move $a4, $zero
; LA64-NEXT:    move $a5, $zero
; LA64-NEXT:    pcaddu18i $ra, %call36(__atomic_compare_exchange_16)
; LA64-NEXT:    jirl $ra, $ra, 0
; LA64-NEXT:    ld.d $ra, $sp, 24 # 8-byte Folded Reload
; LA64-NEXT:    addi.d $sp, $sp, 32
; LA64-NEXT:    ret
;
; NO-LD-SEQ-SA-LABEL: cmpxchg_i128_monotonic_monotonic_reti1:
; NO-LD-SEQ-SA:       # %bb.0:
; NO-LD-SEQ-SA-NEXT:  .LBB6_1: # =>This Inner Loop Header: Depth=1
; NO-LD-SEQ-SA-NEXT:    ll.d $a5, $a0, 0
; NO-LD-SEQ-SA-NEXT:    dbar 20
; NO-LD-SEQ-SA-NEXT:    ld.d $a6, $a0, 8
; NO-LD-SEQ-SA-NEXT:    bne $a5, $a1, .LBB6_3
; NO-LD-SEQ-SA-NEXT:    bne $a6, $a2, .LBB6_3
; NO-LD-SEQ-SA-NEXT:  # %bb.2: # in Loop: Header=BB6_1 Depth=1
; NO-LD-SEQ-SA-NEXT:    move $a7, $a3
; NO-LD-SEQ-SA-NEXT:    sc.q $a7, $a4, $a0
; NO-LD-SEQ-SA-NEXT:    beq $a7, $zero, .LBB6_1
; NO-LD-SEQ-SA-NEXT:    b .LBB6_4
; NO-LD-SEQ-SA-NEXT:  .LBB6_3:
; NO-LD-SEQ-SA-NEXT:    dbar 1792
; NO-LD-SEQ-SA-NEXT:  .LBB6_4:
; NO-LD-SEQ-SA-NEXT:    xor $a0, $a6, $a2
; NO-LD-SEQ-SA-NEXT:    xor $a1, $a5, $a1
; NO-LD-SEQ-SA-NEXT:    or $a0, $a1, $a0
; NO-LD-SEQ-SA-NEXT:    sltui $a0, $a0, 1
; NO-LD-SEQ-SA-NEXT:    ret
;
; LD-SEQ-SA-LABEL: cmpxchg_i128_monotonic_monotonic_reti1:
; LD-SEQ-SA:       # %bb.0:
; LD-SEQ-SA-NEXT:  .LBB6_1: # =>This Inner Loop Header: Depth=1
; LD-SEQ-SA-NEXT:    ll.d $a5, $a0, 0
; LD-SEQ-SA-NEXT:    dbar 20
; LD-SEQ-SA-NEXT:    ld.d $a6, $a0, 8
; LD-SEQ-SA-NEXT:    bne $a5, $a1, .LBB6_3
; LD-SEQ-SA-NEXT:    bne $a6, $a2, .LBB6_3
; LD-SEQ-SA-NEXT:  # %bb.2: # in Loop: Header=BB6_1 Depth=1
; LD-SEQ-SA-NEXT:    move $a7, $a3
; LD-SEQ-SA-NEXT:    sc.q $a7, $a4, $a0
; LD-SEQ-SA-NEXT:    beq $a7, $zero, .LBB6_1
; LD-SEQ-SA-NEXT:    b .LBB6_4
; LD-SEQ-SA-NEXT:  .LBB6_3:
; LD-SEQ-SA-NEXT:  .LBB6_4:
; LD-SEQ-SA-NEXT:    xor $a0, $a6, $a2
; LD-SEQ-SA-NEXT:    xor $a1, $a5, $a1
; LD-SEQ-SA-NEXT:    or $a0, $a1, $a0
; LD-SEQ-SA-NEXT:    sltui $a0, $a0, 1
; LD-SEQ-SA-NEXT:    ret
  %tmp = cmpxchg ptr %ptr, i128 %cmp, i128 %val monotonic monotonic
  %res = extractvalue { i128, i1 } %tmp, 1
  ret i1 %res
}
