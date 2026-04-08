//===- COFFObjectFileTest.cpp - Tests for COFFObjectFile ----------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/Object/COFF.h"
#include "llvm/Object/ObjectFile.h"
#include "llvm/ObjectYAML/yaml2obj.h"
#include "llvm/Support/YAMLTraits.h"
#include "llvm/Testing/Support/Error.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::object;

TEST(COFFObjectFileTest, CHPERangeEntry) {
  chpe_range_entry range;

  range.StartOffset = 0x1000;
  EXPECT_EQ(range.getStart(), 0x1000u);
  EXPECT_EQ(range.getType(), chpe_range_type::Arm64);

  range.StartOffset = 0x2000 | chpe_range_type::Arm64EC;
  EXPECT_EQ(range.getStart(), 0x2000u);
  EXPECT_EQ(range.getType(), chpe_range_type::Arm64EC);

  range.StartOffset = 0x3000 | chpe_range_type::Amd64;
  EXPECT_EQ(range.getStart(), 0x3000u);
  EXPECT_EQ(range.getType(), chpe_range_type::Amd64);
}

static Expected<std::unique_ptr<ObjectFile>>
toBinary(SmallVectorImpl<char> &Storage, StringRef Yaml) {
  raw_svector_ostream OS(Storage);
  yaml::Input YIn(Yaml);
  if (!yaml::convertYAML(YIn, OS, [](const Twine &Msg) {}))
    return createStringError(std::errc::invalid_argument,
                             "unable to convert YAML");
  MemoryBufferRef Buf(OS.str(), "dummyCOFF");
  return ObjectFile::createCOFFObjectFile(Buf);
}

// Test for the COFFObjectFile::readBBAddrMap API.
TEST(COFFObjectFileTest, ReadBBAddrMap) {
  // Two .text sections each with a .llvm_bb_addr_map section.
  // Section data: version=5, feature=0x0000, 8-byte address (relocated),
  // 1 BB: ID=0, offset=0, size=4, metadata=1 (HasReturn).
  StringRef YamlString(R"(
--- !COFF
header:
  Machine:         IMAGE_FILE_MACHINE_AMD64
  Characteristics: [  ]
sections:
  - Name:            .text
    Characteristics: [ IMAGE_SCN_CNT_CODE, IMAGE_SCN_LNK_COMDAT, IMAGE_SCN_MEM_EXECUTE, IMAGE_SCN_MEM_READ ]
    Alignment:       16
    SectionData:     F6C101C3
    SizeOfRawData:   4
  - Name:            .text
    Characteristics: [ IMAGE_SCN_CNT_CODE, IMAGE_SCN_LNK_COMDAT, IMAGE_SCN_MEM_EXECUTE, IMAGE_SCN_MEM_READ ]
    Alignment:       16
    SectionData:     F6C101C3
    SizeOfRawData:   4
  - Name:            .llvm_bb_addr_map
    Characteristics: [ IMAGE_SCN_CNT_INITIALIZED_DATA, IMAGE_SCN_LNK_COMDAT, IMAGE_SCN_MEM_DISCARDABLE, IMAGE_SCN_MEM_READ ]
    Alignment:       1
    SectionData:     '05000000000000000000000100000401'
    SizeOfRawData:   16
    Relocations:
      - VirtualAddress:  3
        SymbolName:      bar
        Type:            IMAGE_REL_AMD64_ADDR64
  - Name:            .llvm_bb_addr_map
    Characteristics: [ IMAGE_SCN_CNT_INITIALIZED_DATA, IMAGE_SCN_LNK_COMDAT, IMAGE_SCN_MEM_DISCARDABLE, IMAGE_SCN_MEM_READ ]
    Alignment:       1
    SectionData:     '05000000000000000000000100000401'
    SizeOfRawData:   16
    Relocations:
      - VirtualAddress:  3
        SymbolName:      foo
        Type:            IMAGE_REL_AMD64_ADDR64
symbols:
  - Name:            .text
    Value:           0
    SectionNumber:   1
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_NULL
    StorageClass:    IMAGE_SYM_CLASS_STATIC
    SectionDefinition:
      Length:          4
      NumberOfRelocations: 0
      NumberOfLinenumbers: 0
      CheckSum:        672536391
      Number:          1
      Selection:       IMAGE_COMDAT_SELECT_NODUPLICATES
  - Name:            .llvm_bb_addr_map
    Value:           0
    SectionNumber:   3
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_NULL
    StorageClass:    IMAGE_SYM_CLASS_STATIC
    SectionDefinition:
      Length:          16
      NumberOfRelocations: 1
      NumberOfLinenumbers: 0
      CheckSum:        1414660404
      Number:          1
      Selection:       IMAGE_COMDAT_SELECT_ASSOCIATIVE
  - Name:            .text
    Value:           0
    SectionNumber:   2
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_NULL
    StorageClass:    IMAGE_SYM_CLASS_STATIC
    SectionDefinition:
      Length:          4
      NumberOfRelocations: 0
      NumberOfLinenumbers: 0
      CheckSum:        672536391
      Number:          2
      Selection:       IMAGE_COMDAT_SELECT_ANY
  - Name:            bar
    Value:           0
    SectionNumber:   1
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_FUNCTION
    StorageClass:    IMAGE_SYM_CLASS_EXTERNAL
  - Name:            foo
    Value:           0
    SectionNumber:   2
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_FUNCTION
    StorageClass:    IMAGE_SYM_CLASS_EXTERNAL
  - Name:            .llvm_bb_addr_map
    Value:           0
    SectionNumber:   4
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_NULL
    StorageClass:    IMAGE_SYM_CLASS_STATIC
    SectionDefinition:
      Length:          16
      NumberOfRelocations: 1
      NumberOfLinenumbers: 0
      CheckSum:        1414660404
      Number:          2
      Selection:       IMAGE_COMDAT_SELECT_ASSOCIATIVE
)");

  BBAddrMap E1 = {
      {{0x0, {{0, 0x0, 0x4, {true, false, false, false, false}, {}, 0}}}}};
  BBAddrMap E2 = {
      {{0x0, {{0, 0x0, 0x4, {true, false, false, false, false}, {}, 0}}}}};
  std::vector<BBAddrMap> AllBBAddrMaps = {E1, E2};

  SmallString<0> Storage;
  Expected<std::unique_ptr<ObjectFile>> ObjOrErr =
      toBinary(Storage, YamlString);
  ASSERT_THAT_EXPECTED(ObjOrErr, Succeeded());
  const COFFObjectFile *Obj =
      dyn_cast<COFFObjectFile>(ObjOrErr->get());
  ASSERT_NE(Obj, nullptr);

  // Read all BB addr maps.
  auto BBAddrMaps = Obj->readBBAddrMap(/*TextSectionIndex=*/std::nullopt);
  ASSERT_THAT_EXPECTED(BBAddrMaps, Succeeded());
  EXPECT_EQ(*BBAddrMaps, AllBBAddrMaps);

  // Read BB addr map for the first .text section (0-based index 0).
  auto Section0Maps = Obj->readBBAddrMap(/*TextSectionIndex=*/0);
  ASSERT_THAT_EXPECTED(Section0Maps, Succeeded());
  EXPECT_EQ(Section0Maps->size(), 1u);
  EXPECT_EQ((*Section0Maps)[0], E1);

  // Read BB addr map for the second .text section (0-based index 1).
  auto Section1Maps = Obj->readBBAddrMap(/*TextSectionIndex=*/1);
  ASSERT_THAT_EXPECTED(Section1Maps, Succeeded());
  EXPECT_EQ(Section1Maps->size(), 1u);
  EXPECT_EQ((*Section1Maps)[0], E2);

  // Non-existent text section returns empty.
  auto EmptyMaps = Obj->readBBAddrMap(/*TextSectionIndex=*/5);
  ASSERT_THAT_EXPECTED(EmptyMaps, Succeeded());
  EXPECT_TRUE(EmptyMaps->empty());
}

// Test for reading BB addr map with PGO analysis data.
TEST(COFFObjectFileTest, ReadBBAddrMapPGOAnalysis) {
  // One function with 3 BBs and PGO features: FuncEntryCount + BBFreq + BrProb.
  // Section data breakdown (version=5, feature=0x0007):
  //   05 0700 0000000000000000 03
  //     00 0004 08  01 0003 01 02 0006 01
  //   64  80808080808080200201
  //       E6CC99B306 029AB3E6CC01
  //       80808098B3E6CC1900 808080E8CC99B30600
  StringRef YamlString(R"(
--- !COFF
header:
  Machine:         IMAGE_FILE_MACHINE_AMD64
  Characteristics: [  ]
sections:
  - Name:            .text
    Characteristics: [ IMAGE_SCN_CNT_CODE, IMAGE_SCN_LNK_COMDAT, IMAGE_SCN_MEM_EXECUTE, IMAGE_SCN_MEM_READ ]
    Alignment:       16
    SectionData:     85C9750331C0C3B801000000C3
    SizeOfRawData:   13
  - Name:            .llvm_bb_addr_map
    Characteristics: [ IMAGE_SCN_CNT_INITIALIZED_DATA, IMAGE_SCN_LNK_COMDAT, IMAGE_SCN_MEM_DISCARDABLE, IMAGE_SCN_MEM_READ ]
    Alignment:       1
    SectionData:     0507000000000000000000030000040801000301020006016480808080808080200201E6CC99B306029AB3E6CC0180808098B3E6CC1900808080E8CC99B30600
    SizeOfRawData:   64
    Relocations:
      - VirtualAddress:  3
        SymbolName:      bar
        Type:            IMAGE_REL_AMD64_ADDR64
symbols:
  - Name:            .text
    Value:           0
    SectionNumber:   1
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_NULL
    StorageClass:    IMAGE_SYM_CLASS_STATIC
    SectionDefinition:
      Length:          13
      NumberOfRelocations: 0
      NumberOfLinenumbers: 0
      CheckSum:        1669794853
      Number:          1
      Selection:       IMAGE_COMDAT_SELECT_NODUPLICATES
  - Name:            .llvm_bb_addr_map
    Value:           0
    SectionNumber:   2
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_NULL
    StorageClass:    IMAGE_SYM_CLASS_STATIC
    SectionDefinition:
      Length:          64
      NumberOfRelocations: 1
      NumberOfLinenumbers: 0
      CheckSum:        192098721
      Number:          1
      Selection:       IMAGE_COMDAT_SELECT_ASSOCIATIVE
  - Name:            bar
    Value:           0
    SectionNumber:   1
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_FUNCTION
    StorageClass:    IMAGE_SYM_CLASS_EXTERNAL
)");

  SmallString<0> Storage;
  Expected<std::unique_ptr<ObjectFile>> ObjOrErr =
      toBinary(Storage, YamlString);
  ASSERT_THAT_EXPECTED(ObjOrErr, Succeeded());
  const COFFObjectFile *Obj =
      dyn_cast<COFFObjectFile>(ObjOrErr->get());
  ASSERT_NE(Obj, nullptr);

  std::vector<PGOAnalysisMap> PGOAnalyses;
  auto BBAddrMaps =
      Obj->readBBAddrMap(/*TextSectionIndex=*/std::nullopt, &PGOAnalyses);
  ASSERT_THAT_EXPECTED(BBAddrMaps, Succeeded());
  EXPECT_EQ(BBAddrMaps->size(), 1u);
  EXPECT_EQ(PGOAnalyses.size(), 1u);

  // Check PGO features are enabled.
  EXPECT_TRUE(PGOAnalyses[0].FeatEnable.FuncEntryCount);
  EXPECT_TRUE(PGOAnalyses[0].FeatEnable.BBFreq);
  EXPECT_TRUE(PGOAnalyses[0].FeatEnable.BrProb);

  // Check function entry count.
  EXPECT_EQ(PGOAnalyses[0].FuncEntryCount, 100u);

  // Check 3 BB PGO entries.
  EXPECT_EQ(PGOAnalyses[0].BBEntries.size(), 3u);
}

// Test for error paths in COFFObjectFile::readBBAddrMap.
TEST(COFFObjectFileTest, InvalidDecodeBBAddrMap) {
  // Section data with unsupported version (6).
  StringRef UnsupportedVersionYaml(R"(
--- !COFF
header:
  Machine:         IMAGE_FILE_MACHINE_AMD64
  Characteristics: [  ]
sections:
  - Name:            .text
    Characteristics: [ IMAGE_SCN_CNT_CODE, IMAGE_SCN_LNK_COMDAT, IMAGE_SCN_MEM_EXECUTE, IMAGE_SCN_MEM_READ ]
    Alignment:       16
    SectionData:     C3
    SizeOfRawData:   1
  - Name:            .llvm_bb_addr_map
    Characteristics: [ IMAGE_SCN_CNT_INITIALIZED_DATA, IMAGE_SCN_LNK_COMDAT, IMAGE_SCN_MEM_DISCARDABLE, IMAGE_SCN_MEM_READ ]
    Alignment:       1
    SectionData:     '06000000000000000000000100000401'
    SizeOfRawData:   16
    Relocations:
      - VirtualAddress:  3
        SymbolName:      func
        Type:            IMAGE_REL_AMD64_ADDR64
symbols:
  - Name:            .text
    Value:           0
    SectionNumber:   1
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_NULL
    StorageClass:    IMAGE_SYM_CLASS_STATIC
    SectionDefinition:
      Length:          1
      NumberOfRelocations: 0
      NumberOfLinenumbers: 0
      CheckSum:        0
      Number:          1
      Selection:       IMAGE_COMDAT_SELECT_NODUPLICATES
  - Name:            .llvm_bb_addr_map
    Value:           0
    SectionNumber:   2
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_NULL
    StorageClass:    IMAGE_SYM_CLASS_STATIC
    SectionDefinition:
      Length:          16
      NumberOfRelocations: 1
      NumberOfLinenumbers: 0
      CheckSum:        0
      Number:          1
      Selection:       IMAGE_COMDAT_SELECT_ASSOCIATIVE
  - Name:            func
    Value:           0
    SectionNumber:   1
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_FUNCTION
    StorageClass:    IMAGE_SYM_CLASS_EXTERNAL
)");

  SmallString<0> Storage;
  Expected<std::unique_ptr<ObjectFile>> ObjOrErr =
      toBinary(Storage, UnsupportedVersionYaml);
  ASSERT_THAT_EXPECTED(ObjOrErr, Succeeded());
  const COFFObjectFile *Obj =
      dyn_cast<COFFObjectFile>(ObjOrErr->get());
  ASSERT_NE(Obj, nullptr);

  EXPECT_THAT_ERROR(
      Obj->readBBAddrMap(/*TextSectionIndex=*/std::nullopt).takeError(),
      FailedWithMessage(testing::HasSubstr("unsupported BB address map "
                                           "version: 6")));

  // Section data with truncated content.
  StringRef TruncatedYaml(R"(
--- !COFF
header:
  Machine:         IMAGE_FILE_MACHINE_AMD64
  Characteristics: [  ]
sections:
  - Name:            .text
    Characteristics: [ IMAGE_SCN_CNT_CODE, IMAGE_SCN_LNK_COMDAT, IMAGE_SCN_MEM_EXECUTE, IMAGE_SCN_MEM_READ ]
    Alignment:       16
    SectionData:     C3
    SizeOfRawData:   1
  - Name:            .llvm_bb_addr_map
    Characteristics: [ IMAGE_SCN_CNT_INITIALIZED_DATA, IMAGE_SCN_LNK_COMDAT, IMAGE_SCN_MEM_DISCARDABLE, IMAGE_SCN_MEM_READ ]
    Alignment:       1
    SectionData:     '0500'
    SizeOfRawData:   2
symbols:
  - Name:            .text
    Value:           0
    SectionNumber:   1
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_NULL
    StorageClass:    IMAGE_SYM_CLASS_STATIC
    SectionDefinition:
      Length:          1
      NumberOfRelocations: 0
      NumberOfLinenumbers: 0
      CheckSum:        0
      Number:          1
      Selection:       IMAGE_COMDAT_SELECT_NODUPLICATES
  - Name:            .llvm_bb_addr_map
    Value:           0
    SectionNumber:   2
    SimpleType:      IMAGE_SYM_TYPE_NULL
    ComplexType:     IMAGE_SYM_DTYPE_NULL
    StorageClass:    IMAGE_SYM_CLASS_STATIC
    SectionDefinition:
      Length:          2
      NumberOfRelocations: 0
      NumberOfLinenumbers: 0
      CheckSum:        0
      Number:          1
      Selection:       IMAGE_COMDAT_SELECT_ASSOCIATIVE
)");

  Storage.clear();
  ObjOrErr = toBinary(Storage, TruncatedYaml);
  ASSERT_THAT_EXPECTED(ObjOrErr, Succeeded());
  Obj = dyn_cast<COFFObjectFile>(ObjOrErr->get());
  ASSERT_NE(Obj, nullptr);

  EXPECT_THAT_ERROR(
      Obj->readBBAddrMap(/*TextSectionIndex=*/std::nullopt).takeError(),
      FailedWithMessage(testing::HasSubstr("unable to decode")));
}
