//===--- PPC.cpp - Implement PPC target feature support -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements PPC TargetInfo objects.
//
//===----------------------------------------------------------------------===//

#include "PPC.h"
#include "clang/Basic/Diagnostic.h"
#include "clang/Basic/MacroBuilder.h"
#include "clang/Basic/TargetBuiltins.h"
#include "llvm/TargetParser/PPCTargetParser.h"
#include <optional>

using namespace clang;
using namespace clang::targets;

static constexpr int NumBuiltins =
    clang::PPC::LastTSBuiltin - Builtin::FirstTSBuiltin;

static constexpr llvm::StringTable BuiltinStrings =
    CLANG_BUILTIN_STR_TABLE_START
#define BUILTIN CLANG_BUILTIN_STR_TABLE
#define TARGET_BUILTIN CLANG_TARGET_BUILTIN_STR_TABLE
#include "clang/Basic/BuiltinsPPC.def"
    ;

static constexpr auto BuiltinInfos = Builtin::MakeInfos<NumBuiltins>({
#define BUILTIN CLANG_BUILTIN_ENTRY
#define TARGET_BUILTIN CLANG_TARGET_BUILTIN_ENTRY
#define LIBBUILTIN CLANG_LIBBUILTIN_ENTRY
#include "clang/Basic/BuiltinsPPC.def"
});

/// handleTargetFeatures - Perform initialization based on the user
/// configured set of features.
bool PPCTargetInfo::handleTargetFeatures(std::vector<std::string> &Features,
                                         DiagnosticsEngine &Diags) {
  FloatABI = HardFloat;
  for (const auto &Feature : Features) {
    if (Feature == "+altivec") {
      HasAltivec = true;
    } else if (Feature == "+vsx") {
      HasVSX = true;
    } else if (Feature == "+power8-vector") {
      HasP8Vector = true;
    } else if (Feature == "+crypto") {
      HasP8Crypto = true;
    } else if (Feature == "+htm") {
      HasHTM = true;
    } else if (Feature == "+float128") {
      HasFloat128 = !getTriple().isOSAIX();
    } else if (Feature == "+power9-vector") {
      HasP9Vector = true;
    } else if (Feature == "+power10-vector") {
      HasP10Vector = true;
    } else if (Feature == "+pcrelative-memops") {
      HasPCRelativeMemops = true;
    } else if (Feature == "+spe" || Feature == "+efpu2") {
      HasStrictFP = false;
      HasSPE = true;
      LongDoubleWidth = LongDoubleAlign = 64;
      LongDoubleFormat = &llvm::APFloat::IEEEdouble();
    } else if (Feature == "+frsqrte") {
      HasFrsqrte = true;
    } else if (Feature == "+frsqrtes") {
      HasFrsqrtes = true;
    } else if (Feature == "-hard-float") {
      FloatABI = SoftFloat;
    } else if (Feature == "+mma") {
      HasMMA = true;
    } else if (Feature == "+rop-protect") {
      HasROPProtect = true;
    } else if (Feature == "+quadword-atomics") {
      HasQuadwordAtomics = true;
    } else if (Feature == "+longcall") {
      UseLongCalls = true;
    }
    // TODO: Finish this list and add an assert that we've handled them
    // all.
  }

  return true;
}

static void defineXLCompatMacros(MacroBuilder &Builder) {
  Builder.defineMacro("__builtin_national2packed",
                      "__builtin_ppc_national2packed");
  Builder.defineMacro("__builtin_packed2national",
                      "__builtin_ppc_packed2national");
  Builder.defineMacro("__builtin_packed2zoned", "__builtin_ppc_packed2zoned");
  Builder.defineMacro("__builtin_zoned2packed", "__builtin_ppc_zoned2packed");
  Builder.defineMacro("__cdtbcd", "__builtin_ppc_cdtbcd");
  Builder.defineMacro("__cbcdtd", "__builtin_ppc_cbcdtd");
  Builder.defineMacro("__addg6s", "__builtin_ppc_addg6s");
  Builder.defineMacro("__popcntb", "__builtin_ppc_popcntb");
  Builder.defineMacro("__poppar4", "__builtin_ppc_poppar4");
  Builder.defineMacro("__poppar8", "__builtin_ppc_poppar8");
  Builder.defineMacro("__eieio", "__builtin_ppc_eieio");
  Builder.defineMacro("__iospace_eieio", "__builtin_ppc_iospace_eieio");
  Builder.defineMacro("__isync", "__builtin_ppc_isync");
  Builder.defineMacro("__lwsync", "__builtin_ppc_lwsync");
  Builder.defineMacro("__iospace_lwsync", "__builtin_ppc_iospace_lwsync");
  Builder.defineMacro("__sync", "__builtin_ppc_sync");
  Builder.defineMacro("__iospace_sync", "__builtin_ppc_iospace_sync");
  Builder.defineMacro("__dcbfl", "__builtin_ppc_dcbfl");
  Builder.defineMacro("__dcbflp", "__builtin_ppc_dcbflp");
  Builder.defineMacro("__dcbst", "__builtin_ppc_dcbst");
  Builder.defineMacro("__dcbt", "__builtin_ppc_dcbt");
  Builder.defineMacro("__dcbtst", "__builtin_ppc_dcbtst");
  Builder.defineMacro("__dcbz", "__builtin_ppc_dcbz");
  Builder.defineMacro("__icbt", "__builtin_ppc_icbt");
  Builder.defineMacro("__compare_and_swap", "__builtin_ppc_compare_and_swap");
  Builder.defineMacro("__compare_and_swaplp",
                      "__builtin_ppc_compare_and_swaplp");
  Builder.defineMacro("__fetch_and_add", "__builtin_ppc_fetch_and_add");
  Builder.defineMacro("__fetch_and_addlp", "__builtin_ppc_fetch_and_addlp");
  Builder.defineMacro("__fetch_and_and", "__builtin_ppc_fetch_and_and");
  Builder.defineMacro("__fetch_and_andlp", "__builtin_ppc_fetch_and_andlp");
  Builder.defineMacro("__fetch_and_or", "__builtin_ppc_fetch_and_or");
  Builder.defineMacro("__fetch_and_orlp", "__builtin_ppc_fetch_and_orlp");
  Builder.defineMacro("__fetch_and_swap", "__builtin_ppc_fetch_and_swap");
  Builder.defineMacro("__fetch_and_swaplp", "__builtin_ppc_fetch_and_swaplp");
  Builder.defineMacro("__ldarx", "__builtin_ppc_ldarx");
  Builder.defineMacro("__lwarx", "__builtin_ppc_lwarx");
  Builder.defineMacro("__lharx", "__builtin_ppc_lharx");
  Builder.defineMacro("__lbarx", "__builtin_ppc_lbarx");
  Builder.defineMacro("__stfiw", "__builtin_ppc_stfiw");
  Builder.defineMacro("__stdcx", "__builtin_ppc_stdcx");
  Builder.defineMacro("__stwcx", "__builtin_ppc_stwcx");
  Builder.defineMacro("__sthcx", "__builtin_ppc_sthcx");
  Builder.defineMacro("__stbcx", "__builtin_ppc_stbcx");
  Builder.defineMacro("__tdw", "__builtin_ppc_tdw");
  Builder.defineMacro("__tw", "__builtin_ppc_tw");
  Builder.defineMacro("__trap", "__builtin_ppc_trap");
  Builder.defineMacro("__trapd", "__builtin_ppc_trapd");
  Builder.defineMacro("__fcfid", "__builtin_ppc_fcfid");
  Builder.defineMacro("__fcfud", "__builtin_ppc_fcfud");
  Builder.defineMacro("__fctid", "__builtin_ppc_fctid");
  Builder.defineMacro("__fctidz", "__builtin_ppc_fctidz");
  Builder.defineMacro("__fctiw", "__builtin_ppc_fctiw");
  Builder.defineMacro("__fctiwz", "__builtin_ppc_fctiwz");
  Builder.defineMacro("__fctudz", "__builtin_ppc_fctudz");
  Builder.defineMacro("__fctuwz", "__builtin_ppc_fctuwz");
  Builder.defineMacro("__cmpeqb", "__builtin_ppc_cmpeqb");
  Builder.defineMacro("__cmprb", "__builtin_ppc_cmprb");
  Builder.defineMacro("__setb", "__builtin_ppc_setb");
  Builder.defineMacro("__cmpb", "__builtin_ppc_cmpb");
  Builder.defineMacro("__mulhd", "__builtin_ppc_mulhd");
  Builder.defineMacro("__mulhdu", "__builtin_ppc_mulhdu");
  Builder.defineMacro("__mulhw", "__builtin_ppc_mulhw");
  Builder.defineMacro("__mulhwu", "__builtin_ppc_mulhwu");
  Builder.defineMacro("__maddhd", "__builtin_ppc_maddhd");
  Builder.defineMacro("__maddhdu", "__builtin_ppc_maddhdu");
  Builder.defineMacro("__maddld", "__builtin_ppc_maddld");
  Builder.defineMacro("__rlwnm", "__builtin_ppc_rlwnm");
  Builder.defineMacro("__rlwimi", "__builtin_ppc_rlwimi");
  Builder.defineMacro("__rldimi", "__builtin_ppc_rldimi");
  Builder.defineMacro("__load2r", "__builtin_ppc_load2r");
  Builder.defineMacro("__load4r", "__builtin_ppc_load4r");
  Builder.defineMacro("__load8r", "__builtin_ppc_load8r");
  Builder.defineMacro("__store2r", "__builtin_ppc_store2r");
  Builder.defineMacro("__store4r", "__builtin_ppc_store4r");
  Builder.defineMacro("__store8r", "__builtin_ppc_store8r");
  Builder.defineMacro("__extract_exp", "__builtin_ppc_extract_exp");
  Builder.defineMacro("__extract_sig", "__builtin_ppc_extract_sig");
  Builder.defineMacro("__mtfsb0", "__builtin_ppc_mtfsb0");
  Builder.defineMacro("__mtfsb1", "__builtin_ppc_mtfsb1");
  Builder.defineMacro("__mtfsf", "__builtin_ppc_mtfsf");
  Builder.defineMacro("__mtfsfi", "__builtin_ppc_mtfsfi");
  Builder.defineMacro("__insert_exp", "__builtin_ppc_insert_exp");
  Builder.defineMacro("__fmsub", "__builtin_ppc_fmsub");
  Builder.defineMacro("__fmsubs", "__builtin_ppc_fmsubs");
  Builder.defineMacro("__fnmadd", "__builtin_ppc_fnmadd");
  Builder.defineMacro("__fnmadds", "__builtin_ppc_fnmadds");
  Builder.defineMacro("__fnmsub", "__builtin_ppc_fnmsub");
  Builder.defineMacro("__fnmsubs", "__builtin_ppc_fnmsubs");
  Builder.defineMacro("__fre", "__builtin_ppc_fre");
  Builder.defineMacro("__fres", "__builtin_ppc_fres");
  Builder.defineMacro("__swdiv_nochk", "__builtin_ppc_swdiv_nochk");
  Builder.defineMacro("__swdivs_nochk", "__builtin_ppc_swdivs_nochk");
  Builder.defineMacro("__alloca", "__builtin_alloca");
  Builder.defineMacro("__vcipher", "__builtin_altivec_crypto_vcipher");
  Builder.defineMacro("__vcipherlast", "__builtin_altivec_crypto_vcipherlast");
  Builder.defineMacro("__vncipher", "__builtin_altivec_crypto_vncipher");
  Builder.defineMacro("__vncipherlast",
                      "__builtin_altivec_crypto_vncipherlast");
  Builder.defineMacro("__vpermxor", "__builtin_altivec_crypto_vpermxor");
  Builder.defineMacro("__vpmsumb", "__builtin_altivec_crypto_vpmsumb");
  Builder.defineMacro("__vpmsumd", "__builtin_altivec_crypto_vpmsumd");
  Builder.defineMacro("__vpmsumh", "__builtin_altivec_crypto_vpmsumh");
  Builder.defineMacro("__vpmsumw", "__builtin_altivec_crypto_vpmsumw");
  Builder.defineMacro("__divde", "__builtin_divde");
  Builder.defineMacro("__divwe", "__builtin_divwe");
  Builder.defineMacro("__divdeu", "__builtin_divdeu");
  Builder.defineMacro("__divweu", "__builtin_divweu");
  Builder.defineMacro("__alignx", "__builtin_ppc_alignx");
  Builder.defineMacro("__bcopy", "bcopy");
  Builder.defineMacro("__bpermd", "__builtin_bpermd");
  Builder.defineMacro("__cntlz4", "__builtin_clz");
  Builder.defineMacro("__cntlz8", "__builtin_clzll");
  Builder.defineMacro("__cmplx", "__builtin_complex");
  Builder.defineMacro("__cmplxf", "__builtin_complex");
  Builder.defineMacro("__cnttz4", "__builtin_ctz");
  Builder.defineMacro("__cnttz8", "__builtin_ctzll");
  Builder.defineMacro("__darn", "__builtin_darn");
  Builder.defineMacro("__darn_32", "__builtin_darn_32");
  Builder.defineMacro("__darn_raw", "__builtin_darn_raw");
  Builder.defineMacro("__dcbf", "__builtin_dcbf");
  Builder.defineMacro("__fence", "__builtin_ppc_fence");
  Builder.defineMacro("__fmadd", "__builtin_fma");
  Builder.defineMacro("__fmadds", "__builtin_fmaf");
  Builder.defineMacro("__abs", "__builtin_abs");
  Builder.defineMacro("__labs", "__builtin_labs");
  Builder.defineMacro("__llabs", "__builtin_llabs");
  Builder.defineMacro("__popcnt4", "__builtin_popcount");
  Builder.defineMacro("__popcnt8", "__builtin_popcountll");
  Builder.defineMacro("__readflm", "__builtin_readflm");
  Builder.defineMacro("__rotatel4", "__builtin_rotateleft32");
  Builder.defineMacro("__rotatel8", "__builtin_rotateleft64");
  Builder.defineMacro("__rdlam", "__builtin_ppc_rdlam");
  Builder.defineMacro("__setflm", "__builtin_setflm");
  Builder.defineMacro("__setrnd", "__builtin_setrnd");
  Builder.defineMacro("__dcbtstt", "__builtin_ppc_dcbtstt");
  Builder.defineMacro("__dcbtt", "__builtin_ppc_dcbtt");
  Builder.defineMacro("__mftbu", "__builtin_ppc_mftbu");
  Builder.defineMacro("__mfmsr", "__builtin_ppc_mfmsr");
  Builder.defineMacro("__mtmsr", "__builtin_ppc_mtmsr");
  Builder.defineMacro("__mfspr", "__builtin_ppc_mfspr");
  Builder.defineMacro("__mtspr", "__builtin_ppc_mtspr");
  Builder.defineMacro("__fric", "__builtin_ppc_fric");
  Builder.defineMacro("__frim", "__builtin_ppc_frim");
  Builder.defineMacro("__frims", "__builtin_ppc_frims");
  Builder.defineMacro("__frin", "__builtin_ppc_frin");
  Builder.defineMacro("__frins", "__builtin_ppc_frins");
  Builder.defineMacro("__frip", "__builtin_ppc_frip");
  Builder.defineMacro("__frips", "__builtin_ppc_frips");
  Builder.defineMacro("__friz", "__builtin_ppc_friz");
  Builder.defineMacro("__frizs", "__builtin_ppc_frizs");
  Builder.defineMacro("__fsel", "__builtin_ppc_fsel");
  Builder.defineMacro("__fsels", "__builtin_ppc_fsels");
  Builder.defineMacro("__frsqrte", "__builtin_ppc_frsqrte");
  Builder.defineMacro("__frsqrtes", "__builtin_ppc_frsqrtes");
  Builder.defineMacro("__fsqrt", "__builtin_ppc_fsqrt");
  Builder.defineMacro("__fsqrts", "__builtin_ppc_fsqrts");
  Builder.defineMacro("__addex", "__builtin_ppc_addex");
  Builder.defineMacro("__cmplxl", "__builtin_complex");
  Builder.defineMacro("__compare_exp_uo", "__builtin_ppc_compare_exp_uo");
  Builder.defineMacro("__compare_exp_lt", "__builtin_ppc_compare_exp_lt");
  Builder.defineMacro("__compare_exp_gt", "__builtin_ppc_compare_exp_gt");
  Builder.defineMacro("__compare_exp_eq", "__builtin_ppc_compare_exp_eq");
  Builder.defineMacro("__test_data_class", "__builtin_ppc_test_data_class");
  Builder.defineMacro("__swdiv", "__builtin_ppc_swdiv");
  Builder.defineMacro("__swdivs", "__builtin_ppc_swdivs");
  Builder.defineMacro("__fnabs", "__builtin_ppc_fnabs");
  Builder.defineMacro("__fnabss", "__builtin_ppc_fnabss");
  Builder.defineMacro("__builtin_maxfe", "__builtin_ppc_maxfe");
  Builder.defineMacro("__builtin_maxfl", "__builtin_ppc_maxfl");
  Builder.defineMacro("__builtin_maxfs", "__builtin_ppc_maxfs");
  Builder.defineMacro("__builtin_minfe", "__builtin_ppc_minfe");
  Builder.defineMacro("__builtin_minfl", "__builtin_ppc_minfl");
  Builder.defineMacro("__builtin_minfs", "__builtin_ppc_minfs");
  Builder.defineMacro("__builtin_mffs", "__builtin_ppc_mffs");
  Builder.defineMacro("__builtin_mffsl", "__builtin_ppc_mffsl");
  Builder.defineMacro("__builtin_mtfsf", "__builtin_ppc_mtfsf");
  Builder.defineMacro("__builtin_set_fpscr_rn", "__builtin_ppc_set_fpscr_rn");
}

/// PPCTargetInfo::getTargetDefines - Return a set of the PowerPC-specific
/// #defines that are not tied to a specific subtarget.
void PPCTargetInfo::getTargetDefines(const LangOptions &Opts,
                                     MacroBuilder &Builder) const {

  // We define the XLC compatibility macros only on AIX and Linux since XLC
  // was never available on any other platforms.
  if (getTriple().isOSAIX() || getTriple().isOSLinux())
    defineXLCompatMacros(Builder);

  // Target identification.
  Builder.defineMacro("__ppc__");
  Builder.defineMacro("__PPC__");
  Builder.defineMacro("_ARCH_PPC");
  Builder.defineMacro("__powerpc__");
  Builder.defineMacro("__POWERPC__");
  if (PointerWidth == 64) {
    Builder.defineMacro("_ARCH_PPC64");
    Builder.defineMacro("__powerpc64__");
    Builder.defineMacro("__PPC64__");
  } else if (getTriple().isOSAIX()) {
    // The XL compilers on AIX define _ARCH_PPC64 for both 32 and 64-bit modes.
    Builder.defineMacro("_ARCH_PPC64");
  }
  if (getTriple().isOSAIX()) {
    Builder.defineMacro("__THW_PPC__");
    // Define __PPC and __powerpc for AIX XL C/C++ compatibility
    Builder.defineMacro("__PPC");
    Builder.defineMacro("__powerpc");
  }

  // Target properties.
  if (getTriple().getArch() == llvm::Triple::ppc64le ||
      getTriple().getArch() == llvm::Triple::ppcle) {
    Builder.defineMacro("_LITTLE_ENDIAN");
  } else {
    if (!getTriple().isOSNetBSD() &&
        !getTriple().isOSOpenBSD())
      Builder.defineMacro("_BIG_ENDIAN");
  }

  // ABI options.
  if (ABI == "elfv1")
    Builder.defineMacro("_CALL_ELF", "1");
  if (ABI == "elfv2")
    Builder.defineMacro("_CALL_ELF", "2");

  // This typically is only for a new enough linker (bfd >= 2.16.2 or gold), but
  // our support post-dates this and it should work on all 64-bit ppc linux
  // platforms. It is guaranteed to work on all elfv2 platforms.
  if (getTriple().getOS() == llvm::Triple::Linux && PointerWidth == 64)
    Builder.defineMacro("_CALL_LINUX", "1");

  // Subtarget options.
  if (!getTriple().isOSAIX()){
    Builder.defineMacro("__NATURAL_ALIGNMENT__");
  }
  Builder.defineMacro("__REGISTER_PREFIX__", "");

  // FIXME: Should be controlled by command line option.
  if (LongDoubleWidth == 128) {
    Builder.defineMacro("__LONG_DOUBLE_128__");
    Builder.defineMacro("__LONGDOUBLE128");
    if (Opts.PPCIEEELongDouble)
      Builder.defineMacro("__LONG_DOUBLE_IEEE128__");
    else
      Builder.defineMacro("__LONG_DOUBLE_IBM128__");
  }

  if (getTriple().isOSAIX() && Opts.LongDoubleSize == 64) {
    assert(LongDoubleWidth == 64);
    Builder.defineMacro("__LONGDOUBLE64");
  }

  // Define this for elfv2 (64-bit only).
  if (ABI == "elfv2")
    Builder.defineMacro("__STRUCT_PARM_ALIGN__", "16");

  if (ArchDefs & ArchDefineName)
    Builder.defineMacro(Twine("_ARCH_", StringRef(CPU).upper()));
  if (ArchDefs & ArchDefinePpcgr)
    Builder.defineMacro("_ARCH_PPCGR");
  if (ArchDefs & ArchDefinePpcsq)
    Builder.defineMacro("_ARCH_PPCSQ");
  if (ArchDefs & ArchDefine440)
    Builder.defineMacro("_ARCH_440");
  if (ArchDefs & ArchDefine603)
    Builder.defineMacro("_ARCH_603");
  if (ArchDefs & ArchDefine604)
    Builder.defineMacro("_ARCH_604");
  if (ArchDefs & ArchDefinePwr4)
    Builder.defineMacro("_ARCH_PWR4");
  if (ArchDefs & ArchDefinePwr5)
    Builder.defineMacro("_ARCH_PWR5");
  if (ArchDefs & ArchDefinePwr5x)
    Builder.defineMacro("_ARCH_PWR5X");
  if (ArchDefs & ArchDefinePwr6)
    Builder.defineMacro("_ARCH_PWR6");
  if (ArchDefs & ArchDefinePwr6x)
    Builder.defineMacro("_ARCH_PWR6X");
  if (ArchDefs & ArchDefinePwr7)
    Builder.defineMacro("_ARCH_PWR7");
  if (ArchDefs & ArchDefinePwr8)
    Builder.defineMacro("_ARCH_PWR8");
  if (ArchDefs & ArchDefinePwr9)
    Builder.defineMacro("_ARCH_PWR9");
  if (ArchDefs & ArchDefinePwr10)
    Builder.defineMacro("_ARCH_PWR10");
  if (ArchDefs & ArchDefinePwr11)
    Builder.defineMacro("_ARCH_PWR11");
  if (ArchDefs & ArchDefineA2)
    Builder.defineMacro("_ARCH_A2");
  if (ArchDefs & ArchDefineE500)
    Builder.defineMacro("__NO_LWSYNC__");
  if (ArchDefs & ArchDefineFuture)
    Builder.defineMacro("_ARCH_PWR_FUTURE");

  if (HasAltivec) {
    Builder.defineMacro("__VEC__", "10206");
    Builder.defineMacro("__ALTIVEC__");
  }
  if (HasSPE)
    Builder.defineMacro("__SPE__");
  if (HasSPE || FloatABI == SoftFloat)
    Builder.defineMacro("__NO_FPRS__");
  if (FloatABI == SoftFloat) {
    Builder.defineMacro("_SOFT_FLOAT");
    Builder.defineMacro("_SOFT_DOUBLE");
  } else {
    if (HasFrsqrte)
      Builder.defineMacro("__RSQRTE__");
    if (HasFrsqrtes)
      Builder.defineMacro("__RSQRTEF__");
  }
  if (HasVSX)
    Builder.defineMacro("__VSX__");
  if (HasP8Vector)
    Builder.defineMacro("__POWER8_VECTOR__");
  if (HasP8Crypto)
    Builder.defineMacro("__CRYPTO__");
  if (HasHTM)
    Builder.defineMacro("__HTM__");
  if (HasFloat128)
    Builder.defineMacro("__FLOAT128__");
  if (HasP9Vector)
    Builder.defineMacro("__POWER9_VECTOR__");
  if (HasMMA)
    Builder.defineMacro("__MMA__");
  if (HasROPProtect)
    Builder.defineMacro("__ROP_PROTECT__");
  if (HasP10Vector)
    Builder.defineMacro("__POWER10_VECTOR__");
  if (HasPCRelativeMemops)
    Builder.defineMacro("__PCREL__");

  Builder.defineMacro("__GCC_HAVE_SYNC_COMPARE_AND_SWAP_1");
  Builder.defineMacro("__GCC_HAVE_SYNC_COMPARE_AND_SWAP_2");
  Builder.defineMacro("__GCC_HAVE_SYNC_COMPARE_AND_SWAP_4");
  if (PointerWidth == 64)
    Builder.defineMacro("__GCC_HAVE_SYNC_COMPARE_AND_SWAP_8");

  // We have support for the bswap intrinsics so we can define this.
  Builder.defineMacro("__HAVE_BSWAP__", "1");

  // FIXME: The following are not yet generated here by Clang, but are
  //        generated by GCC:
  //
  //   __RECIP_PRECISION__
  //   __APPLE_ALTIVEC__
  //   __RECIP__
  //   __RECIPF__
  //   __NO_LWSYNC__
  //   __CMODEL_MEDIUM__
  //   __CMODEL_LARGE__
  //   _CALL_SYSV
  //   _CALL_DARWIN
}

// Handle explicit options being passed to the compiler here:
// - if we've explicitly turned off vsx and turned on any of:
//   - power8-vector
//   - direct-move
//   - float128
//   - power9-vector
//   - paired-vector-memops
//   - mma
//   - power10-vector
// - if we've explicitly turned on vsx and turned off altivec.
// - if we've explicitly turned off hard-float and turned on altivec.
// then go ahead and error since the customer has expressed an incompatible
// set of options.
static bool ppcUserFeaturesCheck(DiagnosticsEngine &Diags,
                                 const std::vector<std::string> &FeaturesVec) {
  auto FindVSXSubfeature = [&](StringRef Feature, StringRef SubOption,
                               StringRef Option) {
    if (llvm::is_contained(FeaturesVec, Feature)) {
      Diags.Report(diag::err_opt_not_valid_with_opt) << SubOption << Option;
      return true;
    }
    return false;
  };

  // Cannot allow soft-float with VSX, Altivec, or any
  // VSX subfeatures.
  bool Found = false;
  if (llvm::is_contained(FeaturesVec, "-hard-float")) {
    Found |= FindVSXSubfeature("+vsx", "-mvsx", "-msoft-float");
    Found |= FindVSXSubfeature("+altivec", "-maltivec", "-msoft-float");
    Found |=
        FindVSXSubfeature("+power8-vector", "-mpower8-vector", "-msoft-float");
    Found |= FindVSXSubfeature("+direct-move", "-mdirect-move", "-msoft-float");
    Found |= FindVSXSubfeature("+float128", "-mfloat128", "-msoft-float");
    Found |=
        FindVSXSubfeature("+power9-vector", "-mpower9-vector", "-msoft-float");
    Found |= FindVSXSubfeature("+paired-vector-memops",
                               "-mpaired-vector-memops", "-msoft-float");
    Found |= FindVSXSubfeature("+mma", "-mmma", "-msoft-float");
    Found |= FindVSXSubfeature("+crypto", "-mcrypto", "-msoft-float");
    Found |= FindVSXSubfeature("+power10-vector", "-mpower10-vector",
                               "-msoft-float");
  }
  if (Found)
    return false;

  // Cannot allow VSX with no Altivec.
  if (llvm::is_contained(FeaturesVec, "+vsx") &&
      llvm::is_contained(FeaturesVec, "-altivec")) {
    Diags.Report(diag::err_opt_not_valid_with_opt) << "-mvsx"
                                                   << "-mno-altivec";
    return false;
  }

  // vsx was not explicitly turned off.
  if (!llvm::is_contained(FeaturesVec, "-vsx"))
    return true;

  Found = FindVSXSubfeature("+power8-vector", "-mpower8-vector", "-mno-vsx");
  Found |= FindVSXSubfeature("+direct-move", "-mdirect-move", "-mno-vsx");
  Found |= FindVSXSubfeature("+float128", "-mfloat128", "-mno-vsx");
  Found |= FindVSXSubfeature("+power9-vector", "-mpower9-vector", "-mno-vsx");
  Found |= FindVSXSubfeature("+paired-vector-memops", "-mpaired-vector-memops",
                             "-mno-vsx");
  Found |= FindVSXSubfeature("+mma", "-mmma", "-mno-vsx");
  Found |= FindVSXSubfeature("+power10-vector", "-mpower10-vector", "-mno-vsx");

  // Return false if any vsx subfeatures was found.
  return !Found;
}

bool PPCTargetInfo::initFeatureMap(
    llvm::StringMap<bool> &Features, DiagnosticsEngine &Diags, StringRef CPU,
    const std::vector<std::string> &FeaturesVec) const {

  const llvm::Triple &TheTriple = getTriple();

  std::optional<llvm::StringMap<bool>> FeaturesOpt =
      llvm::PPC::getPPCDefaultTargetFeatures(TheTriple,
                                             llvm::PPC::normalizeCPUName(CPU));
  if (FeaturesOpt)
    Features = FeaturesOpt.value();

  if (!ppcUserFeaturesCheck(Diags, FeaturesVec))
    return false;

  if (!(ArchDefs & ArchDefinePwr7) && (ArchDefs & ArchDefinePpcgr) &&
      llvm::is_contained(FeaturesVec, "+float128")) {
    // We have __float128 on PPC but not pre-VSX targets.
    Diags.Report(diag::err_opt_not_valid_with_opt) << "-mfloat128" << CPU;
    return false;
  }

  if (!(ArchDefs & ArchDefinePwr10)) {
    if (llvm::is_contained(FeaturesVec, "+mma")) {
      // MMA operations are not available pre-Power10.
      Diags.Report(diag::err_opt_not_valid_with_opt) << "-mmma" << CPU;
      return false;
    }
    if (llvm::is_contained(FeaturesVec, "+pcrel")) {
      // PC-Relative instructions are not available pre-Power10,
      // and these instructions also require prefixed instructions support.
      Diags.Report(diag::err_opt_not_valid_without_opt)
          << "-mpcrel"
          << "-mcpu=pwr10 -mprefixed";
      return false;
    }
    if (llvm::is_contained(FeaturesVec, "+prefixed")) {
      // Prefixed instructions are not available pre-Power10.
      Diags.Report(diag::err_opt_not_valid_without_opt) << "-mprefixed"
                                                        << "-mcpu=pwr10";
      return false;
    }
    if (llvm::is_contained(FeaturesVec, "+paired-vector-memops")) {
      // Paired vector memops are not available pre-Power10.
      Diags.Report(diag::err_opt_not_valid_without_opt)
          << "-mpaired-vector-memops"
          << "-mcpu=pwr10";
      return false;
    }
  }

  if (llvm::is_contained(FeaturesVec, "+rop-protect")) {
    if (PointerWidth == 32) {
      Diags.Report(diag::err_opt_not_valid_on_target) << "-mrop-protect";
      return false;
    }

    if (!(ArchDefs & ArchDefinePwr8)) {
      // We can turn on ROP Protect on Power 8 and above.
      Diags.Report(diag::err_opt_not_valid_with_opt) << "-mrop-protect" << CPU;
      return false;
    }
  }

  if (!(ArchDefs & ArchDefinePwr8) &&
      llvm::is_contained(FeaturesVec, "+privileged")) {
    Diags.Report(diag::err_opt_not_valid_with_opt) << "-mprivileged" << CPU;
    return false;
  }
  return TargetInfo::initFeatureMap(Features, Diags, CPU, FeaturesVec);
}

bool PPCTargetInfo::hasFeature(StringRef Feature) const {
  return llvm::StringSwitch<bool>(Feature)
      .Case("powerpc", true)
      .Case("altivec", HasAltivec)
      .Case("vsx", HasVSX)
      .Case("power8-vector", HasP8Vector)
      .Case("crypto", HasP8Crypto)
      .Case("htm", HasHTM)
      .Case("float128", HasFloat128)
      .Case("power9-vector", HasP9Vector)
      .Case("power10-vector", HasP10Vector)
      .Case("pcrelative-memops", HasPCRelativeMemops)
      .Case("spe", HasSPE)
      .Case("mma", HasMMA)
      .Case("rop-protect", HasROPProtect)
      .Case("quadword-atomics", HasQuadwordAtomics)
      .Case("longcall", UseLongCalls)
      .Default(false);
}

void PPCTargetInfo::setFeatureEnabled(llvm::StringMap<bool> &Features,
                                      StringRef Name, bool Enabled) const {
  if (Enabled) {
    if (Name == "efpu2")
      Features["spe"] = true;
    // If we're enabling any of the vsx based features then enable vsx and
    // altivec. We'll diagnose any problems later.
    bool FeatureHasVSX = llvm::StringSwitch<bool>(Name)
                             .Case("vsx", true)
                             .Case("direct-move", true)
                             .Case("power8-vector", true)
                             .Case("power9-vector", true)
                             .Case("paired-vector-memops", true)
                             .Case("power10-vector", true)
                             .Case("float128", true)
                             .Case("mma", true)
                             .Default(false);
    if (FeatureHasVSX)
      Features["vsx"] = Features["altivec"] = true;
    if (Name == "power9-vector")
      Features["power8-vector"] = true;
    else if (Name == "power10-vector")
      Features["power8-vector"] = Features["power9-vector"] = true;
    if (Name == "pcrel")
      Features["pcrelative-memops"] = true;
    else if (Name == "prefixed")
      Features["prefix-instrs"] = true;
    else
      Features[Name] = true;
  } else {
    if (Name == "spe")
      Features["efpu2"] = false;
    // If we're disabling altivec, hard-float, or vsx go ahead and disable all
    // of the vsx features.
    if ((Name == "altivec") || (Name == "vsx") || (Name == "hard-float")) {
      if (Name != "vsx")
        Features["altivec"] = Features["crypto"] = false;
      Features["vsx"] = Features["direct-move"] = Features["power8-vector"] =
          Features["float128"] = Features["power9-vector"] =
              Features["paired-vector-memops"] = Features["mma"] =
                  Features["power10-vector"] = false;
    }
    if (Name == "power8-vector")
      Features["power9-vector"] = Features["paired-vector-memops"] =
          Features["mma"] = Features["power10-vector"] = false;
    else if (Name == "power9-vector")
      Features["paired-vector-memops"] = Features["mma"] =
          Features["power10-vector"] = false;
    if (Name == "pcrel")
      Features["pcrelative-memops"] = false;
    else if (Name == "prefixed")
      Features["prefix-instrs"] = false;
    else
      Features[Name] = false;
  }
}

// Make sure that registers are added in the correct array index which should be
// the DWARF number for PPC registers.
const char *const PPCTargetInfo::GCCRegNames[] = {
    "r0",  "r1",     "r2",   "r3",      "r4",      "r5",  "r6",  "r7",  "r8",
    "r9",  "r10",    "r11",  "r12",     "r13",     "r14", "r15", "r16", "r17",
    "r18", "r19",    "r20",  "r21",     "r22",     "r23", "r24", "r25", "r26",
    "r27", "r28",    "r29",  "r30",     "r31",     "f0",  "f1",  "f2",  "f3",
    "f4",  "f5",     "f6",   "f7",      "f8",      "f9",  "f10", "f11", "f12",
    "f13", "f14",    "f15",  "f16",     "f17",     "f18", "f19", "f20", "f21",
    "f22", "f23",    "f24",  "f25",     "f26",     "f27", "f28", "f29", "f30",
    "f31", "mq",     "lr",   "ctr",     "ap",      "cr0", "cr1", "cr2", "cr3",
    "cr4", "cr5",    "cr6",  "cr7",     "xer",     "v0",  "v1",  "v2",  "v3",
    "v4",  "v5",     "v6",   "v7",      "v8",      "v9",  "v10", "v11", "v12",
    "v13", "v14",    "v15",  "v16",     "v17",     "v18", "v19", "v20", "v21",
    "v22", "v23",    "v24",  "v25",     "v26",     "v27", "v28", "v29", "v30",
    "v31", "vrsave", "vscr", "spe_acc", "spefscr", "sfp"
};

ArrayRef<const char *> PPCTargetInfo::getGCCRegNames() const {
  return llvm::ArrayRef(GCCRegNames);
}

const TargetInfo::GCCRegAlias PPCTargetInfo::GCCRegAliases[] = {
    // While some of these aliases do map to different registers
    // they still share the same register name.
    {{"0"}, "r0"},     {{"1", "sp"}, "r1"}, {{"2"}, "r2"},
    {{"3"}, "r3"},     {{"4"}, "r4"},       {{"5"}, "r5"},
    {{"6"}, "r6"},     {{"7"}, "r7"},       {{"8"}, "r8"},
    {{"9"}, "r9"},     {{"10"}, "r10"},     {{"11"}, "r11"},
    {{"12"}, "r12"},   {{"13"}, "r13"},     {{"14"}, "r14"},
    {{"15"}, "r15"},   {{"16"}, "r16"},     {{"17"}, "r17"},
    {{"18"}, "r18"},   {{"19"}, "r19"},     {{"20"}, "r20"},
    {{"21"}, "r21"},   {{"22"}, "r22"},     {{"23"}, "r23"},
    {{"24"}, "r24"},   {{"25"}, "r25"},     {{"26"}, "r26"},
    {{"27"}, "r27"},   {{"28"}, "r28"},     {{"29"}, "r29"},
    {{"30"}, "r30"},   {{"31"}, "r31"},     {{"fr0"}, "f0"},
    {{"fr1"}, "f1"},   {{"fr2"}, "f2"},     {{"fr3"}, "f3"},
    {{"fr4"}, "f4"},   {{"fr5"}, "f5"},     {{"fr6"}, "f6"},
    {{"fr7"}, "f7"},   {{"fr8"}, "f8"},     {{"fr9"}, "f9"},
    {{"fr10"}, "f10"}, {{"fr11"}, "f11"},   {{"fr12"}, "f12"},
    {{"fr13"}, "f13"}, {{"fr14"}, "f14"},   {{"fr15"}, "f15"},
    {{"fr16"}, "f16"}, {{"fr17"}, "f17"},   {{"fr18"}, "f18"},
    {{"fr19"}, "f19"}, {{"fr20"}, "f20"},   {{"fr21"}, "f21"},
    {{"fr22"}, "f22"}, {{"fr23"}, "f23"},   {{"fr24"}, "f24"},
    {{"fr25"}, "f25"}, {{"fr26"}, "f26"},   {{"fr27"}, "f27"},
    {{"fr28"}, "f28"}, {{"fr29"}, "f29"},   {{"fr30"}, "f30"},
    {{"fr31"}, "f31"}, {{"cc"}, "cr0"},
};

ArrayRef<TargetInfo::GCCRegAlias> PPCTargetInfo::getGCCRegAliases() const {
  return llvm::ArrayRef(GCCRegAliases);
}

// PPC ELFABIv2 DWARF Definition "Table 2.26. Mappings of Common Registers".
// vs0 ~ vs31 is mapping to 32 - 63,
// vs32 ~ vs63 is mapping to 77 - 108.
// And this mapping applies to all OSes which run on powerpc.
const TargetInfo::AddlRegName GCCAddlRegNames[] = {
    // Table of additional register names to use in user input.
    {{"vs0"}, 32},   {{"vs1"}, 33},   {{"vs2"}, 34},   {{"vs3"}, 35},
    {{"vs4"}, 36},   {{"vs5"}, 37},   {{"vs6"}, 38},   {{"vs7"}, 39},
    {{"vs8"}, 40},   {{"vs9"}, 41},   {{"vs10"}, 42},  {{"vs11"}, 43},
    {{"vs12"}, 44},  {{"vs13"}, 45},  {{"vs14"}, 46},  {{"vs15"}, 47},
    {{"vs16"}, 48},  {{"vs17"}, 49},  {{"vs18"}, 50},  {{"vs19"}, 51},
    {{"vs20"}, 52},  {{"vs21"}, 53},  {{"vs22"}, 54},  {{"vs23"}, 55},
    {{"vs24"}, 56},  {{"vs25"}, 57},  {{"vs26"}, 58},  {{"vs27"}, 59},
    {{"vs28"}, 60},  {{"vs29"}, 61},  {{"vs30"}, 62},  {{"vs31"}, 63},
    {{"vs32"}, 77},  {{"vs33"}, 78},  {{"vs34"}, 79},  {{"vs35"}, 80},
    {{"vs36"}, 81},  {{"vs37"}, 82},  {{"vs38"}, 83},  {{"vs39"}, 84},
    {{"vs40"}, 85},  {{"vs41"}, 86},  {{"vs42"}, 87},  {{"vs43"}, 88},
    {{"vs44"}, 89},  {{"vs45"}, 90},  {{"vs46"}, 91},  {{"vs47"}, 92},
    {{"vs48"}, 93},  {{"vs49"}, 94},  {{"vs50"}, 95},  {{"vs51"}, 96},
    {{"vs52"}, 97},  {{"vs53"}, 98},  {{"vs54"}, 99},  {{"vs55"}, 100},
    {{"vs56"}, 101}, {{"vs57"}, 102}, {{"vs58"}, 103}, {{"vs59"}, 104},
    {{"vs60"}, 105}, {{"vs61"}, 106}, {{"vs62"}, 107}, {{"vs63"}, 108},
};

ArrayRef<TargetInfo::AddlRegName> PPCTargetInfo::getGCCAddlRegNames() const {
  return llvm::ArrayRef(GCCAddlRegNames);
}

bool PPCTargetInfo::isValidCPUName(StringRef Name) const {
  return llvm::PPC::isValidCPU(Name);
}

void PPCTargetInfo::fillValidCPUList(SmallVectorImpl<StringRef> &Values) const {
  llvm::PPC::fillValidCPUList(Values);
}

void PPCTargetInfo::adjust(DiagnosticsEngine &Diags, LangOptions &Opts,
                           const TargetInfo *Aux) {
  if (HasAltivec)
    Opts.AltiVec = 1;
  TargetInfo::adjust(Diags, Opts, Aux);
  if (LongDoubleFormat != &llvm::APFloat::IEEEdouble())
    LongDoubleFormat = Opts.PPCIEEELongDouble
                           ? &llvm::APFloat::IEEEquad()
                           : &llvm::APFloat::PPCDoubleDouble();
  Opts.IEEE128 = 1;
  if (getTriple().isOSAIX() && Opts.EnableAIXQuadwordAtomicsABI &&
      HasQuadwordAtomics)
    MaxAtomicInlineWidth = 128;
}

llvm::SmallVector<Builtin::InfosShard>
PPCTargetInfo::getTargetBuiltins() const {
  return {{&BuiltinStrings, BuiltinInfos}};
}

bool PPCTargetInfo::validateCpuSupports(StringRef FeatureStr) const {
  llvm::Triple Triple = getTriple();
  if (Triple.isOSAIX()) {
#define PPC_AIX_FEATURE(NAME, DESC, SUPPORT_METHOD, INDEX, MASK, COMP_OP,      \
                        VALUE)                                                 \
  .Case(NAME, true)
    return llvm::StringSwitch<bool>(FeatureStr)
#include "llvm/TargetParser/PPCTargetParser.def"
        .Default(false);
  }

  assert(Triple.isOSLinux() &&
         "__builtin_cpu_supports() is only supported for AIX and Linux.");

#define PPC_LNX_FEATURE(NAME, DESC, ENUMNAME, ENUMVAL, HWCAPN) .Case(NAME, true)
  return llvm::StringSwitch<bool>(FeatureStr)
#include "llvm/TargetParser/PPCTargetParser.def"
      .Default(false);
}

bool PPCTargetInfo::validateCpuIs(StringRef CPUName) const {
  llvm::Triple Triple = getTriple();
  assert((Triple.isOSAIX() || Triple.isOSLinux()) &&
         "__builtin_cpu_is() is only supported for AIX and Linux.");

#define PPC_CPU(NAME, Linux_SUPPORT_METHOD, LinuxID, AIX_SUPPORT_METHOD,       \
                AIXID)                                                         \
  .Case(NAME, {Linux_SUPPORT_METHOD, AIX_SUPPORT_METHOD})

  std::pair<unsigned, unsigned> SuppportMethod =
      llvm::StringSwitch<std::pair<unsigned, unsigned>>(CPUName)
#include "llvm/TargetParser/PPCTargetParser.def"
          .Default({BUILTIN_PPC_UNSUPPORTED, BUILTIN_PPC_UNSUPPORTED});
  return Triple.isOSLinux()
             ? (SuppportMethod.first != BUILTIN_PPC_UNSUPPORTED)
             : (SuppportMethod.second != BUILTIN_PPC_UNSUPPORTED);
}
