---
title: Apple 操作系统可执行文件 Mach-O
date: 2020-03-29 16:13:45
tags: [iOS, Apple, Mach-O]
categories: Programming
---

## 介绍
Mach-O 的全称是 Mach Object File Format。可以是可执行文件，目标代码或共享库，动态库。Mach 内核的操作系统比如 macOS，iPadOS 和 iOS 都是用的 Mach-O。Mach-O 包含程序的核心逻辑，以及入口点主要功能。


通过学习 Mach-O，可以了解应用程序是如何加载到系统的，如何执行的。还能了解符号查找，函数调用堆栈符号化等。更重要的是能够了解如何设计数据结构，这对于日后开发生涯的收益是长期的。了解这些对于了解编译和逆向工程都会有帮助，你还会了解到动态链接器的内部工作原理以及字节码格式的信息，Leb128字节流，Mach 导出时 Trie 二进制 image 压缩。

对于 Mach-O，你一定不陌生，但是对于它内部逻辑你一定会好奇，比如它是怎么构建出来的，组织方式如何，怎么加载的，如何工作，谁让它工作的，怎样导入和导出符号的。


接下来我们先看看怎么构建一个 Mach-O 文件的吧。
## 构建


构建 Mach-O 文件，主要需要用到编译器和静态链接器，编译器可以将编写的高级语言代码转成中间目标文件，然后用静态链接器把中间目标文件组合成 Mach-O。


编译器驱动程序使用的是 clang，有编译、组装和链接的能力，调用 Xcode Tools 里的其他工具来实现源码到 Mach-O 文件生成。其他工具包括将汇编代码创建为中间目标文件的 as 汇编程序，组合中间目标文件成 Mach-O 文件的静态链接器 ld，还有创建静态库或共享库的 libtool。


构建成 Mach-O 包括中间对象文件（MH_OBJECT）、可执行二进制（MH_EXECUTE）、VM 共享库文件（MH_FVMLIB）、Crash 产生的 Core 文件（MH_CORE）、preload（MH_PRELOAD）、动态共享库（MH_DYLIB）、动态链接器（MH_DYLINKER）、静态链接文件（MH_DYLIB_STUB）、符号文件和调试信息（MH_DSYM）这几种类型。其中框架会包含Mach-O和图片、文档、接口等相关资源。


写个 main.c 文件代码：


```c
#include <stdlib.h>

int main(int argc, char *argv[]) { 
    const char *name = argv[1];
    printf("%s\n", name);
    return 0; 
}
```


通过 clang 构建成 Mach-O 文件 a.out。


```c
xcrun clang main.c
```


如果有多个文件，先将多个文件生成中间目标文件，后缀是.o，使用 clang 的选项 -c。每个目标文件都是模块。使用静态链接器可以把多个模块组合成一个动态共享库。通过 ld 可以完成这个操作。使用 libtool 的选项 -static 可以构建静态库。


组合成动态库可以使用 clang 的 -dynamiclib 选项，命令如下：


```c
xcrun clang -dynamiclib command.c header.c -fvisibility=hidden -o mac.dylib
```


静态链接就是把各个模块组合成一个整体，生成新的 Mach-O，链接的内容就是把各个模块间相互的引用能够正确的链接好，原理就是把一些指令对其他符号的地址引用进行修正。过程包含地址和空间分配，符号解析和围绕符号进行的重定位。核心是重定位，X86-64寻址方式是 RIP-relative 寻址，就是基于 RIP 来计算目标地址，通过 jumpq 跳转目标地址，就是当前指令下一条指令地址来加偏移量。


构建完 Mach-O。那你一定好奇 Mach-O 里面都有什么呢？分析 Mach-O 的工具有分析体系结构的 lipo，显式文件类型的 file，列 Data 内容的 otool，分析 image 每个逻辑信息符号的 pagestuff，符号表显示的 nm。


## 组成


Mach-O 会将数据流分组，每组都会有自己的意义，主要分三大部分，分别是 Mach Header、Load Command、Data。


### Header
Mach Header 里会有 Mach-O 的 CPU 信息，以及 Load Command 的信息。可以使用 otool 查看内容：


```c
otool -v -h a.out
```


结果如下：


```c
Mach header
      magic cputype cpusubtype  caps    filetype ncmds sizeofcmds      flags
MH_MAGIC_64  X86_64        ALL  0x00     EXECUTE    16       1368   NOUNDEFS DYLDLINK TWOLEVEL PIE
```


通过 _dyld_get_image_header 函数可以获取 mach_header 结构体。[GCDFetchFeed/SMCallStack.m at master · ming1016/GCDFetchFeed · GitHub](https://github.com/ming1016/GCDFetchFeed/blob/master/GCDFetchFeed/GCDFetchFeed/Lib/SMLagMonitor/SMCallStack.m) 里这段代码里有判断 Mach Header 结构体魔数的函数 smCmdFirstPointerFromMachHeader，代码如下：


```c
uintptr_t smCmdFirstPointerFromMachHeader(const struct mach_header* const machHeader) {
    switch (machHeader->magic) {
        case MH_MAGIC:
        case MH_CIGAM:
        case MH_MAGIC_64:
        case MH_CIGAM_64:
            return (uintptr_t)(((machHeaderByCPU*)machHeader) + 1);
        default:
            return 0; // Header 不合法
    }
}
```


还有 Fat Header，里面会包含多个架构的 Header。


LLVM 中生成 Mach Header 的代码如下：


```c
void MachOFileLayout::writeMachHeader() {
  auto cpusubtype = MachOLinkingContext::cpuSubtypeFromArch(_file.arch);
  // dynamic x86 executables on newer OS version should also set the
  // CPU_SUBTYPE_LIB64 mask in the CPU subtype.
  // FIXME: Check that this is a dynamic executable, not a static one.
  if (_file.fileType == llvm::MachO::MH_EXECUTE &&
      cpusubtype == CPU_SUBTYPE_X86_64_ALL &&
      _file.os == MachOLinkingContext::OS::macOSX) {
    uint32_t version;
    bool failed = MachOLinkingContext::parsePackedVersion("10.5", version);
    if (!failed && _file.minOSverson >= version)
      cpusubtype |= CPU_SUBTYPE_LIB64;
  }

  mach_header *mh = reinterpret_cast<mach_header*>(_buffer);
  mh->magic = _is64 ? llvm::MachO::MH_MAGIC_64 : llvm::MachO::MH_MAGIC;
  mh->cputype =  MachOLinkingContext::cpuTypeFromArch(_file.arch);
  mh->cpusubtype = cpusubtype;
  mh->filetype = _file.fileType;
  mh->ncmds = _countOfLoadCommands;
  mh->sizeofcmds = _endOfLoadCommands - _startOfLoadCommands;
  mh->flags = _file.flags;
  if (_swap)
    swapStruct(*mh);
}
```


### Load Command
Load Command 包含 Mach-O 里命令类型信息，名称和二进制文件的位置。


使用 otool 命令可以查看详细：


```c
otool -v -l a.out
```


遍历 Mach Header 里的 ncmds 可以取到所有 Load Command。代码如下：


```c
for (uint32_t iCmd = 0; iCmd < machHeader->ncmds; iCmd++) {
        const struct load_command* loadCmd = (struct load_command*)cmdPointer;
}
```


load_command 里的 cmd 是以 LC_ 开头定义的宏，可以参看 loader.h 里的定义，有50多个，主要的是：

- LC_SEGMENT_64(_PAGEZERO)
- LC_SEGMENT_64(_TEXT)
- LC_SEGMENT_64(_DATA)
- LC_SEGMENT_64(_LINKEDIT)
- LC_DYLD_INFO_ONLY
- LC_SYMTAB
- LC_DYSYMTAB
- LC_LOAD_DYLINKER
- LC_UUID
- LC_BUILD_VERSION
- LC_SOURCE_VERSION
- LC_MAIN
- LC_LOAD_DYLIB(libSystem.B.dylib)
- LC_FUNCTION_STARTS
- LC_DATA_IN_CODE



每个 command 的结构都是独立的，前两个字段 cmd 和 cmdsize 是一样的。


根据 Load Command 可以得到 Segment 的偏移量。


生成 Load Command 的代码如下：
```c
llvm::Error MachOFileLayout::writeLoadCommands() {
  uint8_t *lc = &_buffer[_startOfLoadCommands];
  if (_file.fileType == llvm::MachO::MH_OBJECT) {
    // Object files have one unnamed segment which holds all sections.
    if (_is64) {
     if (auto ec = writeSingleSegmentLoadCommand<MachO64Trait>(lc))
       return ec;
    } else {
      if (auto ec = writeSingleSegmentLoadCommand<MachO32Trait>(lc))
        return ec;
    }
    // Add LC_SYMTAB with symbol table info
    symtab_command* st = reinterpret_cast<symtab_command*>(lc);
    st->cmd     = LC_SYMTAB;
    st->cmdsize = sizeof(symtab_command);
    st->symoff  = _startOfSymbols;
    st->nsyms   = _file.stabsSymbols.size() + _file.localSymbols.size() +
                  _file.globalSymbols.size() + _file.undefinedSymbols.size();
    st->stroff  = _startOfSymbolStrings;
    st->strsize = _endOfSymbolStrings - _startOfSymbolStrings;
    if (_swap)
      swapStruct(*st);
    lc += sizeof(symtab_command);

    // Add LC_VERSION_MIN_MACOSX, LC_VERSION_MIN_IPHONEOS,
    // LC_VERSION_MIN_WATCHOS, LC_VERSION_MIN_TVOS
    writeVersionMinLoadCommand(_file, _swap, lc);

    // Add LC_FUNCTION_STARTS if needed.
    if (_functionStartsSize != 0) {
      linkedit_data_command* dl = reinterpret_cast<linkedit_data_command*>(lc);
      dl->cmd      = LC_FUNCTION_STARTS;
      dl->cmdsize  = sizeof(linkedit_data_command);
      dl->dataoff  = _startOfFunctionStarts;
      dl->datasize = _functionStartsSize;
      if (_swap)
        swapStruct(*dl);
      lc += sizeof(linkedit_data_command);
    }

    // Add LC_DATA_IN_CODE if requested.
    if (_file.generateDataInCodeLoadCommand) {
      linkedit_data_command* dl = reinterpret_cast<linkedit_data_command*>(lc);
      dl->cmd      = LC_DATA_IN_CODE;
      dl->cmdsize  = sizeof(linkedit_data_command);
      dl->dataoff  = _startOfDataInCode;
      dl->datasize = _dataInCodeSize;
      if (_swap)
        swapStruct(*dl);
      lc += sizeof(linkedit_data_command);
    }
  } else {
    // Final linked images have sections under segments.
    if (_is64) {
      if (auto ec = writeSegmentLoadCommands<MachO64Trait>(lc))
        return ec;
    } else {
      if (auto ec = writeSegmentLoadCommands<MachO32Trait>(lc))
        return ec;
    }

    // Add LC_ID_DYLIB command for dynamic libraries.
    if (_file.fileType == llvm::MachO::MH_DYLIB) {
      dylib_command *dc = reinterpret_cast<dylib_command*>(lc);
      StringRef path = _file.installName;
      uint32_t size = sizeof(dylib_command) + pointerAlign(path.size() + 1);
      dc->cmd                         = LC_ID_DYLIB;
      dc->cmdsize                     = size;
      dc->dylib.name                  = sizeof(dylib_command); // offset
      // needs to be some constant value different than the one in LC_LOAD_DYLIB
      dc->dylib.timestamp             = 1;
      dc->dylib.current_version       = _file.currentVersion;
      dc->dylib.compatibility_version = _file.compatVersion;
      if (_swap)
        swapStruct(*dc);
      memcpy(lc + sizeof(dylib_command), path.begin(), path.size());
      lc[sizeof(dylib_command) + path.size()] = '\0';
      lc += size;
    }

    // Add LC_DYLD_INFO_ONLY.
    dyld_info_command* di = reinterpret_cast<dyld_info_command*>(lc);
    di->cmd            = LC_DYLD_INFO_ONLY;
    di->cmdsize        = sizeof(dyld_info_command);
    di->rebase_off     = _rebaseInfo.size() ? _startOfRebaseInfo : 0;
    di->rebase_size    = _rebaseInfo.size();
    di->bind_off       = _bindingInfo.size() ? _startOfBindingInfo : 0;
    di->bind_size      = _bindingInfo.size();
    di->weak_bind_off  = 0;
    di->weak_bind_size = 0;
    di->lazy_bind_off  = _lazyBindingInfo.size() ? _startOfLazyBindingInfo : 0;
    di->lazy_bind_size = _lazyBindingInfo.size();
    di->export_off     = _exportTrie.size() ? _startOfExportTrie : 0;
    di->export_size    = _exportTrie.size();
    if (_swap)
      swapStruct(*di);
    lc += sizeof(dyld_info_command);

    // Add LC_SYMTAB with symbol table info.
    symtab_command* st = reinterpret_cast<symtab_command*>(lc);
    st->cmd     = LC_SYMTAB;
    st->cmdsize = sizeof(symtab_command);
    st->symoff  = _startOfSymbols;
    st->nsyms   = _file.stabsSymbols.size() + _file.localSymbols.size() +
                  _file.globalSymbols.size() + _file.undefinedSymbols.size();
    st->stroff  = _startOfSymbolStrings;
    st->strsize = _endOfSymbolStrings - _startOfSymbolStrings;
    if (_swap)
      swapStruct(*st);
    lc += sizeof(symtab_command);

    // Add LC_DYSYMTAB
    if (_file.fileType != llvm::MachO::MH_PRELOAD) {
      dysymtab_command* dst = reinterpret_cast<dysymtab_command*>(lc);
      dst->cmd            = LC_DYSYMTAB;
      dst->cmdsize        = sizeof(dysymtab_command);
      dst->ilocalsym      = _symbolTableLocalsStartIndex;
      dst->nlocalsym      = _file.stabsSymbols.size() +
                            _file.localSymbols.size();
      dst->iextdefsym     = _symbolTableGlobalsStartIndex;
      dst->nextdefsym     = _file.globalSymbols.size();
      dst->iundefsym      = _symbolTableUndefinesStartIndex;
      dst->nundefsym      = _file.undefinedSymbols.size();
      dst->tocoff         = 0;
      dst->ntoc           = 0;
      dst->modtaboff      = 0;
      dst->nmodtab        = 0;
      dst->extrefsymoff   = 0;
      dst->nextrefsyms    = 0;
      dst->indirectsymoff = _startOfIndirectSymbols;
      dst->nindirectsyms  = _indirectSymbolTableCount;
      dst->extreloff      = 0;
      dst->nextrel        = 0;
      dst->locreloff      = 0;
      dst->nlocrel        = 0;
      if (_swap)
        swapStruct(*dst);
      lc += sizeof(dysymtab_command);
    }

    // If main executable, add LC_LOAD_DYLINKER
    if (_file.fileType == llvm::MachO::MH_EXECUTE) {
      // Build LC_LOAD_DYLINKER load command.
      uint32_t size=pointerAlign(sizeof(dylinker_command)+dyldPath().size()+1);
      dylinker_command* dl = reinterpret_cast<dylinker_command*>(lc);
      dl->cmd              = LC_LOAD_DYLINKER;
      dl->cmdsize          = size;
      dl->name             = sizeof(dylinker_command); // offset
      if (_swap)
        swapStruct(*dl);
      memcpy(lc+sizeof(dylinker_command), dyldPath().data(), dyldPath().size());
      lc[sizeof(dylinker_command)+dyldPath().size()] = '\0';
      lc += size;
    }

    // Add LC_VERSION_MIN_MACOSX, LC_VERSION_MIN_IPHONEOS, LC_VERSION_MIN_WATCHOS,
    // LC_VERSION_MIN_TVOS
    writeVersionMinLoadCommand(_file, _swap, lc);

    // Add LC_SOURCE_VERSION
    {
      // Note, using a temporary here to appease UB as we may not be aligned
      // enough for a struct containing a uint64_t when emitting a 32-bit binary
      source_version_command sv;
      sv.cmd       = LC_SOURCE_VERSION;
      sv.cmdsize   = sizeof(source_version_command);
      sv.version   = _file.sourceVersion;
      if (_swap)
        swapStruct(sv);
      memcpy(lc, &sv, sizeof(source_version_command));
      lc += sizeof(source_version_command);
    }

    // If main executable, add LC_MAIN.
    if (_file.fileType == llvm::MachO::MH_EXECUTE) {
      // Build LC_MAIN load command.
      // Note, using a temporary here to appease UB as we may not be aligned
      // enough for a struct containing a uint64_t when emitting a 32-bit binary
      entry_point_command ep;
      ep.cmd       = LC_MAIN;
      ep.cmdsize   = sizeof(entry_point_command);
      ep.entryoff  = _file.entryAddress - _seg1addr;
      ep.stacksize = _file.stackSize;
      if (_swap)
        swapStruct(ep);
      memcpy(lc, &ep, sizeof(entry_point_command));
      lc += sizeof(entry_point_command);
    }

    // Add LC_LOAD_DYLIB commands
    for (const DependentDylib &dep : _file.dependentDylibs) {
      dylib_command* dc = reinterpret_cast<dylib_command*>(lc);
      uint32_t size = sizeof(dylib_command) + pointerAlign(dep.path.size()+1);
      dc->cmd                         = dep.kind;
      dc->cmdsize                     = size;
      dc->dylib.name                  = sizeof(dylib_command); // offset
      // needs to be some constant value different than the one in LC_ID_DYLIB
      dc->dylib.timestamp             = 2;
      dc->dylib.current_version       = dep.currentVersion;
      dc->dylib.compatibility_version = dep.compatVersion;
      if (_swap)
        swapStruct(*dc);
      memcpy(lc+sizeof(dylib_command), dep.path.begin(), dep.path.size());
      lc[sizeof(dylib_command)+dep.path.size()] = '\0';
      lc += size;
    }

    // Add LC_RPATH
    for (const StringRef &path : _file.rpaths) {
      rpath_command *rpc = reinterpret_cast<rpath_command *>(lc);
      uint32_t size = pointerAlign(sizeof(rpath_command) + path.size() + 1);
      rpc->cmd                         = LC_RPATH;
      rpc->cmdsize                     = size;
      rpc->path                        = sizeof(rpath_command); // offset
      if (_swap)
        swapStruct(*rpc);
      memcpy(lc+sizeof(rpath_command), path.begin(), path.size());
      lc[sizeof(rpath_command)+path.size()] = '\0';
      lc += size;
    }

    // Add LC_FUNCTION_STARTS if needed.
    if (_functionStartsSize != 0) {
      linkedit_data_command* dl = reinterpret_cast<linkedit_data_command*>(lc);
      dl->cmd      = LC_FUNCTION_STARTS;
      dl->cmdsize  = sizeof(linkedit_data_command);
      dl->dataoff  = _startOfFunctionStarts;
      dl->datasize = _functionStartsSize;
      if (_swap)
        swapStruct(*dl);
      lc += sizeof(linkedit_data_command);
    }

    // Add LC_DATA_IN_CODE if requested.
    if (_file.generateDataInCodeLoadCommand) {
      linkedit_data_command* dl = reinterpret_cast<linkedit_data_command*>(lc);
      dl->cmd      = LC_DATA_IN_CODE;
      dl->cmdsize  = sizeof(linkedit_data_command);
      dl->dataoff  = _startOfDataInCode;
      dl->datasize = _dataInCodeSize;
      if (_swap)
        swapStruct(*dl);
      lc += sizeof(linkedit_data_command);
    }
  }
  return llvm::Error::success();
}
```


### Data
Data 由 Segment 的数据组成，是 Mach-O 占比最多的部分，有代码有数据，比如符号表。Data 共三个 Segment，__TEXT、__DATA、__LINKEDIT。其中 __TEXT 和 __DATA 对应一个或多个 Section，__LINKEDIT 没有 Section，需要配合 LC_SYMTAB 来解析 symbol table 和 string table。这些里面是 Mach-O 的主要数据。


生成 __LINKEDIT 的代码如下：


```c
void MachOFileLayout::buildLinkEditInfo() {
  buildRebaseInfo();
  buildBindInfo();
  buildLazyBindInfo();
  buildExportTrie();
  computeSymbolTableSizes();
  computeFunctionStartsSize();
  computeDataInCodeSize();
}

void MachOFileLayout::writeLinkEditContent() {
  if (_file.fileType == llvm::MachO::MH_OBJECT) {
    writeRelocations();
    writeFunctionStartsInfo();
    writeDataInCodeInfo();
    writeSymbolTable();
  } else {
    writeRebaseInfo();
    writeBindingInfo();
    writeLazyBindingInfo();
    // TODO: add weak binding info
    writeExportInfo();
    writeFunctionStartsInfo();
    writeDataInCodeInfo();
    writeSymbolTable();
  }
}

```


通过生成 __LINKEDIT 的代码可以看出 __LINKEDIT 里包含 dyld 所需各种数据，比如符号表、间接符号表、rebase 操作码、绑定操作码、导出符号、函数启动信息、数据表、代码签名等。


__DATA 包含 lazy 和 non lazy 符号指针，还会包含静态数据和全局变量等。可重定位的 Mach-O 文件还会有一个重定位的区域用来存储重定位信息，如果哪个 section 有重定位字节，就会有一个 relocation table 对应。


生成 relocation 的代码如下：


```c
void MachOFileLayout::writeRelocations() {
  uint32_t relOffset = _startOfRelocations;
  for (Section sect : _file.sections) {
    for (Relocation r : sect.relocations) {
      any_relocation_info* rb = reinterpret_cast<any_relocation_info*>(
                                                           &_buffer[relOffset]);
      *rb = packRelocation(r, _swap, _bigEndianArch);
      relOffset += sizeof(any_relocation_info);
    }
  }
}
```


使用 size 命令可以看到内容的分布，使用前面生成的 a.out 来看：


```c
xcrun size -x -l -m a.out
```


结果如下：


```c
Segment __PAGEZERO: 0x100000000 (vmaddr 0x0 fileoff 0)
Segment __TEXT: 0x1000 (vmaddr 0x100000000 fileoff 0)
    Section __text: 0x41 (addr 0x100000f50 offset 3920)
    Section __stubs: 0x6 (addr 0x100000f92 offset 3986)
    Section __stub_helper: 0x1a (addr 0x100000f98 offset 3992)
    Section __cstring: 0x4 (addr 0x100000fb2 offset 4018)
    Section __unwind_info: 0x48 (addr 0x100000fb8 offset 4024)
    total 0xad
Segment __DATA_CONST: 0x1000 (vmaddr 0x100001000 fileoff 4096)
    Section __got: 0x8 (addr 0x100001000 offset 4096)
    total 0x8
Segment __DATA: 0x1000 (vmaddr 0x100002000 fileoff 8192)
    Section __la_symbol_ptr: 0x8 (addr 0x100002000 offset 8192)
    Section __data: 0x8 (addr 0x100002008 offset 8200)
    total 0x10
Segment __LINKEDIT: 0x1000 (vmaddr 0x100003000 fileoff 12288)
total 0x100004000
```


其中__TEXT Segment 的内容有：

- Section64(__TEXT,__text)
- Section64(__TEXT,__stubs)
- Section64(__TEXT,__stub_helper)
- Section64(__TEXT,__cstring)
- Section64(__TEXT,__unwind_info)



__DATA Segment 的内容有：

- Section64(__DATA,__nl_symbol_ptr)
- Section64(__DATA,__la_symbol_ptr)



__LINKEDIT 的内容是：

- Dynamic Loader Info
- Function Starts
- Symbol Table
- Data in Code Entries
- Dynamic Symbol Table
- String Table




如果是 Objective-C 代码生成的 Mach-O 会多出很多和 Objective-C 相关的 Section ，我拿[已阅](https://github.com/ming1016/GCDFetchFeed)项目生成的 Mach-O 来看。


```c
xcrun size -x -l -m GCDFetchFeed
```


结果如下：


```c
Segment __PAGEZERO: 0x100000000 (vmaddr 0x0 fileoff 0)
Segment __TEXT: 0xa8000 (vmaddr 0x100000000 fileoff 0)
    Section __text: 0x89084 (addr 0x1000020e0 offset 8416)
    Section __stubs: 0x588 (addr 0x10008b164 offset 569700)
    Section __stub_helper: 0x948 (addr 0x10008b6ec offset 571116)
    Section __gcc_except_tab: 0x1318 (addr 0x10008c034 offset 573492)
    Section __cstring: 0xbebd (addr 0x10008d34c offset 578380)
    Section __objc_methname: 0xa20f (addr 0x100099209 offset 627209)
    Section __objc_classname: 0x11d9 (addr 0x1000a3418 offset 668696)
    Section __objc_methtype: 0x2185 (addr 0x1000a45f1 offset 673265)
    Section __const: 0x23c (addr 0x1000a6780 offset 681856)
    Section __ustring: 0x23e (addr 0x1000a69bc offset 682428)
    Section __entitlements: 0x184 (addr 0x1000a6bfa offset 683002)
    Section __unwind_info: 0x1274 (addr 0x1000a6d80 offset 683392)
    total 0xa5f08
Segment __DATA: 0x2f000 (vmaddr 0x1000a8000 fileoff 688128)
    Section __nl_symbol_ptr: 0x8 (addr 0x1000a8000 offset 688128)
    Section __got: 0x258 (addr 0x1000a8008 offset 688136)
    Section __la_symbol_ptr: 0x760 (addr 0x1000a8260 offset 688736)
    Section __const: 0x4238 (addr 0x1000a89c0 offset 690624)
    Section __cfstring: 0x9d80 (addr 0x1000acbf8 offset 707576)
    Section __objc_classlist: 0x510 (addr 0x1000b6978 offset 747896)
    Section __objc_nlclslist: 0x40 (addr 0x1000b6e88 offset 749192)
    Section __objc_catlist: 0x90 (addr 0x1000b6ec8 offset 749256)
    Section __objc_nlcatlist: 0x10 (addr 0x1000b6f58 offset 749400)
    Section __objc_protolist: 0x80 (addr 0x1000b6f68 offset 749416)
    Section __objc_imageinfo: 0x8 (addr 0x1000b6fe8 offset 749544)
    Section __objc_const: 0x182e8 (addr 0x1000b6ff0 offset 749552)
    Section __objc_selrefs: 0x2bf8 (addr 0x1000cf2d8 offset 848600)
    Section __objc_protorefs: 0x8 (addr 0x1000d1ed0 offset 859856)
    Section __objc_classrefs: 0x858 (addr 0x1000d1ed8 offset 859864)
    Section __objc_superrefs: 0x370 (addr 0x1000d2730 offset 862000)
    Section __objc_ivar: 0xb48 (addr 0x1000d2aa0 offset 862880)
    Section __objc_data: 0x32a0 (addr 0x1000d35e8 offset 865768)
    Section __data: 0x604 (addr 0x1000d6888 offset 878728)
    Section __bss: 0x158 (addr 0x1000d6e90 offset 0)
    total 0x2efe4
Segment __LINKEDIT: 0xae000 (vmaddr 0x1000d7000 fileoff 880640)
total 0x100185000
```


可以看到 __objc 前缀的都是为了支持 Objective-C 语言新增加的。


那么 Swift 语言代码构建的 Mach-O 是怎样的呢？


使用我做启动优化时用 Swift 写的工具 [MethodTraceAnalyze](https://github.com/ming1016/MethodTraceAnalyze) 看下内容有什么。结果如下：


```c
Segment __PAGEZERO: 0x100000000 (vmaddr 0x0 fileoff 0)
Segment __TEXT: 0x115000 (vmaddr 0x100000000 fileoff 0)
    Section __text: 0xfd540 (addr 0x1000019b0 offset 6576)
    Section __stubs: 0x6f6 (addr 0x1000feef0 offset 1044208)
    Section __stub_helper: 0xbaa (addr 0x1000ff5e8 offset 1045992)
    Section __swift5_typeref: 0xf56 (addr 0x100100192 offset 1048978)
    Section __swift5_capture: 0x3b4 (addr 0x1001010e8 offset 1052904)
    Section __cstring: 0x7011 (addr 0x1001014a0 offset 1053856)
    Section __const: 0x4754 (addr 0x1001084c0 offset 1082560)
    Section __swift5_fieldmd: 0x2bf4 (addr 0x10010cc14 offset 1100820)
    Section __swift5_types: 0x1f0 (addr 0x10010f808 offset 1112072)
    Section __swift5_builtin: 0x78 (addr 0x10010f9f8 offset 1112568)
    Section __swift5_reflstr: 0x2740 (addr 0x10010fa70 offset 1112688)
    Section __swift5_proto: 0x154 (addr 0x1001121b0 offset 1122736)
    Section __swift5_assocty: 0x120 (addr 0x100112304 offset 1123076)
    Section __objc_methname: 0x7a5 (addr 0x100112424 offset 1123364)
    Section __swift5_protos: 0x8 (addr 0x100112bcc offset 1125324)
    Section __unwind_info: 0x1c70 (addr 0x100112bd4 offset 1125332)
    Section __eh_frame: 0x7b0 (addr 0x100114848 offset 1132616)
    total 0x11362c
Segment __DATA_CONST: 0x4000 (vmaddr 0x100115000 fileoff 1134592)
    Section __got: 0x4a8 (addr 0x100115000 offset 1134592)
    Section __const: 0x32f8 (addr 0x1001154a8 offset 1135784)
    Section __objc_classlist: 0xd0 (addr 0x1001187a0 offset 1148832)
    Section __objc_protolist: 0x10 (addr 0x100118870 offset 1149040)
    Section __objc_imageinfo: 0x8 (addr 0x100118880 offset 1149056)
    total 0x3888
Segment __DATA: 0x8000 (vmaddr 0x100119000 fileoff 1150976)
    Section __la_symbol_ptr: 0x948 (addr 0x100119000 offset 1150976)
    Section __objc_const: 0x2018 (addr 0x100119948 offset 1153352)
    Section __objc_selrefs: 0xb0 (addr 0x10011b960 offset 1161568)
    Section __objc_protorefs: 0x10 (addr 0x10011ba10 offset 1161744)
    Section __objc_classrefs: 0x38 (addr 0x10011ba20 offset 1161760)
    Section __objc_data: 0x98 (addr 0x10011ba58 offset 1161816)
    Section __data: 0x1f88 (addr 0x10011baf0 offset 1161968)
    Section __bss: 0x2a68 (addr 0x10011da80 offset 0)
    Section __common: 0x50 (addr 0x1001204e8 offset 0)
    total 0x7530
Segment __LINKEDIT: 0x152000 (vmaddr 0x100121000 fileoff 1171456)
total 0x100273000
```


可以看到 __DATA Segment 部分还是有 __objc 前缀的 Section，__TEXT Segment 里已经都是 __swift5 为前缀的 Section 了。


使用 otool 可以查看某个 Section 内容。比如查看 __TEXT Segment 的 __text Section 的内容，使用如下命令：


```c
xcrun otool -s __TEXT __text a.out
```


使用 otool 可以直接看 Mach-O 汇编内容 ：


```c
xcrun otool -v -t a.out
```


结果如下：


```c
a.out:
(__TEXT,__text) section
_main:
0000000100000f50    pushq   %rbp
0000000100000f51    movq    %rsp, %rbp
0000000100000f54    subq    $0x20, %rsp
0000000100000f58    movl    $0x0, -0x4(%rbp)
0000000100000f5f    movl    %edi, -0x8(%rbp)
0000000100000f62    movq    %rsi, -0x10(%rbp)
0000000100000f66    movq    -0x10(%rbp), %rax
0000000100000f6a    movq    0x8(%rax), %rax
0000000100000f6e    movq    %rax, -0x18(%rbp)
0000000100000f72    movq    -0x18(%rbp), %rsi
0000000100000f76    leaq    0x35(%rip), %rdi
0000000100000f7d    movb    $0x0, %al
0000000100000f7f    callq   0x100000f92
0000000100000f84    xorl    %ecx, %ecx
0000000100000f86    movl    %eax, -0x1c(%rbp)
0000000100000f89    movl    %ecx, %eax
0000000100000f8b    addq    $0x20, %rsp
0000000100000f8f    popq    %rbp
0000000100000f90    retq
```


构建中查看代码生成汇编可以使用 clang 以下选项：


```c
xcrun clang -S -o - main.c
```


 生成汇编如下：


```c
    .section    __TEXT,__text,regular,pure_instructions
    .build_version macos, 10, 15    sdk_version 10, 15, 4
    .globl  _main                   ## -- Begin function main
    .p2align    4, 0x90
_main:                                  ## @main
    .cfi_startproc
## %bb.0:
    pushq   %rbp
    .cfi_def_cfa_offset 16
    .cfi_offset %rbp, -16
    movq    %rsp, %rbp
    .cfi_def_cfa_register %rbp
    subq    $32, %rsp
    movl    $0, -4(%rbp)
    movl    %edi, -8(%rbp)
    movq    %rsi, -16(%rbp)
    movq    -16(%rbp), %rax
    movq    8(%rax), %rax
    movq    %rax, -24(%rbp)
    movq    -24(%rbp), %rsi
    leaq    L_.str(%rip), %rdi
    movb    $0, %al
    callq   _printf
    xorl    %ecx, %ecx
    movl    %eax, -28(%rbp)         ## 4-byte Spill
    movl    %ecx, %eax
    addq    $32, %rsp
    popq    %rbp
    retq
    .cfi_endproc
                                        ## -- End function
    .section    __TEXT,__cstring,cstring_literals
L_.str:                                 ## @.str
    .asciz  "%s\n"
```


可以发现两者汇编逻辑是一样的。点符号开头的都是汇编指令，比如.section 就是告知会执行哪个 segment，.p2align 指令明确后面代码对齐方式，这里是16(2^4) 字节对齐，0x90 补齐。在 __TEXT Segment 的 __text Section 里会创建一个调用帧堆栈，进行函数调用，callq printf 函数前会用到 L_.str(%rip)，L_.str 标签会指向字符串，leaq 会把字符串的指针加载到 rdi 寄存器。最后会销毁调用帧堆栈，进行 retq 返回。


主要 Section：

- __nl_symbol_ptr：包含 non-lazy 符号指针，mach-o/loader.h 里有详细说明。服务 dyld_stub_binder 处理的符号。
- __la_symbol_ptr：__stubs 第一个 jump 目标地址。动态库的符号指针地址。
- __got：二进制文件的全局偏移表 GOT，也包含 S_NON_LAZY_SYMBOL_POINTERS 标记的 non-lazy 符号指针。服务于 __TEXT Segment 里的符号。可以将__got 看作一个表，里面每项都是一个地址值。__got 的每项在加载期间都会被 dyld 重写，所以会在 __DATA Segment 中。__got 用来存放 non-lazy 符号最终地址，为 dyld 所用。dylib 外部符号对于全局变量和常量引用地址会指到 __got。
- __lazy_symbol：包含 lazy 符号，首次使用时绑定。
- __stubs：跳转表，重定向到 lazy 和 non-lazy 符号的 section。被标记为 S_SYMBOL_STUBS。__TEXT Segment 里代码和 dylib 外部符号的引用地址对函数符号的引用都指向了 __stubs。其中每项都是 jmp 代码间接寻址，可跳到 __la_symbol_ptr Section 中。
- __stub_helper：lazy 动态绑定符号的辅助函数。可跳到 __nl_symbol_ptr Section 中。
- __text：机器码，也是实际代码，包含所有功能。
- __cstring：常量。只读 C 字符串。
- __const：初始化过的常量。
- __objc_：Objective-C 语言 runtime 的支持。
- __data：初始化过的变量。
- __bss：未初始化的静态变量。
- __unwind_info：生成异常处理信息。
- __eh_frame：DWARF2 unwind 可执行文件代码信息，用于调试。
- string table：以空值终止的字符串序列。
- symbol table：通过 LC_SYMTAB 命令找到 symbol table，其包含所有用到的符号信息。结构体 nlist_64描述了符号的基本信息。nlist_64 结构体中 n_type 字段是一个8位复合字段，其中bit[0:1]表示是外部符号，bit[5:8]表调试符号，bit[4:5]表示私有 external 符号，bit[1:4]是符号类型，有 N_UNDF 未定义、N_ABS 绝对地址、N_SECT 本地符号、N_PBUD 预绑定符号、N_INDR 同名符号几种类型。
- indirect symbol table：每项都是一个 index 值，指向 symbol table 中的项。由 LC_DYSYMTAB 定义，和__nl_symbol_ptr 和 __lazy_symbol 一起为 __stubs 和 __got 等 Section 服务。



生成 Section 的代码如下：


```c
void MachOFileLayout::writeSectionContent() {
  for (const Section &s : _file.sections) {
    // Copy all section content to output buffer.
    if (isZeroFillSection(s.type))
      continue;
    if (s.content.empty())
      continue;
    uint32_t offset = _sectInfo[&s].fileOffset;
    uint8_t *p = &_buffer[offset];
    memcpy(p, &s.content[0], s.content.size());
    p += s.content.size();
  }
}
```


其中 symble table 生成的代码如下：


```c
void MachOFileLayout::writeSymbolTable() {
  // Write symbol table and symbol strings in parallel.
  uint32_t symOffset = _startOfSymbols;
  uint32_t strOffset = _startOfSymbolStrings;
  // Reserve n_strx offset of zero to mean no name.
  _buffer[strOffset++] = ' ';
  _buffer[strOffset++] = '\0';
  appendSymbols(_file.stabsSymbols, symOffset, strOffset);
  appendSymbols(_file.localSymbols, symOffset, strOffset);
  appendSymbols(_file.globalSymbols, symOffset, strOffset);
  appendSymbols(_file.undefinedSymbols, symOffset, strOffset);
  // Write indirect symbol table array.
  uint32_t *indirects = reinterpret_cast<uint32_t*>
                                            (&_buffer[_startOfIndirectSymbols]);
  if (_file.fileType == llvm::MachO::MH_OBJECT) {
    // Object files have sections in same order as input normalized file.
    for (const Section &section : _file.sections) {
      for (uint32_t index : section.indirectSymbols) {
        if (_swap)
          *indirects++ = llvm::sys::getSwappedBytes(index);
        else
          *indirects++ = index;
      }
    }
  } else {
    // Final linked images must sort sections from normalized file.
    for (const Segment &seg : _file.segments) {
      SegExtraInfo &segInfo = _segInfo[&seg];
      for (const Section *section : segInfo.sections) {
        for (uint32_t index : section->indirectSymbols) {
          if (_swap)
            *indirects++ = llvm::sys::getSwappedBytes(index);
          else
            *indirects++ = index;
        }
      }
    }
  }
}
```


获取 Segment 信息的代码如下：


```c
int segmentWalk(void *segment_command) {
  uint32_t nsects;
  void *section;

  section = segment_command + sizeof(struct segment_command);
  nsects = ((struct segment_command *) segment_command)->nsects;

  while (nsects--) {
    section += sizeof(struct s_section);
  }
}
```


获取对应符号的方法代码如下：


```c
// 定义参看 <mach-o/nlist.h>
#define N_UNDF  0x0  // 未定义
#define N_ABS 0x2    // 绝对地址
#define N_SECT 0xe   // 本地符号
#define N_PBUD 0xc   // 预定义符号
#define N_INDR 0xa   // 同名符号

#define N_STAB 0xe0  // 调试符号
#define N_PEXT 0x10  // 私有 external 符号
#define N_TYPE 0x0e  // 类型位的掩码
#define N_EXT 0x01   // external 符号

char symbolical(sym) {
  if (N_STAB & sym->type)
    return '-'; 
  else if ((N_TYPE & sym->type) == N_UNDF) {
    if (sym->name_not_found)
     return 'C';
    else if (sym->type & N_EXT)
     return = 'U';
    else
     return = '?';
  } else if ((N_TYPE & sym->type) == N_SECT) {
    return matched(saved_sections, sym);
  } else if ((N_TYPE & sym->type) == N_ABS) {
    return = 'A';
  } else if ((N_TYPE & sym->type) == N_INDR) {
    return = 'I';
  }
}

char matched(saved_sections, symbol)
{
  if (sect = find_mysection(saved_sections, symbol->n_sect)) # 
  {
    if (!ft_strcmp(sect->name, SECT_TEXT))
      ret = 'T';
    else if (!ft_strcmp(sect->name, SECT_DATA))
      ret = 'D';
    else if (!ft_strcmp(sect->name, SECT_BSS))
      ret = 'B';
    else
      ret = 'S';

    if (!(mysym->type & N_EXT))
       ret -= 'A' - 'a';
  }
}
```


## 加载运行
程序要和其他库还有模块一起运行，需要在运行时对这些库和模块的符号引用进行解析，运行时，你应用程序使用的模块符号都在共享名称空间。macOS 使用的是两级名称空间来确保不同模块符号名不会冲突，同时增强向前兼容。


选择要加载的 Mach-O 后，系统内核会先确定该文件是否是 Mach-O 文件。


文件的第一个字节是魔数，通过魔数可以推断是不是 Mach-O，mach-o/loader.h 里定义了四个魔数标识。


```c
#define MH_MAGIC    0xfeedface
#define MH_CIGAM    NXSwapInt(MH_MAGIC)
#define MH_MAGIC_64 0xfeedfacf
#define MH_CIGAM_64 NXSwapInt(MH_MAGIC_64)
```


以上四个魔数标识是 Mach-O 文件。


然后内核系统会用 fork 函数创建一个进程，然后通过 execve 函数开始程序加载过程，execve 有多个种类，比如 execl、execv 等，只是在参数和环境变量上有不同，最终都会到内核的 execve 函数。


接着会检查 Mach-O header，加载 dyld 和程序到 Load Command 指定的地址空间。执行动态链接器。动态链接器通过 dyld_stub_binder 调用，这个函数的参数不直接指定要绑定的符号，而是通过给 dyld_stub_binder 偏移量到 dyld 解释的特殊字节码 Segment 中。dyld_stub_binder 函数的代码在这里：[dyld_stub_binder.s](https://opensource.apple.com/source/dyld/dyld-635.2/src/dyld_stub_binder.s.auto.html)。dyld 分为 rebase、binding、lazy binding、导出几个部分。dyld 可以 hook，使用 DYLD_INSERT_LIBRARIES，类似 ld 的 LD_PRELOAD 还有 DYLD_LIBRARY_PATH。


__text 里需要被 lazy binding 的符号引用，访问时回到 stub 中，目标地址在 __la_symbol_ptr，对应 __la_symbol_ptr 的内容会指向 __stub_helper，其中逻辑会调到 dyld_stub_binder 函数，这个函数会通过 dyld 找到符号的真实地址，最后 dyld_stub_binder 会把得到的地址写入 __la_symbol_ptr 里后，会跳转到符号的真实地址。由于地址已经在 __la_symbol_ptr 里了，所以再访问符号时会通过 stub 的 jum 指令直接跳转到真实地址。


通过 dyld 加载主程序链接到的所有依赖库，执行符号绑定也就是non lazy binding。绑定解析其他模块的功能和数据的引用过程，也叫导入符号。


### 导入导出符号
执行绑定时，链接程序会用实际定义的地址替换程序的每个导入引用。通过构建时的选项设置，dyld 可以即时绑定，也叫延迟绑定，首次使用引用时的绑定，在使用符号前不会将程序的引用绑定到共享库的符号。使用 -bind_at_load 可以加载时绑定，动态链接程序在加载程序时立即绑定所有导入的引用，如果没有设置这个选项，默认按即时绑定来。设置 -prebind，程序引用的共享库都会在指定的地址预先绑定。


根据 Code Fragment Manager 设计的弱引用允许程序有选择的绑定到指定的共享库，如果 dyld 找不到弱引用的定义，会设置为 NULL，然后可以继续加载程序。代码上可以写判断，如果引用为空进行相应的处理。


过程链接表 PLT，会在运行时确定函数地址。callq 指令在 dyld_stub 调用 PLT 条目，符号 stub 位于 __TEXT Segment 的 __stubs Section 中。每个 Mach-O 符号 stub 都是一个 jumpq 指令，它会调用 dyld 找到符号，然后执行。


Mach-O 的导入和导出都会存在 __LINKEDIT 里。使用 FSA 接受 Leb128 参数，也就是绑定操作码。LEB 会把整数值编码成可变长度的字节序列，最后一个字节才设置最高有效位。

当 FSA 循环或递归时，会用0xF0对其进行掩码获得操作码，所有导入绑定操作码都会对应有宏名称和对应的功能。比如 0xb0 对应宏是 BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED，功能是将记录放到导入堆栈中，然后把当前记录的地址偏移量设为 seg_offset = seg_offset + (scale * sizeofptr) + sizeofptr ，其中 scale 是立即数中包含的值，sizeofptr 是指针对应平台的大小。


Mach-O 导出符号是 [trie](https://en.wikipedia.org/wiki/Trie) 的数据结构，trie 节点最多有一个终端字符串信息，如果没有终端信息，就以0x00字节标记。有的化，就用 Leb128 代替该节点的终端字符串信息大小。节点导出信息后，类型信息类型使用0x3对标志进行位掩码获得。0x00表示常规符号，0x01表示线程本地符号，0x02标识绝对符号，0x4表示弱引用符号，0x8表示重新导出，0x10是 stub，具有 Leb128的 stub 偏移量。大部分符号都是常规符号，会将 Mach-O 的偏移量给符号。

生成 trie 数据结构的代码如下：


```c
void MachOFileLayout::buildExportTrie() {
  if (_file.exportInfo.empty())
    return;

  // For all temporary strings and objects used building trie.
  BumpPtrAllocator allocator;

  // Build trie of all exported symbols.
  auto *rootNode = new (allocator) TrieNode(StringRef());
  std::vector<TrieNode*> allNodes;
  allNodes.reserve(_file.exportInfo.size()*2);
  allNodes.push_back(rootNode);
  for (const Export& entry : _file.exportInfo) {
    rootNode->addSymbol(entry, allocator, allNodes);
  }

  std::vector<TrieNode*> orderedNodes;
  orderedNodes.reserve(allNodes.size());

  for (const Export& entry : _file.exportInfo)
    rootNode->addOrderedNodes(entry, orderedNodes);

  // Assign each node in the vector an offset in the trie stream, iterating
  // until all uleb128 sizes have stabilized.
  bool more;
  do {
    uint32_t offset = 0;
    more = false;
    for (TrieNode* node : orderedNodes) {
      if (node->updateOffset(offset))
        more = true;
    }
  } while (more);

  // Serialize trie to ByteBuffer.
  for (TrieNode* node : orderedNodes) {
    node->appendToByteBuffer(_exportTrie);
  }
  _exportTrie.align(_is64 ? 8 : 4);
}
```

Trie 也叫数字树或前缀树，是一种搜索树。查找复杂度 O(m)，m 是字符串的长度。和散列表相比，散列最差复杂度是 O(N)，一般都是 O(1)，用 O(m)时间评估 hash。散列缺点是会分配一大块内存，内容越多所占内存越大。Trie 不仅查找快，插入和删除都很快，适合存储预测性文本或自动完成词典。为了进一步优化所占空间，可以将 Trie 这种树形的确定性有限自动机压缩成确定性非循环有限状态自动体（DAFSA），其空间小，做法是会压缩相同分支。对于更大内容，还可以做更进一步的优化，比如使用字母缩减的实现技术，把原来的字符串重新解释为较长的字符串；使用单链式列表，节点设计为由符号、子节点、下一个节点来表示；将字母表数组存储为代表 ASCII 字母表的256位的位图。

对于动态库，有几个易于理解的公共符号比导出所有符号更易于使用，让公共符号集少，私有符号集丰富，维护起来更加方便。更新时也不会影响较早版本。导出最少数量的符号，还能够优化动态加载程序到进程的时间，动态库导出符号越少，dyld 加载就越快。


静态存储类是表明不想导出符号的最简单的方法。将可见性属性放置在实现文件中的符号定义里，设置符号可见性也能够更精确的控制哪些符号是公共符号还是私有符号。在编译选项 -fvisbility 可以指定未指定可见性符号的可见性。使用 -weak_library 选项会告诉编译器将库里所有导出符号都设为弱链接符号。使用 nm 的 -gm 选项可以查看 Mach-O 导出的符号：


```c
nm -gm header.dylib
```


结果如下：


```c
                 (undefined) external ___cxa_atexit (from libSystem)
                 (undefined) external _printf (from libSystem)
                 (undefined) external dyld_stub_binder (from libSystem)
```


另外可以通过导出的符号文件，列出要导出的符号来控制导出符号数量，其他符号都会被隐藏。导出符号文件 list 如下：


```c
_foo
_header
```


使用 -exported_symbols_list 选项编译就可以仅导出文件中指定的符号：


```c
clang -dynamiclib header.c -exported_symbols_list list -o header.dylib
```


### 符号绑定范围
符号可能存在与多个作用域级别。未定义的外部符号是在当前文件之外的文件中，如下：


```c
extern int count;
extern void foo(void);
```


私有定义符号，其他模块不可见


```c
static int count;
```


私有外部符号可以使用 __private_extern__关键字：


```c
__private_extern__ int count = 0;
```


指定一个函数为弱引用，可以使用 weak_import 属性：


```c
void foo(void) __attribute__((weak_import));
```


在符号声明中添加 weak 属性来指定将符号设置为合并的弱引用：


```c
void foo(void) __attribute__((weak));
```


### 入口点


符号绑定结果放到 LC_DYSYMTAB 指定的 section，解析后的地址会放到 __DATA segment 的 __nl_symbol_ptr 和 __got 里。dyld 使用 Load Command 指定 Mach-O 中的数据以各种方式链接依赖项。Mach-O 的 Segment 按照 Load Command 中指定映射到内存中。 初始化后，会调用 LC_MAIN 指定的入口点，这个点是 __TEXT Segment 的 __text Section 的开始。使用 __stubs 将 __la_symbol_ptr 指向 __stub_helpers，dyld_stub_binder 执行解析，然后更新 __la_symbol_ptr 的地址。


Mach-O 和链接器之间是通过 assembly trampoline 进行的桥接，Mach-O 接口的 ABI 和 ELF 相同，但策略不同。macOS 在调用 dyld 前后都会保存和恢复 SSE 寄存器。

### 动态库构造函数和析构函数
动态库加载可能需要执行特殊的初始化或者需要做些准备工作，这里可以使用初始化函数也就是构造函数。结束的时候可以加析构函数。


举个例子，先定义一个 header.c，在里面加上构造函数和析构函数：


```c
#include <stdio.h>

__attribute__((constructor))
static void prepare() {
    printf("%s\n", "prepare");
}

__attribute__((destructor))
static void end() {
    printf("%s\n", "end");
}

void showHeader() { 
    printf("%s\n", "header");
}
```


将 header.c 构建成一个动态库 header.dylib。


```c
xcrun clang -dynamiclib header.c -fvisibility=hidden -o header.dylib
```


将 header.dylib 和 main.c 构建成一个中间目标文件 main.o。


```c
xcrun clang main.c header.dylib -o main
```


运行看结果


```c
ming@mingdeMacBook-Pro macho_demo % ./main "hi"
prepare
hi
end
```


可以看到，动态库的构造函数 prepare 和析构函数 end 都执行了。
































