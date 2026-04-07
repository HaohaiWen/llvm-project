; RUN: llc < %s -mtriple=x86_64-pc-windows-msvc -basic-block-address-map | FileCheck %s

; Verify that COFF emits .llvm_bb_addr_map for both non-COMDAT and COMDAT
; text sections, and that COMDAT mapping is associative to foo.

define i32 @bar(i32 %x) {
entry:
  %add = add nsw i32 %x, 2
  ret i32 %add
}

$foo = comdat any

define linkonce_odr i32 @foo(i32 %x) comdat {
entry:
  %add = add nsw i32 %x, 1
  ret i32 %add
}

; CHECK: .section        .llvm_bb_addr_map,"drD"
; CHECK: .section        .text,"xr",discard,foo
; CHECK: .section        .llvm_bb_addr_map,"drD",associative,foo
