//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include <clc/integer/clc_mul_hi.h>
#include <clc/opencl/integer/mul_hi.h>

#define FUNCTION mul_hi
#define __CLC_BODY <clc/shared/binary_def.inc>

#include <clc/integer/gentype.inc>
