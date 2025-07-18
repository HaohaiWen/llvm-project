; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 5
; RUN: llc < %s -mtriple=s390x-linux-gnu -mcpu=z13 | FileCheck %s --check-prefix=NO-MISC3
; RUN: llc < %s -mtriple=s390x-linux-gnu -mcpu=z15 | FileCheck %s --check-prefix=MISC3

; test that masked-merge code is generated as "xor;and;xor" sequence or
; "andn ; and; or" if and-not is available.

define i32 @masked_merge0(i32 %a0, i32 %a1, i32 %a2) {
; NO-MISC3-LABEL: masked_merge0:
; NO-MISC3:       # %bb.0:
; NO-MISC3-NEXT:    xr %r3, %r4
; NO-MISC3-NEXT:    nr %r2, %r3
; NO-MISC3-NEXT:    xr %r2, %r4
; NO-MISC3-NEXT:    br %r14
;
; MISC3-LABEL: masked_merge0:
; MISC3:       # %bb.0:
; MISC3-NEXT:    nr %r3, %r2
; MISC3-NEXT:    ncrk %r2, %r4, %r2
; MISC3-NEXT:    or %r2, %r3
; MISC3-NEXT:    br %r14
  %and0 = and i32 %a0, %a1
  %not = xor i32 %a0, -1
  %and1 = and i32 %not, %a2
  %or = or i32 %and0, %and1
  ret i32 %or
}

define i16 @masked_merge1(i16 %a0, i16 %a1, i16 %a2) {
; NO-MISC3-LABEL: masked_merge1:
; NO-MISC3:       # %bb.0:
; NO-MISC3-NEXT:    xr %r3, %r4
; NO-MISC3-NEXT:    nr %r2, %r3
; NO-MISC3-NEXT:    xr %r2, %r4
; NO-MISC3-NEXT:    br %r14
;
; MISC3-LABEL: masked_merge1:
; MISC3:       # %bb.0:
; MISC3-NEXT:    ncrk %r0, %r4, %r2
; MISC3-NEXT:    nr %r2, %r3
; MISC3-NEXT:    or %r2, %r0
; MISC3-NEXT:    br %r14
  %and0 = and i16 %a0, %a1
  %not = xor i16 %a0, -1
  %and1 = and i16 %a2, %not
  %or = or i16 %and0, %and1
  ret i16 %or
}

define i8 @masked_merge2(i8 %a0, i8 %a1, i8 %a2) {
; NO-MISC3-LABEL: masked_merge2:
; NO-MISC3:       # %bb.0:
; NO-MISC3-NEXT:    lr %r2, %r3
; NO-MISC3-NEXT:    br %r14
;
; MISC3-LABEL: masked_merge2:
; MISC3:       # %bb.0:
; MISC3-NEXT:    lr %r2, %r3
; MISC3-NEXT:    br %r14
  %not = xor i8 %a0, -1
  %and0 = and i8 %not, %a1
  %and1 = and i8 %a1, %a0
  %or = or i8 %and0, %and1
  ret i8 %or
}

define i64 @masked_merge3(i64 %a0, i64 %a1, i64 %a2) {
; NO-MISC3-LABEL: masked_merge3:
; NO-MISC3:       # %bb.0:
; NO-MISC3-NEXT:    lcgr %r0, %r4
; NO-MISC3-NEXT:    aghi %r0, -1
; NO-MISC3-NEXT:    xgr %r3, %r0
; NO-MISC3-NEXT:    ngr %r3, %r2
; NO-MISC3-NEXT:    xgr %r3, %r2
; NO-MISC3-NEXT:    xgrk %r2, %r3, %r0
; NO-MISC3-NEXT:    br %r14
;
; MISC3-LABEL: masked_merge3:
; MISC3:       # %bb.0:
; MISC3-NEXT:    lcgr %r0, %r2
; MISC3-NEXT:    aghi %r0, -1
; MISC3-NEXT:    ncgrk %r0, %r0, %r4
; MISC3-NEXT:    ncgrk %r2, %r2, %r3
; MISC3-NEXT:    ogr %r2, %r0
; MISC3-NEXT:    br %r14
  %v0 = xor i64 %a1, -1
  %v1 = xor i64 %a2, -1
  %not = xor i64 %a0, -1
  %and0 = and i64 %not, %v1
  %and1 = and i64 %v0, %a0
  %or = or i64 %and0, %and1
  ret i64 %or
}

define i32 @not_a_masked_merge0(i32 %a0, i32 %a1, i32 %a2) {
; NO-MISC3-LABEL: not_a_masked_merge0:
; NO-MISC3:       # %bb.0:
; NO-MISC3-NEXT:    lcr %r0, %r2
; NO-MISC3-NEXT:    nr %r3, %r2
; NO-MISC3-NEXT:    nr %r0, %r4
; NO-MISC3-NEXT:    ork %r2, %r3, %r0
; NO-MISC3-NEXT:    br %r14
;
; MISC3-LABEL: not_a_masked_merge0:
; MISC3:       # %bb.0:
; MISC3-NEXT:    lcr %r0, %r2
; MISC3-NEXT:    nr %r3, %r2
; MISC3-NEXT:    nr %r0, %r4
; MISC3-NEXT:    ork %r2, %r3, %r0
; MISC3-NEXT:    br %r14
  %and0 = and i32 %a0, %a1
  %not_a_not = sub i32 0, %a0
  %and1 = and i32 %not_a_not, %a2
  %or = or i32 %and0, %and1
  ret i32 %or
}

define i32 @not_a_masked_merge1(i32 %a0, i32 %a1, i32 %a2, i32 %a3) {
; NO-MISC3-LABEL: not_a_masked_merge1:
; NO-MISC3:       # %bb.0:
; NO-MISC3-NEXT:    xilf %r5, 4294967295
; NO-MISC3-NEXT:    nr %r2, %r3
; NO-MISC3-NEXT:    nr %r4, %r5
; NO-MISC3-NEXT:    or %r2, %r4
; NO-MISC3-NEXT:    br %r14
;
; MISC3-LABEL: not_a_masked_merge1:
; MISC3:       # %bb.0:
; MISC3-NEXT:    nr %r2, %r3
; MISC3-NEXT:    ncrk %r0, %r4, %r5
; MISC3-NEXT:    or %r2, %r0
; MISC3-NEXT:    br %r14
  %and0 = and i32 %a0, %a1
  %not = xor i32 %a3, -1
  %and1 = and i32 %not, %a2
  %or = or i32 %and0, %and1
  ret i32 %or
}

define i32 @not_a_masked_merge2(i32 %a0, i32 %a1, i32 %a2) {
; NO-MISC3-LABEL: not_a_masked_merge2:
; NO-MISC3:       # %bb.0:
; NO-MISC3-NEXT:    or %r3, %r2
; NO-MISC3-NEXT:    xilf %r2, 4294967295
; NO-MISC3-NEXT:    nr %r2, %r4
; NO-MISC3-NEXT:    or %r2, %r3
; NO-MISC3-NEXT:    br %r14
;
; MISC3-LABEL: not_a_masked_merge2:
; MISC3:       # %bb.0:
; MISC3-NEXT:    or %r3, %r2
; MISC3-NEXT:    ncrk %r2, %r4, %r2
; MISC3-NEXT:    or %r2, %r3
; MISC3-NEXT:    br %r14
  %not_an_and0 = or i32 %a0, %a1
  %not = xor i32 %a0, -1
  %and1 = and i32 %not, %a2
  %or = or i32 %not_an_and0, %and1
  ret i32 %or
}

define i32 @not_a_masked_merge3(i32 %a0, i32 %a1, i32 %a2) {
; NO-MISC3-LABEL: not_a_masked_merge3:
; NO-MISC3:       # %bb.0:
; NO-MISC3-NEXT:    nr %r3, %r2
; NO-MISC3-NEXT:    xr %r2, %r4
; NO-MISC3-NEXT:    xilf %r2, 4294967295
; NO-MISC3-NEXT:    or %r2, %r3
; NO-MISC3-NEXT:    br %r14
;
; MISC3-LABEL: not_a_masked_merge3:
; MISC3:       # %bb.0:
; MISC3-NEXT:    nr %r3, %r2
; MISC3-NEXT:    xr %r2, %r4
; MISC3-NEXT:    ocrk %r2, %r3, %r2
; MISC3-NEXT:    br %r14
  %and0 = and i32 %a0, %a1
  %not = xor i32 %a0, -1
  %not_an_and1 = xor i32 %not, %a2
  %or = or i32 %and0, %not_an_and1
  ret i32 %or
}

define i32 @not_a_masked_merge4(i32 %a0, i32 %a1, i32 %a2) {
; NO-MISC3-LABEL: not_a_masked_merge4:
; NO-MISC3:       # %bb.0:
; NO-MISC3-NEXT:    nr %r2, %r3
; NO-MISC3-NEXT:    br %r14
;
; MISC3-LABEL: not_a_masked_merge4:
; MISC3:       # %bb.0:
; MISC3-NEXT:    nr %r2, %r3
; MISC3-NEXT:    br %r14
  %and0 = and i32 %a0, %a1
  %not = xor i32 %a2, -1
  %and1 = and i32 %not, %a2
  %or = or i32 %and0, %and1
  ret i32 %or
}

define i32 @masked_merge_no_transform0(i32 %a0, i32 %a1, i32 %a2, ptr %p1) {
; NO-MISC3-LABEL: masked_merge_no_transform0:
; NO-MISC3:       # %bb.0:
; NO-MISC3-NEXT:    nr %r3, %r2
; NO-MISC3-NEXT:    xilf %r2, 4294967295
; NO-MISC3-NEXT:    nr %r2, %r4
; NO-MISC3-NEXT:    or %r2, %r3
; NO-MISC3-NEXT:    st %r3, 0(%r5)
; NO-MISC3-NEXT:    br %r14
;
; MISC3-LABEL: masked_merge_no_transform0:
; MISC3:       # %bb.0:
; MISC3-NEXT:    nr %r3, %r2
; MISC3-NEXT:    ncrk %r2, %r4, %r2
; MISC3-NEXT:    or %r2, %r3
; MISC3-NEXT:    st %r3, 0(%r5)
; MISC3-NEXT:    br %r14
  %and0 = and i32 %a0, %a1
  %not = xor i32 %a0, -1
  %and1 = and i32 %not, %a2
  %or = or i32 %and0, %and1
  store i32 %and0, ptr %p1
  ret i32 %or
}

define i32 @masked_merge_no_transform1(i32 %a0, i32 %a1, i32 %a2, ptr %p1) {
; NO-MISC3-LABEL: masked_merge_no_transform1:
; NO-MISC3:       # %bb.0:
; NO-MISC3-NEXT:    nrk %r0, %r2, %r3
; NO-MISC3-NEXT:    xilf %r2, 4294967295
; NO-MISC3-NEXT:    nr %r4, %r2
; NO-MISC3-NEXT:    or %r0, %r4
; NO-MISC3-NEXT:    st %r2, 0(%r5)
; NO-MISC3-NEXT:    lr %r2, %r0
; NO-MISC3-NEXT:    br %r14
;
; MISC3-LABEL: masked_merge_no_transform1:
; MISC3:       # %bb.0:
; MISC3-NEXT:    nrk %r0, %r2, %r3
; MISC3-NEXT:    ncrk %r1, %r4, %r2
; MISC3-NEXT:    xilf %r2, 4294967295
; MISC3-NEXT:    or %r0, %r1
; MISC3-NEXT:    st %r2, 0(%r5)
; MISC3-NEXT:    lr %r2, %r0
; MISC3-NEXT:    br %r14
  %and0 = and i32 %a0, %a1
  %not = xor i32 %a0, -1
  %and1 = and i32 %not, %a2
  %or = or i32 %and0, %and1
  store i32 %not, ptr %p1
  ret i32 %or
}

define i32 @masked_merge_no_transform2(i32 %a0, i32 %a1, i32 %a2, ptr %p1) {
; NO-MISC3-LABEL: masked_merge_no_transform2:
; NO-MISC3:       # %bb.0:
; NO-MISC3-NEXT:    nr %r3, %r2
; NO-MISC3-NEXT:    xilf %r2, 4294967295
; NO-MISC3-NEXT:    nr %r4, %r2
; NO-MISC3-NEXT:    ork %r2, %r3, %r4
; NO-MISC3-NEXT:    st %r4, 0(%r5)
; NO-MISC3-NEXT:    br %r14
;
; MISC3-LABEL: masked_merge_no_transform2:
; MISC3:       # %bb.0:
; MISC3-NEXT:    nr %r3, %r2
; MISC3-NEXT:    ncrk %r0, %r4, %r2
; MISC3-NEXT:    ork %r2, %r3, %r0
; MISC3-NEXT:    st %r0, 0(%r5)
; MISC3-NEXT:    br %r14
  %and0 = and i32 %a0, %a1
  %not = xor i32 %a0, -1
  %and1 = and i32 %not, %a2
  %or = or i32 %and0, %and1
  store i32 %and1, ptr %p1
  ret i32 %or
}
