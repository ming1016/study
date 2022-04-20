//
//  CallingConvention.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/19.
//

import llvm

/// Enumerates the calling conventions supported by LLVM.
public enum CallingConvention {
  /// The default LLVM calling convention, compatible with C.
  case c
  /// This calling convention attempts to make calls as fast as possible
  /// (e.g. by passing things in registers). This calling convention
  /// allows the target to use whatever tricks it wants to produce fast
  /// code for the target, without having to conform to an externally
  /// specified ABI (Application Binary Interface). `Tail calls can only
  /// be optimized when this, the `ghc` or the `hiPE` convention is
  /// used. This calling convention does not support varargs and requires the
  /// prototype of all callees to exactly match the prototype of the function
  /// definition.
  case fast
  /// This calling convention attempts to make code in the caller as
  /// efficient as possible under the assumption that the call is not
  /// commonly executed. As such, these calls often preserve all registers
  /// so that the call does not break any live ranges in the caller side.
  /// This calling convention does not support varargs and requires the
  /// prototype of all callees to exactly match the prototype of the
  /// function definition. Furthermore the inliner doesn't consider such
  /// function calls for inlining.
  case cold
  /// This calling convention has been implemented specifically for use by
  /// the Glasgow Haskell Compiler (GHC).
  ///
  /// It passes everything in registers, going to extremes to achieve this
  /// by disabling callee save registers. This calling convention should
  /// not be used lightly but only for specific situations such as an
  /// alternative to the *register pinning* performance technique often
  /// used when implementing functional programming languages. At the
  /// moment only X86 supports this convention and it has the following
  /// limitations:
  ///
  /// -  On *X86-32* only supports up to 4 bit type parameters. No
  /// floating-point types are supported.
  /// -  On *X86-64* only supports up to 10 bit type parameters and 6
  /// floating-point parameters.
  ///
  /// This calling convention supports `tail call
  /// optimization but requires both the caller and callee are using it.
  case ghc
  /// This calling convention has been implemented specifically for use by
  /// the High-Performance Erlang (HiPE) compiler, *the*
  /// native code compiler of the `Ericsson's Open Source Erlang/OTP
  /// system.
  ///
  /// It uses more registers for argument passing than the ordinary C calling
  /// convention and defines no callee-saved registers. The calling
  /// convention properly supports tail call optimization but requires that
  /// both the caller and the callee use it.
  ///
  /// It uses a *register pinning* mechanism, similar to GHC's convention, for
  /// keeping frequently accessed runtime components pinned to specific hardware
  /// registers.
  ///
  /// At the moment only X86 supports this convention (both 32 and 64 bit).
  case hiPE
  /// This calling convention has been implemented for WebKit FTL JIT. It passes
  /// arguments on the stack right to left (as cdecl does), and returns a value
  /// in the platform's customary return register.
  case webKitJS
  /// Calling convention for dynamic register based calls
  /// (e.g. stackmap and patchpoint intrinsics).
  ///
  /// This is a special convention that supports patching an arbitrary code
  /// sequence in place of a call site. This convention forces the call
  /// arguments into registers but allows them to be dynamically
  /// allocated. This can currently only be used with calls to
  /// `llvm.experimental.patchpoint` because only this intrinsic records
  /// the location of its arguments in a side table.
  case anyReg
  /// Calling convention for runtime calls that preserves most registers.
  ///
  /// This calling convention attempts to make the code in the caller as
  /// unintrusive as possible. This convention behaves identically to the `c`
  /// calling convention on how arguments and return values are passed, but it
  /// uses a different set of caller/callee-saved registers. This alleviates the
  /// burden of saving and recovering a large register set before and after the
  /// call in the caller. If the arguments are passed in callee-saved registers,
  /// then they will be preserved by the callee across the call. This doesn't
  /// apply for values returned in callee-saved registers.
  ///
  /// On X86-64 the callee preserves all general purpose registers, except for
  /// R11. R11 can be used as a scratch register. Floating-point registers
  /// (XMMs/YMMs) are not preserved and need to be saved by the caller.
  ///
  /// The idea behind this convention is to support calls to runtime functions
  /// that have a hot path and a cold path. The hot path is usually a small
  /// piece of code that doesn't use many registers. The cold path might need to
  /// call out to another function and therefore only needs to preserve the
  /// caller-saved registers, which haven't already been saved by the caller.
  ///
  /// The `preserveMost` calling convention is very similar to the `cold`
  /// calling convention in terms of caller/callee-saved registers, but they are
  /// used for different types of function calls. `cold` is for function calls
  /// that are rarely executed, whereas `preserveMost` function calls are
  /// intended to be on the hot path and definitely executed a lot. Furthermore
  /// `preserveMost` doesn't prevent the inliner from inlining the function
  /// call.
  ///
  /// This calling convention will be used by a future version of the
  /// Objective-C runtime and should therefore still be considered experimental
  /// at this time.
  ///
  /// Although this convention was created to optimize certain runtime calls to
  /// the ObjectiveC runtime, it is not limited to this runtime and might be
  /// used by other runtimes in the future too.
  ///
  /// The current implementation only supports X86-64, but the intention is to
  /// support more architectures in the future.
  case preserveMost
  /// This calling convention attempts to make the code in the caller even less
  /// intrusive than the `preserveMost` calling convention. This calling
  /// convention also behaves identical to the `c` calling convention on how
  /// arguments and return values are passed, but it uses a different set of
  /// caller/callee-saved registers. This removes the burden of saving and
  /// recovering a large register set before and after the call in the caller.
  ///
  /// If the arguments are passed in callee-saved registers, then they will be
  /// preserved by the callee across the call. This doesn't apply for values
  /// returned in callee-saved registers.
  ///
  /// - On X86-64 the callee preserves all general purpose registers, except for
  /// R11. R11 can be used as a scratch register. Furthermore it also preserves
  /// all floating-point registers (XMMs/YMMs).
  ///
  /// The idea behind this convention is to support calls to runtime functions
  /// that don't need to call out to any other functions.
  ///
  /// This calling convention, like the `preserveMost` calling convention,
  /// will be used by a future version of the ObjectiveC runtime and should be
  /// considered experimental at this time.
  case preserveAll
  /// Calling convention for Swift.
  ///
  /// - On X86-64 `RCX` and `R8` are available for additional integer returns,
  /// and `XMM2` and `XMM3` are available for additional FP/vector returns.
  /// - On iOS platforms, we use the `armAAPCSVFP` calling convention.
  case swift
  /// The calling convention for accessors to C++-style thread-local storage.
  ///
  /// The access function generally has an entry block, an exit block
  /// and an initialization block that is run at the first time. The entry and
  /// exit blocks can access a few TLS IR variables, each access will be lowered
  /// to a platform-specific sequence.
  ///
  /// This calling convention aims to minimize overhead in the caller by
  /// preserving as many registers as possible (all the registers that are
  /// perserved on the fast path, composed of the entry and exit blocks).
  ///
  /// This calling convention behaves identical to the `C` calling convention on
  /// how arguments and return values are passed, but it uses a different set of
  /// caller/callee-saved registers.
  ///
  /// Given that each platform has its own lowering sequence, hence its own set
  /// of preserved registers, we can't use the existing `preserveMost`.
  ///
  /// - On X86-64 the callee preserves all general purpose registers, except for
  /// RDI and RAX.
  case cxxFastThreadLocalStorage
  /// The calling conventions mostly used by the Win32 API.
  ///
  /// It is basically the same as the C convention with the difference in that
  /// the callee is responsible for popping the arguments from the stack.
  case x86StandardCall
  /// "Fast" analog of `x86Stdcall`.
  ///
  /// Passes first two arguments in ECX:EDX registers, others via the stack.
  /// The callee is responsible for stack cleaning.
  case x86FastCall
  /// Short for "ARM Procedure Calling Standard" calling convention (obsolete,
  /// but still used on some targets).
  case armAPCS
  /// Short for "ARM Architecture Procedure Calling Standard" calling
  /// convention.  This is often referred to as EABI - though this terminology
  /// can be confusing for those that remember EABI from PowerPC.
  ///
  /// `armAAPCS` is the modern incarnation of `armAPCS`.  It enables a number of
  /// desirable optimizations over `armAPCS` such as tighter packing of
  /// structures and (emulated) floating point instructions. `armAPCS` suffered
  /// a 10x performance penalty in environments without a floating point
  /// co-processor, as floating routines would be implemented by trapping to
  /// software implementations in the kernel.
  case armAAPCS
  /// Same as `armAAPCS`, but uses hardware floating point ABI.  On
  /// ARM architectures before ARMv8, these instructions are implemented as
  /// co-processor extensions.
  ///
  /// Despite `VFP` being short for "Vector Floating Point", processing of data
  /// is entirely sequential.  VFP does not perform actual vector computing
  /// in the usual sense (SIMD), and is generally replaced by NEON intrinsics.
  case armAAPCSVFP
  /// Calling convention used for MSP430 interrupt service routines (ISRs).
  ///
  /// ISRs may not accept or return arguments in registers.  They should ideally
  /// save all registers when they are first invoked and must clean up before
  /// returning with the special `RETI` instruction.  LLVM will trap if any of
  /// these invariants are violated.
  case msp430Interrupt
  /// Similar to `x86Stdcall`.
  ///
  /// - On x86_64 it passes the first argument (a pointer to `this` in C++) in
  /// `ECX` and the others via the stack from right to left. The callee is
  /// responsible for popping the arguments from the stack.
  ///
  /// MSVC uses this by default for methods in its ABI for all non-variadic
  /// member method calls.
  case x86ThisCall
  /// Calling convention for Parallel Thread Execution (PTX) kernel functions.
  ///
  /// In PTX, there are two types of functions: device functions, which are only
  /// callable by device code, and kernel functions, which are callable by host
  /// code.  Use this calling convention for kernel functions.
  ///
  /// The parameter (`.param`) state space is used to pass input arguments
  /// from the host to the kernel, to declare formal input and return
  /// parameters for device functions called from within kernel execution, and
  /// to declare locally-scoped byte array variables that serve as function
  /// call arguments, typically for passing large structures by value to a
  /// function.
  ///
  /// Kernel function parameters differ from device function parameters in terms
  /// of access and sharing (read-only versus read-write, per-kernel versus
  /// per-thread).
  case ptxKernelFunction
  /// Calling convention for Parallel Thread Execution (PTX) device functions.
  ///
  /// Passes all arguments in register or parameter space.
  ///
  /// Registers (.reg state space) are fast storage locations. The number of
  /// registers is limited, and will vary from platform to platform. When the
  /// limit is exceeded, register variables will be spilled to memory, causing
  /// changes in performance.
  ///
  /// Device function parameters differ from kernel function parameters in that
  /// they may not necessarily be directly addressable.  Because the exact
  /// location of argument values is implementation-defined, requesting the
  /// address of a device argument is generally not supported.
  case ptxDeviceFunction
  /// Calling convention for SPIR non-kernel device functions.
  ///
  /// No lowering or expansion of arguments.
  /// Structures are passed as a pointer to a struct with the byval attribute.
  /// Functions can only call SPIR_FUNC and SPIR_KERNEL functions.
  /// Functions can only have zero or one return values.
  /// Variable arguments are not allowed, except for printf.
  /// How arguments/return values are lowered are not specified.
  /// Functions are only visible to the devices.
  case spirDeviceFunction
  /// Calling convention for SPIR kernel functions.
  ///
  /// Inherits the restrictions of `.spirFunction`, except
  /// Cannot have non-void return values.
  /// Cannot have variable arguments.
  /// Can also be called by the host.
  /// Is externally visible.
  case spirKernelFunction
  /// Calling conventions for Intel OpenCL built-ins.
  ///
  /// Extends the x86_32 C ABI for passing and returning values by a set of
  /// high-bitwidth registers for passing arguments and returning values from
  /// functions, and a set of mask registers.
  case intelOpenCLBuiltin
  /// The C convention as specified in the x86-64 supplement to the
  /// System V ABI, used on most non-Windows systems.
  case x8664SystemV
  /// The C convention as implemented on Windows/x86-64 and
  /// AArch64. This convention differs from the more common
  /// `x8664SystemV` convention in a number of ways, most notably in
  /// that XMM registers used to pass arguments are shadowed by GPRs,
  /// and vice versa.
  ///
  /// On AArch64, this is identical to the normal C (`aapcs`) calling
  /// convention for normal functions, but floats are passed in integer
  /// registers to variadic functions.
  case win64
  /// MSVC calling convention that passes vectors and vector aggregates
  /// in SSE registers.
  case x86VectorCall
  /// Calling convention used by HipHop Virtual Machine (HHVM) to
  /// perform calls to and from translation cache, and for calling PHP
  /// functions.
  ///
  /// HHVM is a very relaxed convention that marks as many registers as
  /// general-purpose as possible, including RBP which contains the first
  /// argument, but excluding RSP and R12 which are used for the stack pointer
  /// and return value respectively.
  ///
  /// This calling convention supports tail and sibling call elimination.
  case hhvm
  /// HHVM calling convention for invoking C/C++ helpers.
  ///
  /// This calling convention differs from the standard `c` calling convention
  /// in that the first argument is passed in RBP.
  case hhvmc
  /// The calling convention for x86 hardware interrupts.
  ///
  /// The callee may take one or two parameters, where the 1st represents a
  /// pointer to hardware context frame and the 2nd represents a hardware error
  /// code. The presence of the latter depends on the interrupt vector taken.
  ///
  /// This convention is valid for both 32-bit and 64-bit subtargets.
  case x86Interrupt
  /// Calling convention for AVR interrupt routines.
  case avrInterrupt
  /// Calling convention used for AVR signal routines.
  case avrSignal
  /// Calling convention used for special AVR rtlib functions
  /// which have an "optimized" convention to preserve registers.
  case avrBuiltin
  /// Calling convention used for Mesa vertex shaders, or AMDPAL last shader
  /// stage before rasterization (vertex shader if tessellation and geometry
  /// are not in use, or otherwise copy shader if one is needed).
  case amdGPUVertexShader
  /// Calling convention used for Mesa/AMDPAL geometry shaders.
  case amdGPUGeometryShader
  /// Calling convention used for Mesa/AMDPAL pixel shaders.
  case amdGPUPixelShader
  /// Calling convention used for Mesa/AMDPAL compute shaders.
  case amdGPUComputeShader
  /// Calling convention for AMDGPU code object kernels.
  case amdGPUKernel
  /// Register calling convention used for parameters transfer optimization
  case x86RegisterCall
  /// Calling convention used for Mesa/AMDPAL hull shaders (= tessellation
  /// control shaders).
  case amdGPUHullShader
  /// Calling convention used for special MSP430 rtlib functions
  /// which have an "optimized" convention using additional registers.
  case msp430Builtin
  /// Calling convention used for AMDPAL vertex shader if tessellation is in
  /// use.
  case amdGPULS
  /// Calling convention used for AMDPAL shader stage before geometry shader
  /// if geometry is in use. So either the domain (= tessellation evaluation)
  /// shader if tessellation is in use, or otherwise the vertex shader.
  case amdGPUES

  internal init(llvm: LLVMCallConv) {
    switch llvm {
    case LLVMCCallConv: self = .c
    case LLVMFastCallConv: self = .fast
    case LLVMColdCallConv: self = .cold
    case LLVMGHCCallConv: self = .ghc
    case LLVMHiPECallConv: self = .hiPE
    case LLVMWebKitJSCallConv: self = .webKitJS
    case LLVMAnyRegCallConv: self = .anyReg
    case LLVMPreserveMostCallConv: self = .preserveMost
    case LLVMPreserveAllCallConv: self = .preserveAll
    case LLVMSwiftCallConv: self = .swift
    case LLVMCXXFASTTLSCallConv: self = .cxxFastThreadLocalStorage
    case LLVMX86StdcallCallConv: self = .x86StandardCall
    case LLVMX86FastcallCallConv: self = .x86FastCall
    case LLVMARMAPCSCallConv: self = .armAPCS
    case LLVMARMAAPCSCallConv: self = .armAAPCS
    case LLVMARMAAPCSVFPCallConv: self = .armAAPCSVFP
    case LLVMMSP430INTRCallConv: self = .msp430Interrupt
    case LLVMX86ThisCallCallConv: self = .x86ThisCall
    case LLVMPTXKernelCallConv: self = .ptxKernelFunction
    case LLVMPTXDeviceCallConv: self = .ptxDeviceFunction
    case LLVMSPIRFUNCCallConv: self = .spirDeviceFunction
    case LLVMSPIRKERNELCallConv: self = .spirKernelFunction
    case LLVMIntelOCLBICallConv: self = .intelOpenCLBuiltin
    case LLVMX8664SysVCallConv: self = .x8664SystemV
    case LLVMWin64CallConv: self = .win64
    case LLVMX86VectorCallCallConv: self = .x86VectorCall
    case LLVMHHVMCallConv: self = .hhvm
    case LLVMHHVMCCallConv: self = .hhvmc
    case LLVMX86INTRCallConv: self = .x86Interrupt
    case LLVMAVRINTRCallConv: self = .avrInterrupt
    case LLVMAVRSIGNALCallConv: self = .avrSignal
    case LLVMAVRBUILTINCallConv: self = .avrBuiltin
    case LLVMAMDGPUVSCallConv: self = .amdGPUVertexShader
    case LLVMAMDGPUGSCallConv: self = .amdGPUGeometryShader
    case LLVMAMDGPUPSCallConv: self = .amdGPUPixelShader
    case LLVMAMDGPUCSCallConv: self = .amdGPUComputeShader
    case LLVMAMDGPUKERNELCallConv: self = .amdGPUKernel
    case LLVMX86RegCallCallConv: self = .x86RegisterCall
    case LLVMAMDGPUHSCallConv: self = .amdGPUHullShader
    case LLVMMSP430BUILTINCallConv: self = .msp430Builtin
    case LLVMAMDGPULSCallConv: self = .amdGPULS
    case LLVMAMDGPUESCallConv: self = .amdGPUES
    default: fatalError("unknown calling convention \(llvm)")
    }
  }

  private static let conventionMapping: [CallingConvention: LLVMCallConv] = [
    .c : LLVMCCallConv, .fast : LLVMFastCallConv, .cold : LLVMColdCallConv,
    .ghc : LLVMGHCCallConv, .hiPE : LLVMHiPECallConv,
    .webKitJS : LLVMWebKitJSCallConv, .anyReg : LLVMAnyRegCallConv,
    .preserveMost : LLVMPreserveMostCallConv,
    .preserveAll : LLVMPreserveAllCallConv, .swift : LLVMSwiftCallConv,
    .cxxFastThreadLocalStorage : LLVMCXXFASTTLSCallConv,
    .x86StandardCall : LLVMX86StdcallCallConv,
    .x86FastCall : LLVMX86FastcallCallConv, .armAPCS : LLVMARMAPCSCallConv,
    .armAAPCS : LLVMARMAAPCSCallConv, .armAAPCSVFP : LLVMARMAAPCSVFPCallConv,
    .msp430Interrupt : LLVMMSP430INTRCallConv,
    .x86ThisCall : LLVMX86ThisCallCallConv, .ptxKernelFunction : LLVMPTXKernelCallConv,
    .ptxDeviceFunction : LLVMPTXDeviceCallConv, .spirDeviceFunction : LLVMSPIRFUNCCallConv,
    .spirKernelFunction : LLVMSPIRKERNELCallConv, .intelOpenCLBuiltin : LLVMIntelOCLBICallConv,
    .x8664SystemV : LLVMX8664SysVCallConv, .win64 : LLVMWin64CallConv,
    .x86VectorCall : LLVMX86VectorCallCallConv, .hhvm : LLVMHHVMCallConv,
    .hhvmc : LLVMHHVMCCallConv, .x86Interrupt : LLVMX86INTRCallConv,
    .avrInterrupt : LLVMAVRINTRCallConv, .avrSignal : LLVMAVRSIGNALCallConv,
    .avrBuiltin : LLVMAVRBUILTINCallConv,
    .amdGPUVertexShader : LLVMAMDGPUVSCallConv,
    .amdGPUGeometryShader : LLVMAMDGPUGSCallConv,
    .amdGPUPixelShader : LLVMAMDGPUPSCallConv,
    .amdGPUComputeShader : LLVMAMDGPUCSCallConv,
    .amdGPUKernel : LLVMAMDGPUKERNELCallConv,
    .x86RegisterCall : LLVMX86RegCallCallConv,
    .amdGPUHullShader : LLVMAMDGPUHSCallConv,
    .msp430Builtin : LLVMMSP430BUILTINCallConv,
    .amdGPULS : LLVMAMDGPULSCallConv, .amdGPUES : LLVMAMDGPUESCallConv,
  ]

  /// Retrieves the corresponding `LLVMCallConv`.
  public var llvm: LLVMCallConv {
    return CallingConvention.conventionMapping[self]!
  }
}
