//
//  Triple.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// A `Triple` provides an abstraction over "Target Triples".
///
/// A Target Triple encodes information about the target of a
/// compilation session including the underlying processor architecture, OS,
/// platform vendor, and additional information about the runtime environment.
///
/// A target triple is usually specified at the command line as a `-` delimited
/// string in the format:
///
///     <arch><sub>-<vendor>-<sys>-<abi>
///
/// For example:
///
///     nvptx64-nvidia-cuda
///     x86_64-unknown-linux-gnu
///     x86_64-apple-ios8.3-simulator
///
/// For this reason, `Triple` provides an initializer that parses strings in
/// this format.
public struct Triple: Equatable {
  /// The raw target triple string.
  public let data: String
  /// The target's architecture.
  public let architecture: Architecture
  /// The target's vendor.
  public let vendor: Vendor
  /// The target's operating system.
  public let os: OS
  /// The target's environment.
  public let environment: Environment
  /// The target's object file format.
  public let objectFormat: ObjectFormat

  /// Returns the default target triple for the host machine.
  public static let `default`: Triple = {
    guard let raw = LLVMGetDefaultTargetTriple() else {
      return Triple("")
    }
    defer { LLVMDisposeMessage(raw) }
    return Triple(String(cString: raw))
  }()

  /// Create a target triple from known components.
  ///
  /// - Parameters:
  ///   - architecture: The target's architecture. If none is specified,
  ///                   an unknown architecture is assumed.
  ///   - vendor: The target's vendor.  If none is specified,
  ///             an unknown vendor is assumed.
  ///   - os: The target's operating system. If none is specified,
  ///         an unknown operating system is assumed.
  ///   - environment: The target's environment.  If none is specified,
  ///                  an unknown environment is assumed.
  ///   - objectFormat: The target's object file format.  If none is specified,
  ///                   an unknown object file format is assumed.
  public init(
    architecture: Architecture = .unknown,
    vendor: Vendor = .unknown,
    os: OS = .unknown,
    environment: Environment = .unknown,
    objectFormat: ObjectFormat = .unknown
  ) {
    self.data = [
      architecture.rawValue,
      vendor.rawValue,
      os.rawValue,
      environment.rawValue
    ].joined(separator: "-")

    self.architecture = architecture
    self.vendor = vendor
    self.os = os
    self.environment = environment
    self.objectFormat = (objectFormat == .unknown)
                      ? ObjectFormat.default(for: architecture, os: os)
                      : objectFormat
  }

  /// Create a target triple by parsing a string in the standard LLVM
  /// triple format.
  ///
  /// The expected format of a target triple string is as follows:
  ///
  ///     <arch><sub>-<vendor>-<sys>-<abi>
  ///
  /// - Parameter str: The target triple format string to parse.
  public init(_ str: String) {
    var parch: Architecture = .unknown
    var pvendor: Vendor = .unknown
    var pos: OS = .unknown
    var penvironment: Environment = .unknown
    var pobjectFormat: ObjectFormat = .unknown

    let components = str.split(separator: "-", maxSplits: 3, omittingEmptySubsequences: false)
    if components.count > 0 {
      parch = Architecture(parse: components[0])
      if components.count > 1 {
        pvendor = Vendor(parse: components[1])
        if components.count > 2 {
          pos = OS(parse: components[2])
          if components.count > 3 {
            penvironment = Environment(parse: components[3])
            pobjectFormat = ObjectFormat(parse: components[3])
          }
        }
      } else {
        switch components[0] {
        case let x where x.starts(with: "mipsn32"):
          penvironment = .gnuABIN32
        case let x where x.starts(with: "mips64"):
          penvironment = .gnuABI64
        case let x where x.starts(with: "mipsisa64"):
          penvironment = .gnuABI64
        case let x where x.starts(with: "mipsisa32"):
          penvironment = .gnu
        case "mips", "mipsel", "mipsr6", "mipsr6el":
          penvironment = .gnu
        default:
          penvironment = .unknown
        }
        pvendor = .unknown
      }
    } else {
      parch = .unknown
    }

    if pobjectFormat == .unknown {
      pobjectFormat = ObjectFormat.default(for: parch, os: pos)
    }

    self.data = str
    self.architecture = parch
    self.vendor = pvendor
    self.os = pos
    self.environment = penvironment
    self.objectFormat = pobjectFormat
  }

  /// Create a target triple from string components.
  ///
  /// The environment is assumed to be unknown and the object file format is
  /// determined from a combination of the given target architecture and
  /// operating system.
  ///
  /// - Parameters:
  ///   - arch: The target's architecture.
  ///   - vendor: The target's vendor
  ///   - os: The target's operating system.
  public init(arch: String, vendor: String, os: String) {
    self.data = [arch, vendor, os].joined(separator: "-")
    self.architecture = Architecture(parse: Substring(arch))
    self.vendor = Vendor(parse: Substring(vendor))
    self.os = OS(parse: Substring(os))
    self.environment = .unknown
    self.objectFormat = ObjectFormat.default(for: self.architecture, os: self.os)
  }

  /// Create a target triple from string components.
  ///
  /// - Parameters:
  ///   - arch: The target's architecture.
  ///   - vendor: The target's vendor
  ///   - os: The target's operating system.
  ///   - environment: The target's environment.
  public init(arch: String, vendor: String, os: String, environment: String) {
    self.data = [arch, vendor, os, environment].joined(separator: "-")
    self.architecture = Architecture(parse: Substring(arch))
    self.vendor = Vendor(parse: Substring(vendor))
    self.os = OS(parse: Substring(os))
    self.environment = Environment(parse: Substring(environment))
    self.objectFormat = ObjectFormat(parse: Substring(environment))
  }

  public static func == (lhs: Triple, rhs: Triple) -> Bool {
    return lhs.data == rhs.data
      && lhs.architecture == rhs.architecture
      && lhs.vendor == rhs.vendor
      && lhs.os == rhs.os
      && lhs.environment == rhs.environment
      && lhs.objectFormat == rhs.objectFormat
  }

  /// Normalizes a target triple format string.
  ///
  /// The normalization process converts an arbitrary machine specification
  /// into the canonical triple form.  In particular, it handles the
  /// common case in which otherwise valid components are in the wrong order.
  ///
  /// Examples:
  ///
  ///     Triple.normalize("---") == "unknown-unknown-unknown-unknown"
  ///     Triple.normalize("-pc-i386") == "i386-pc-unknown"
  ///     Triple.normalize("a-b-c-i386") == "i386-a-b-c"
  ///
  /// - Parameter string: The target triple format string.
  /// - Returns: A normalized target triple string.
  public static func normalize(_ string: String) -> String {
    guard let data = LLVMNormalizeTargetTriple(string) else {
      return ""
    }
    defer { LLVMDisposeMessage(data) }
    return String(cString: data)
  }

  /// Returns the architecture component of the triple, if it exists.
  ///
  /// If the environment component does not exist, the empty string is returned.
  public var architectureName: Substring {
    let split = self.data.split(separator: "-", maxSplits: 3, omittingEmptySubsequences: false)
    guard split.count > 0 else {
      return ""
    }
    return split[0]
  }

  /// Returns the vendor component of the triple, if it exists.
  ///
  /// If the environment component does not exist, the empty string is returned.
  public var vendorName: Substring {
    let split = self.data.split(separator: "-", maxSplits: 3, omittingEmptySubsequences: false)
    guard split.count > 1 else {
      return ""
    }
    return split[1]
  }

  /// Returns the operating system component of the triple, if it exists.
  ///
  /// If the environment component does not exist, the empty string is returned.
  public var osName: Substring {
    let split = self.data.split(separator: "-", maxSplits: 3, omittingEmptySubsequences: false)
    guard split.count > 2 else {
      return ""
    }
    return split[2]
  }

  /// Returns the environment component of the triple, if it exists.
  ///
  /// If the environment component does not exist, the empty string is returned.
  public var environmentName: Substring {
    let split = self.data.split(separator: "-", maxSplits: 3, omittingEmptySubsequences: false)
    guard split.count > 3 else {
      return ""
    }
    return split[3]
  }
}

extension Triple {
  /// Returns whether this environment is a simulator.
  public var isSimulatorEnvironment: Bool {
    return self.environment == .simulator
  }

  /// Returns whether this environment is a Windows OS in an MSVC environment.
  public var isKnownWindowsMSVCEnvironment: Bool {
    return self.os.isWindows && self.environment == .msvc
  }

  /// Checks if the environment could be MSVC.
  public var isWindowsMSVCEnvironment: Bool {
    return self.isKnownWindowsMSVCEnvironment ||
      (self.os.isWindows && self.environment == .unknown)
  }

  /// Returns whether this environment is a Windows OS in a CoreCLR environment.
  public var isWindowsCoreCLREnvironment: Bool {
    return self.os.isWindows && self.environment == .coreCLR
  }

  /// Returns whether this environment is a Windows OS in an
  /// Itanium environment.
  public var isWindowsItaniumEnvironment: Bool {
    return self.os.isWindows && self.environment == .itanium
  }

  /// Returns whether this environment is a Windows OS in a Cygnus environment.
  public var isWindowsCygwinEnvironment: Bool {
    return self.os.isWindows && self.environment == .cygnus
  }

  /// Returns whether this environment is a Windows OS in a GNU environment.
  public var isWindowsGNUEnvironment: Bool {
    return self.os.isWindows && self.environment == .gnu
  }

  /// Returns whether the OS uses glibc.
  public var isOSGlibc: Bool {
    return (self.os == .linux || self.os == .kFreeBSD ||
      self.os == .hurd) &&
      !self.isAndroid
  }

  /// Tests for either Cygwin or MinGW OS
  public var isOSCygMing: Bool {
    return self.isWindowsCygwinEnvironment || self.isWindowsGNUEnvironment
  }

  /// Is this a "Windows" OS targeting a "MSVCRT.dll" environment.
  public var isOSMSVCRT: Bool {
    return self.isWindowsMSVCEnvironment || self.isWindowsGNUEnvironment ||
      self.isWindowsItaniumEnvironment
  }

  /// Returns whether the OS uses the ELF binary format.
  public var isOSBinFormatELF: Bool {
    return self.objectFormat == .elf
  }

  /// Returns whether the OS uses the COFF binary format.
  public var isOSBinFormatCOFF: Bool {
    return self.objectFormat == .coff
  }

  /// Returns whether the environment is MachO.
  public var isOSBinFormatMachO: Bool {
    return self.objectFormat == .machO
  }

  /// Returns whether the OS uses the Wasm binary format.
  public var isOSBinFormatWasm: Bool {
    return self.objectFormat == .wasm
  }

  /// Returns whether the OS uses the XCOFF binary format.
  public var isOSBinFormatXCOFF: Bool {
    return self.objectFormat == .xcoff
  }

  /// Returns whether the target is the PS4 CPU
  public var isPS4CPU: Bool {
    return self.architecture == .x86_64 &&
      self.vendor == .scei &&
      self.os == .ps4
  }

  /// Returns whether the target is the PS4 platform
  public var isPS4: Bool {
    return self.vendor == .scei &&
      self.os == .ps4
  }

  /// Returns whether the target is Android
  public var isAndroid: Bool {
    return self.environment == .android
  }

  /// Returns whether the environment is musl-libc
  public var isMusl: Bool {
    return self.environment == .musl ||
      self.environment == .muslEABI ||
      self.environment == .muslEABIHF
  }

  /// Returns whether the target is NVPTX (32- or 64-bit).
  public var isNVPTX: Bool {
    return self.architecture == .nvptx || self.architecture == .nvptx64
  }

  /// Returns whether the target is Thumb (little and big endian).
  public var isThumb: Bool {
    return self.architecture == .thumb || self.architecture == .thumbeb
  }

  /// Returns whether the target is ARM (little and big endian).
  public var isARM: Bool {
    return self.architecture == .arm || self.architecture == .armeb
  }

  /// Returns whether the target is AArch64 (little and big endian).
  public var isAArch64: Bool {
    return self.architecture == .aarch64 || self.architecture == .aarch64_be
  }

  /// Returns whether the target is MIPS 32-bit (little and big endian).
  public var isMIPS32: Bool {
    return self.architecture == .mips || self.architecture == .mipsel
  }

  /// Returns whether the target is MIPS 64-bit (little and big endian).
  public var isMIPS64: Bool {
    return self.architecture == .mips64 || self.architecture == .mips64el
  }

  /// Returns whether the target is MIPS (little and big endian, 32- or 64-bit).
  public var isMIPS: Bool {
    return self.isMIPS32 || self.isMIPS64
  }

  /// Returns whether the target supports comdat
  public var supportsCOMDAT: Bool {
    return !self.isOSBinFormatMachO
  }

  /// Returns whether the target uses emulated TLS as default.
  public var hasDefaultEmulatedTLS: Bool {
    return self.isAndroid || self.os.isOpenBSD || self.isWindowsCygwinEnvironment
  }
}

// MARK: Triple Data

extension Triple {
  /// Represents an architecture known to LLVM.
  public enum Architecture: String, CaseIterable {
    /// An unknown architecture or hardware platform.
    case unknown = "unknown"

    ///  ARM (little endian): arm, armv.*, xscale
    case arm = "arm"
    ///  ARM (big endian): armeb
    case armeb = "armeb"
    ///  AArch64 (little endian): aarch64
    case aarch64 = "aarch64"
    ///  AArch64 (big endian): aarch64_be
    case aarch64_be = "aarch64_be"
    ///  ARC: Synopsys ARC
    case arc = "arc"
    ///  AVR: Atmel AVR microcontroller
    case avr = "avr"
    ///  eBPF or extended BPF or 64-bit BPF (little endian)
    case bpfel = "bpfel"
    ///  eBPF or extended BPF or 64-bit BPF (big endian)
    case bpfeb = "bpfeb"
    ///  Hexagon: hexagon
    case hexagon = "hexagon"
    ///  MIPS: mips, mipsallegrex, mipsr6
    case mips = "mips"
    ///  MIPSEL: mipsel, mipsallegrexe, mipsr6el
    case mipsel = "mipsel"
    ///  MIPS64: mips64, mips64r6, mipsn32, mipsn32r6
    case mips64 = "mips64"
    ///  MIPS64EL: mips64el, mips64r6el, mipsn32el, mipsn32r6el
    case mips64el = "mips64el"
    ///  MSP430: msp430
    case msp430 = "msp430"
    ///  PPC: powerpc
    case ppc = "ppc"
    ///  PPC64: powerpc64, ppu
    case ppc64 = "ppc64"
    ///  PPC64LE: powerpc64le
    case ppc64le = "ppc64le"
    ///  R600: AMD GPUs HD2XXX - HD6XXX
    case r600 = "r600"
    ///  AMDGCN: AMD GCN GPUs
    case amdgcn = "amdgcn"
    ///  RISC-V (32-bit): riscv32
    case riscv32 = "riscv32"
    ///  RISC-V (64-bit): riscv64
    case riscv64 = "riscv64"
    ///  Sparc: sparc
    case sparc = "sparc"
    ///  Sparcv9: Sparcv9
    case sparcv9 = "sparcv9"
    ///  Sparc: (endianness = little). NB: 'Sparcle' is a CPU variant
    case sparcel = "sparcel"
    ///  SystemZ: s390x
    case systemz = "systemz"
    ///  TCE (http://tce.cs.tut.fi/): tce
    case tce = "tce"
    ///  TCE little endian (http://tce.cs.tut.fi/): tcele
    case tcele = "tcele"
    ///  Thumb (little endian): thumb, thumbv.*
    case thumb = "thumb"
    ///  Thumb (big endian): thumbeb
    case thumbeb = "thumbeb"
    ///  X86: i[3-9]86
    case x86 = "x86"
    ///  X86-64: amd64, x86_64
    case x86_64 = "x86_64"
    ///  XCore: xcore
    case xcore = "xcore"
    ///  NVPTX: 32-bit
    case nvptx = "nvptx"
    ///  NVPTX: 64-bit
    case nvptx64 = "nvptx64"
    ///  le32: generic little-endian 32-bit CPU (PNaCl)
    case le32 = "le32"
    ///  le64: generic little-endian 64-bit CPU (PNaCl)
    case le64 = "le64"
    ///  AMDIL
    case amdil = "amdil"
    ///  AMDIL with 64-bit pointers
    case amdil64 = "amdil64"
    ///  AMD HSAIL
    case hsail = "hsail"
    ///  AMD HSAIL with 64-bit pointers
    case hsail64 = "hsail64"
    ///  SPIR: standard portable IR for OpenCL 32-bit version
    case spir = "spir"
    ///  SPIR: standard portable IR for OpenCL 64-bit version
    case spir64 = "spir64"
    ///  Kalimba: generic kalimba
    case kalimba = "kalimba"
    ///  SHAVE: Movidius vector VLIW processors
    case shave = "shave"
    ///  Lanai: Lanai 32-bit
    case lanai = "lanai"
    ///  WebAssembly with 32-bit pointers
    case wasm32 = "wasm32"
    ///  WebAssembly with 64-bit pointers
    case wasm64 = "wasm64"
    ///  32-bit RenderScript
    case renderscript32 = "renderscript32"
    ///  64-bit RenderScript
    case renderscript64 = "renderscript64"

    fileprivate init(parse archName: Substring) {
      func parseBPFArch(_ ArchName: Substring) -> Architecture {
        if ArchName == "bpf" {
          #if _endian(little)
            return .bpfel
          #elseif _endian(big)
            return .bpfeb
          #else
            #error("Unknown endianness?")
          #endif
        } else if ArchName == "bpf_be" || ArchName == "bpfeb" {
          return .bpfeb
        } else if ArchName == "bpf_le" || ArchName == "bpfel" {
          return .bpfel
        } else {
          return .unknown
        }
      }

      func parseARMArch(_ ArchName: Substring) -> Architecture {
        enum ARMISA {
          case invalid
          case arm
          case thumb
          case aarch64
        }
        func parseISA(_ Arch: Substring) -> ARMISA {
          switch Arch {
          case let x where x.starts(with: "aarch64"):
            return .aarch64
          case let x where x.starts(with: "arm64"):
            return .aarch64
          case let x where x.starts(with: "thumb"):
            return .thumb
          case let x where x.starts(with: "arm"):
            return .arm
          default:
            return .invalid
          }
        }

        enum EndianKind {
          case invalid
          case little
          case big
        }

        func parseArchEndian(_ Arch: Substring) -> EndianKind {
          if (Arch.starts(with: "armeb") || Arch.starts(with: "thumbeb") ||
            Arch.starts(with: "aarch64_be")) {
            return .big
          }

          if Arch.starts(with: "arm") || Arch.starts(with: "thumb") {
            if Arch.hasSuffix("eb") {
              return .big
            } else {
              return .little
            }
          }

          if Arch.starts(with: "aarch64") {
            return .little
          }

          return .invalid
        }

        let isa = parseISA(archName)
        let endian = parseArchEndian(archName)

        var arch = Architecture.unknown
        switch endian {
        case .little:
          switch isa {
          case .arm:
            arch = .arm
          case .thumb:
            arch = .thumb
          case .aarch64:
            arch = .aarch64
          case .invalid:
            break
          }
        case .big:
          switch isa {
          case .arm:
            arch = .armeb
          case .thumb:
            arch = .thumbeb
          case .aarch64:
            arch = .aarch64_be
          case .invalid:
            break
          }
        case .invalid:
          break
        }

        let ownedStr = String(archName)
        guard let rawArch = LLVMGetARMCanonicalArchName(ownedStr, ownedStr.count) else {
          fatalError()
        }
        let archName = String(cString: rawArch)
        guard !archName.isEmpty else {
          return .unknown
        }
        // Thumb only exists in v4+
        if isa == .thumb && (ArchName.starts(with: "v2") || ArchName.starts(with: "v3")) {
          return .unknown
        }

        // Thumb only for v6m
        let Profile = LLVMARMParseArchProfile(archName, archName.count)
        let Version = LLVMARMParseArchVersion(archName, archName.count)
        if Profile == LLVMARMProfileKindM && Version == 6 {
          if endian == .big {
            return .thumbeb
          } else {
            return .thumb
          }
        }

        return arch
      }

      switch archName {
      case "i386", "i486", "i586", "i686":
        self = .x86
      // FIXME: Do we need to support these?
      case "i786", "i886", "i986":
        self = .x86
      case "amd64", "x86_64", "x86_64h":
        self = .x86_64
      case "powerpc", "ppc", "ppc32":
        self = .ppc
      case "powerpc64", "ppu", "ppc64":
        self = .ppc64
      case "powerpc64le", "ppc64le":
        self = .ppc64le
      case "xscale":
        self = .arm
      case "xscaleeb":
        self = .armeb
      case "aarch64":
        self = .aarch64
      case "aarch64_be":
        self = .aarch64_be
      case "arc":
        self = .arc
      case "arm64":
        self = .aarch64
      case "arm":
        self = .arm
      case "armeb":
        self = .armeb
      case "thumb":
        self = .thumb
      case "thumbeb":
        self = .thumbeb
      case "avr":
        self = .avr
      case "msp430":
        self = .msp430
      case "mips", "mipseb", "mipsallegrex", "mipsisa32r6", "mipsr6":
        self = .mips
      case "mipsel", "mipsallegrexel", "mipsisa32r6el", "mipsr6el":
        self = .mipsel
      case "mips64", "mips64eb", "mipsn32", "mipsisa64r6", "mips64r6", "mipsn32r6":
        self = .mips64
      case "mips64el", "mipsn32el", "mipsisa64r6el", "mips64r6el", "mipsn32r6el":
        self = .mips64el
      case "r600":
        self = .r600
      case "amdgcn":
        self = .amdgcn
      case "riscv32":
        self = .riscv32
      case "riscv64":
        self = .riscv64
      case "hexagon":
        self = .hexagon
      case "s390x", "systemz":
        self = .systemz
      case "sparc":
        self = .sparc
      case "sparcel":
        self = .sparcel
      case "sparcv9", "sparc64":
        self = .sparcv9
      case "tce":
        self = .tce
      case "tcele":
        self = .tcele
      case "xcore":
        self = .xcore
      case "nvptx":
        self = .nvptx
      case "nvptx64":
        self = .nvptx64
      case "le32":
        self = .le32
      case "le64":
        self = .le64
      case "amdil":
        self = .amdil
      case "amdil64":
        self = .amdil64
      case "hsail":
        self = .hsail
      case "hsail64":
        self = .hsail64
      case "spir":
        self = .spir
      case "spir64":
        self = .spir64
      case let x where x.starts(with: "kalimba"):
        self = .kalimba
      case "lanai":
        self = .lanai
      case "shave":
        self = .shave
      case "wasm32":
        self = .wasm32
      case "wasm64":
        self = .wasm64
      case "renderscript32":
        self = .renderscript32
      case "renderscript64":
        self = .renderscript64
      default:
        if archName.starts(with: "arm") || archName.starts(with: "thumb") || archName.starts(with: "aarch64") {
          self = parseARMArch(archName)
        } else if archName.starts(with: "bpf") {
          self = parseBPFArch(archName)
        } else {
          self = .unknown
        }
      }
    }

    /// Returns the prefix for a family of related architectures.
    public var prefix: String {
      switch self {
      case .aarch64, .aarch64_be:
        return "aarch64"
      case .arc:
        return "arc"
      case .arm, .armeb, .thumb, .thumbeb:
        return "arm"
      case .avr:
        return "avr"
      case .ppc64, .ppc64le, .ppc:
        return "ppc"
      case .mips, .mipsel, .mips64, .mips64el:
        return "mips"
      case .hexagon:
        return "hexagon"
      case .amdgcn:
        return "amdgcn"    case .r600:
          return "r600"
      case .bpfel, .bpfeb:
        return "bpf"
      case .sparcv9, .sparcel, .sparc:
        return "sparc"
      case .systemz:
        return "s390"
      case .x86, .x86_64:
        return "x86"
      case .xcore:
        return "xcore"
      // NVPTX intrinsics are namespaced under nvvm.
      case .nvptx, .nvptx64:
        return "nvvm"
      case .le32:
        return "le32"
      case .le64:
        return "le64"
      case .amdil, .amdil64:
        return "amdil"
      case .hsail, .hsail64:
        return "hsail"
      case .spir, .spir64:
        return "spir"    case .kalimba:
          return "kalimba"
      case .lanai:
        return "lanai"
      case .shave:
        return "shave"
      case .wasm32, .wasm64:
        return "wasm"
      case .riscv32, .riscv64:
        return "riscv"
      default:
        return ""
      }
    }

    /// Returns the width in bits for a pointer on this architecture.
    public var pointerBitWidth: Int {
      switch self {
      case .unknown:
        return 0

      case .avr, .msp430:
        return 16

      case .arc: fallthrough
      case .arm: fallthrough
      case .armeb: fallthrough
      case .hexagon: fallthrough
      case .le32: fallthrough
      case .mips: fallthrough
      case .mipsel: fallthrough
      case .nvptx: fallthrough
      case .ppc: fallthrough
      case .r600: fallthrough
      case .riscv32: fallthrough
      case .sparc: fallthrough
      case .sparcel: fallthrough
      case .tce: fallthrough
      case .tcele: fallthrough
      case .thumb: fallthrough
      case .thumbeb: fallthrough
      case .x86: fallthrough
      case .xcore: fallthrough
      case .amdil: fallthrough
      case .hsail: fallthrough
      case .spir: fallthrough
      case .kalimba: fallthrough
      case .lanai: fallthrough
      case .shave: fallthrough
      case .wasm32: fallthrough
      case .renderscript32:
        return 32

      case .aarch64: fallthrough
      case .aarch64_be: fallthrough
      case .amdgcn: fallthrough
      case .bpfel: fallthrough
      case .bpfeb: fallthrough
      case .le64: fallthrough
      case .mips64: fallthrough
      case .mips64el: fallthrough
      case .nvptx64: fallthrough
      case .ppc64: fallthrough
      case .ppc64le: fallthrough
      case .riscv64: fallthrough
      case .sparcv9: fallthrough
      case .systemz: fallthrough
      case .x86_64: fallthrough
      case .amdil64: fallthrough
      case .hsail64: fallthrough
      case .spir64: fallthrough
      case .wasm64: fallthrough
      case .renderscript64:
        return 64
      }
    }
  }

  /// Represents a vendor known to LLVM.
  public enum Vendor: String, CaseIterable {
    /// An unknown vendor.
    case unknown = "unknown"

    /// Apple
    case apple = "Apple"
    /// PC
    case pc = "PC"
    /// SCEI
    case scei = "SCEI"
    /// BGP
    case bgp = "BGP"
    /// BGQ
    case bgq = "BGQ"
    /// Freescale
    case freescale = "Freescale"
    /// IBM
    case ibm = "IBM"
    /// ImaginationTechnologies
    case imaginationTechnologies = "ImaginationTechnologies"
    /// MipsTechnologies
    case mipsTechnologies = "MipsTechnologies"
    /// NVIDIA
    case nvidia = "NVIDIA"
    /// CSR
    case csr = "CSR"
    /// Myriad
    case myriad = "Myriad"
    /// AMD
    case amd = "AMD"
    /// Mesa
    case mesa = "Mesa"
    /// SUSE
    case suse = "SUSE"
    /// OpenEmbedded
    case openEmbedded = "OpenEmbedded"

    fileprivate init(parse VendorName: Substring) {
      switch VendorName {
      case "apple":
        self = .apple
      case "pc":
        self = .pc
      case "scei":
        self = .scei
      case "bgp":
        self = .bgp
      case "bgq":
        self = .bgq
      case "fsl":
        self = .freescale
      case "ibm":
        self = .ibm
      case "img":
        self = .imaginationTechnologies
      case "mti":
        self = .mipsTechnologies
      case "nvidia":
        self = .nvidia
      case "csr":
        self = .csr
      case "myriad":
        self = .myriad
      case "amd":
        self = .amd
      case "mesa":
        self = .mesa
      case "suse":
        self = .suse
      case "oe":
        self = .openEmbedded
      default:
        self = .unknown
      }
    }
  }

  /// Represents an operating system known to LLVM.
  public enum OS: String, CaseIterable {
    /// An unknown operating system.
    case unknown = "UnknownOS"

    /// The Ananas operating system.
    case ananas = "Ananas"
    /// The CloudABI operating system.
    case cloudABI = "CloudABI"
    /// The Darwin operating system.
    case darwin = "Darwin"
    /// The DragonFly operating system.
    case dragonFly = "DragonFly"
    /// The FreeBSD operating system.
    case freeBSD = "FreeBSD"
    /// The Fuchsia operating system.
    case fuchsia = "Fuchsia"
    /// The iOS operating system.
    case iOS = "IOS"
    /// The GNU/kFreeBSD operating system.
    case kFreeBSD = "KFreeBSD"
    /// The Linux operating system.
    case linux = "Linux"
    /// Sony's PS3 operating system.
    case lv2 = "Lv2"
    /// The macOS operating system.
    case macOS = "MacOSX"
    /// The NetBSD operating system.
    case netBSD = "NetBSD"
    /// The OpenBSD operating system.
    case openBSD = "OpenBSD"
    /// The Solaris operating system.
    case solaris = "Solaris"
    /// The Win32 operating system.
    case win32 = "Win32"
    /// The Haiku operating system.
    case haiku = "Haiku"
    /// The Minix operating system.
    case minix = "Minix"
    /// The RTEMS operating system.
    case rtems = "RTEMS"
    ///  Native Client
    case naCl = "NaCl"
    ///  BG/P Compute-Node Kernel
    case cnk = "CNK"
    /// The AIX operating system.
    case aix = "AIX"
    ///  NVIDIA CUDA
    case cuda = "CUDA"
    ///  NVIDIA OpenCL
    case nvcl = "NVCL"
    ///  AMD HSA Runtime
    case amdHSA = "AMDHSA"
    /// Sony's PS4 operating system.
    case ps4 = "PS4"
    /// The Intel MCU operating system.
    case elfIAMCU = "ELFIAMCU"
    ///  Apple tvOS.
    case tvOS = "TvOS"
    ///  Apple watchOS.
    case watchOS = "WatchOS"
    /// The Mesa 3D compute kernel.
    case mesa3D = "Mesa3D"
    /// The Contiki operating system.
    case contiki = "Contiki"
    /// AMD PAL Runtime.
    case amdPAL = "AMDPAL"
    ///  HermitCore Unikernel/Multikernel.
    case hermitCore = "HermitCore"
    /// GNU/Hurd.
    case hurd = "Hurd"
    /// Experimental WebAssembly OS
    case wasi = "WASI"

    fileprivate init(parse OSName: Substring) {
      switch OSName {
      case let x where x.starts(with: "ananas"):
        self = .ananas
      case let x where x.starts(with: "cloudabi"):
        self = .cloudABI
      case let x where x.starts(with: "darwin"):
        self = .darwin
      case let x where x.starts(with: "dragonfly"):
        self = .dragonFly
      case let x where x.starts(with: "freebsd"):
        self = .freeBSD
      case let x where x.starts(with: "fuchsia"):
        self = .fuchsia
      case let x where x.starts(with: "ios"):
        self = .tvOS
      case let x where x.starts(with: "kfreebsd"):
        self = .kFreeBSD
      case let x where x.starts(with: "linux"):
        self = .linux
      case let x where x.starts(with: "lv2"):
        self = .lv2
      case let x where x.starts(with: "macos"):
        self = .macOS
      case let x where x.starts(with: "netbsd"):
        self = .netBSD
      case let x where x.starts(with: "openbsd"):
        self = .openBSD
      case let x where x.starts(with: "solaris"):
        self = .solaris
      case let x where x.starts(with: "win32"):
        self = .win32
      case let x where x.starts(with: "windows"):
        self = .win32
      case let x where x.starts(with: "haiku"):
        self = .haiku
      case let x where x.starts(with: "minix"):
        self = .minix
      case let x where x.starts(with: "rtems"):
        self = .rtems
      case let x where x.starts(with: "nacl"):
        self = .naCl
      case let x where x.starts(with: "cnk"):
        self = .cnk
      case let x where x.starts(with: "aix"):
        self = .aix
      case let x where x.starts(with: "cuda"):
        self = .cuda
      case let x where x.starts(with: "nvcl"):
        self = .nvcl
      case let x where x.starts(with: "amdhsa"):
        self = .amdHSA
      case let x where x.starts(with: "ps4"):
        self = .ps4
      case let x where x.starts(with: "elfiamcu"):
        self = .elfIAMCU
      case let x where x.starts(with: "tvos"):
        self = .tvOS
      case let x where x.starts(with: "watchos"):
        self = .watchOS
      case let x where x.starts(with: "mesa3d"):
        self = .mesa3D
      case let x where x.starts(with: "contiki"):
        self = .contiki
      case let x where x.starts(with: "amdpal"):
        self = .amdPAL
      case let x where x.starts(with: "hermit"):
        self = .hermitCore
      case let x where x.starts(with: "hurd"):
        self = .hurd
      case let x where x.starts(with: "wasi"):
        self = .wasi
      default:
        self = .unknown
      }
    }

    /// Returns whether the OS is unknown.
    public var isUnknown: Bool {
      return self == .unknown
    }

    /// Returns whether this a Mac OS X triple.
    ///
    /// For legacy reasons, LLVM supports both "darwin" and "osx" as
    /// macOS triples.
    public var isMacOS: Bool {
      return self == .darwin || self == .macOS
    }

    /// Returns whether this an iOS triple.
    public var isiOS: Bool {
      return self == .iOS || self.isTvOS
    }

    /// Returns whether this an Apple tvOS triple.
    public var isTvOS: Bool {
      return self == .tvOS
    }

    /// Returns whether this an Apple watchOS triple.
    public var isWatchOS: Bool {
      return self == .watchOS
    }

    /// Returns whether this a "Darwin" OS (OS X, iOS, or watchOS).
    public var isDarwin: Bool {
      return self.isMacOS || self.isiOS || self.isWatchOS
    }

    /// Returns whether the OS is NetBSD.
    public var isNetBSD: Bool {
      return self == .netBSD
    }

    /// Returns whether the OS is OpenBSD.
    public var isOpenBSD: Bool {
      return self == .openBSD
    }

    /// Returns whether the OS is FreeBSD.
    public var isFreeBSD: Bool {
      return self == .freeBSD
    }

    /// Returns whether the OS is Fuchsia.
    public var isFuchsia: Bool {
      return self == .fuchsia
    }

    /// Returns whether the OS is DragonFly.
    public var isDragonFly: Bool {
      return self == .dragonFly
    }

    /// Returns whether the OS is Solaris.
    public var isSolaris: Bool {
      return self == .solaris
    }

    /// Returns whether the OS is IAMCU.
    public var isIAMCU: Bool {
      return self == .elfIAMCU
    }

    /// Returns whether the OS is Contiki.
    public var isContiki: Bool {
      return self == .contiki
    }

    /// Returns whether the OS is Haiku.
    public var isHaiku: Bool {
      return self == .haiku
    }

    /// Returns whether the OS is Windows.
    public var isWindows: Bool {
      return self == .win32
    }

    /// Returns whether the OS is NaCl (Native Client)
    public var isNaCl: Bool {
      return self == .naCl
    }

    /// Returns whether the OS is Linux.
    public var isLinux: Bool {
      return self == .linux
    }

    /// Returns whether the OS is kFreeBSD.
    public var isKFreeBSD: Bool {
      return self == .kFreeBSD
    }

    /// Returns whether the OS is Hurd.
    public var isHurd: Bool {
      return self == .hurd
    }

    /// Returns whether the OS is WASI.
    public var isWASI: Bool {
      return self == .wasi
    }

    /// Returns whether the OS is AIX.
    public var isAIX: Bool {
      return self == .aix
    }
  }

  /// Represents a runtime environment known to LLVM.
  public enum Environment: String, CaseIterable {
    /// An unknown environment.
    case unknown = "UnknownEnvironment"

    /// The generic GNU environment.
    case gnu = "GNU"
    /// The GNU environment with 32-bit pointers and integers.
    case gnuABIN32 = "GNUABIN32"
    /// The GNU environment with 64-bit pointers and integers.
    case gnuABI64 = "GNUABI64"
    /// The GNU environment for ARM EABI.
    ///
    /// Differs from `gnuEABIHF` because it uses software floating point.
    case gnuEABI = "GNUEABI"
    /// The GNU environment for ARM EABI.
    ///
    /// Differs from `gnuEABI` because it uses hardware floating point.
    case gnuEABIHF = "GNUEABIHF"
    /// The GNU X32 environment for amd64/x86_64 CPUs using 32-bit integers,
    /// longs and pointers.
    case gnuX32 = "GNUX32"
    /// The _ environment.
    case code16 = "CODE16"
    /// The ARM EABI environment.
    ///
    /// Differs from `eabiHF` because it uses software floating point.
    case eabi = "EABI"
    /// The ARM EABI environment.
    ///
    /// Differs from `eabi` because it uses hardware floating point.
    case eabiHF = "EABIHF"
    /// The Google Android environment.
    case android = "Android"
    /// The musl environment.
    case musl = "Musl"
    /// The musl environment for ARM EABI.
    ///
    /// Differs from `muslEABIHF` because it uses software floating point.
    case muslEABI = "MuslEABI"
    /// The musl environment for ARM EABI.
    ///
    /// Differs from `Differs` because it uses hardware floating point.
    case muslEABIHF = "MuslEABIHF"
    /// The Microsoft Visual C++ environment.
    case msvc = "MSVC"
    /// The Intel Itanium environment.
    case itanium = "Itanium"
    /// The Cygnus environment.
    case cygnus = "Cygnus"
    /// The Microsoft CoreCLR environment for .NET core.
    case coreCLR = "CoreCLR"
    ///  Simulator variants of other systems, e.g., Apple's iOS
    case simulator = "Simulator"

    fileprivate init(parse EnvironmentName: Substring) {
      switch EnvironmentName {
      case let x where x.starts(with: "eabihf"):
        self = .eabiHF
      case let x where x.starts(with: "eabi"):
        self = .eabi
      case let x where x.starts(with: "gnuabin32"):
        self = .gnuABIN32
      case let x where x.starts(with: "gnuabi64"):
        self = .gnuABI64
      case let x where x.starts(with: "gnueabihf"):
        self = .gnuEABIHF
      case let x where x.starts(with: "gnueabi"):
        self = .gnuEABI
      case let x where x.starts(with: "gnux32"):
        self = .gnuX32
      case let x where x.starts(with: "code16"):
        self = .code16
      case let x where x.starts(with: "gnu"):
        self = .gnu
      case let x where x.starts(with: "android"):
        self = .android
      case let x where x.starts(with: "musleabihf"):
        self = .muslEABIHF
      case let x where x.starts(with: "musleabi"):
        self = .muslEABI
      case let x where x.starts(with: "musl"):
        self = .musl
      case let x where x.starts(with: "msvc"):
        self = .msvc
      case let x where x.starts(with: "itanium"):
        self = .itanium
      case let x where x.starts(with: "cygnus"):
        self = .cygnus
      case let x where x.starts(with: "coreclr"):
        self = .coreCLR
      case let x where x.starts(with: "simulator"):
        self = .simulator
      default:
        self = .unknown
      }
    }

    /// Returns whether this environment is a GNU environment.
    public var isGNU: Bool {
      return self == .gnu || self == .gnuABIN32 ||
        self == .gnuABI64 || self == .gnuEABI ||
        self == .gnuEABIHF || self == .gnuX32
    }
  }

  /// Represents an object file format known to LLVM.
  public enum ObjectFormat: String, CaseIterable {
    /// An unknown object file format.
    case unknown = "unknown"

    /// The Common Object File Format.
    case coff = "COFF"
    /// The Executable and Linkable Format.
    case elf = "ELF"
    /// The Mach Object format.
    case machO = "MachO"
    /// The Web Assembly format.
    case wasm = "Wasm"
    /// The eXtended Common Object File Format.
    case xcoff = "XCOFF"

    fileprivate init(parse EnvironmentName: Substring) {
      switch EnvironmentName {
      // "xcoff" must come before "coff" because of the order-dependendent
      // pattern matching.
      case let x where x.hasSuffix("xcoff"):
        self = .xcoff
      case let x where x.hasSuffix("coff"):
        self = .coff
      case let x where x.hasSuffix("elf"):
        self = .elf
      case let x where x.hasSuffix("macho"):
        self = .machO
      case let x where x.hasSuffix("wasm"):
        self = .wasm
      default:
        self = .unknown
      }
    }

    /// Returns the default object file format for the given architecture and
    /// operating system.
    ///
    /// - Parameters:
    ///   - arch: The architecture.
    ///   - os: The operatuing system.
    /// - Returns: A default object file format compatible with the given
    ///   architecture and operating system.
    public static func `default`(for arch: Architecture, os: OS) -> ObjectFormat {
      switch arch {
      case .unknown, .aarch64, .arm, .thumb, .x86, .x86_64:
        if os.isDarwin {
          return .machO
        } else if os.isWindows {
          return .coff
        }
        return .elf

      case .aarch64_be, .arc, .amdgcn, .amdil, .amdil64, .armeb, .avr,
           .bpfeb, .bpfel, .hexagon, .lanai, .hsail, .hsail64, .kalimba,
           .le32, .le64, .mips, .mips64, .mips64el, .mipsel, .msp430,
           .nvptx, .nvptx64, .ppc64le,
           .r600, .renderscript32, .renderscript64, .riscv32, .riscv64,
           .shave, .sparc, .sparcel, .sparcv9, .spir, .spir64, .systemz,
           .tce, .tcele, .thumbeb, .xcore:
        return .elf

      case .ppc, .ppc64:
        if os.isDarwin {
          return .machO
        } else if os.isAIX {
          return .xcoff
        }
        return .elf

      case .wasm32, .wasm64:
        return .wasm
      }
    }
  }
}
