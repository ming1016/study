//
//  MemoryBuffer.swift
//  SwiftLLVMCase
//
//  Created by Ming Dai on 2022/4/20.
//

import llvm

/// Enumerates the possible failures that can be thrown initializing
/// a MemoryBuffer.
public enum MemoryBufferError: Error {
  /// The MemoryBuffer failed to be initialized for a specific reason.
  case couldNotCreate(String)
}

/// `MemoryBuffer` provides simple read-only access to a block of memory, and
/// provides simple methods for reading files and standard input into a memory
/// buffer.  In addition to basic access to the characters in the file, this
/// interface guarantees you can read one character past the end of the file,
/// and that this character will read as '\0'.
///
/// The '\0' guarantee is needed to support an optimization -- it's intended to
/// be more efficient for clients which are reading all the data to stop
/// reading when they encounter a '\0' than to continually check the file
/// position to see if it has reached the end of the file.
public class MemoryBuffer: Sequence {
  let llvm: LLVMMemoryBufferRef
  internal var ownsContext: Bool = true

  /// Creates a `MemoryBuffer` with the contents of `stdin`, stopping once
  /// `EOF` is read.
  /// - throws: `MemoryBufferError` if there was an error on creation.
  public static func fromStdin() throws -> MemoryBuffer {
    var buf: LLVMMemoryBufferRef?
    var error: UnsafeMutablePointer<Int8>?
    LLVMCreateMemoryBufferWithSTDIN(&buf, &error)
    if let error = error {
      defer { LLVMDisposeMessage(error) }
      throw MemoryBufferError.couldNotCreate(String(cString: error))
    }
    guard let llvm = buf else {
      throw MemoryBufferError.couldNotCreate("unknown reason")
    }
    return MemoryBuffer(llvm: llvm)
  }


  /// Creates a MemoryBuffer from the underlying `LLVMMemoryBufferRef`
  ///
  /// - parameter llvm: The LLVMMemoryBufferRef with which to initialize
  internal init(llvm: LLVMMemoryBufferRef) {
    self.llvm = llvm
  }

  /// Creates a `MemoryBuffer` that points to a specified
  /// `UnsafeBufferPointer`.
  ///
  /// - parameters:
  ///   - buffer: The underlying buffer that contains the data.
  ///   - name: The name for the new memory buffer.
  ///   - requiresNullTerminator: Whether or not the `MemoryBuffer` should
  ///                             append a null terminator. Defaults to
  ///                             `false`
  public init(buffer: UnsafeBufferPointer<Int8>,
              name: String,
              requiresNullTerminator: Bool = false) {
    llvm = LLVMCreateMemoryBufferWithMemoryRange(buffer.baseAddress,
                                                 buffer.count,
                                                 name,
                                                 requiresNullTerminator.llvm)
  }

  /// Creates a `MemoryBuffer` by copying the data within a specified
  /// `UnsafeBufferPointer`.
  ///
  /// - parameters:
  ///   - buffer: The underlying buffer that contains the data.
  ///   - name: The name for the new memory buffer.
  public init(copyingBuffer buffer: UnsafeBufferPointer<Int8>,
              name: String) {
    llvm = LLVMCreateMemoryBufferWithMemoryRangeCopy(buffer.baseAddress,
                                                     buffer.count,
                                                     name)
  }


  /// Creates a `MemoryBuffer` with the contents of the file at the provided
  /// path.
  ///
  /// - parameter file: The full path of the file you're trying to read.
  /// - throws: `MemoryBufferError` if there was a problem creating
  ///           the buffer or reading the file.
  public init(contentsOf file: String) throws {
    var buf: LLVMMemoryBufferRef?
    var error: UnsafeMutablePointer<Int8>?
    LLVMCreateMemoryBufferWithContentsOfFile(file, &buf, &error)
    if let error = error {
      defer { LLVMDisposeMessage(error) }
      throw MemoryBufferError.couldNotCreate(String(cString: error))
    }
    guard let llvm = buf else {
      throw MemoryBufferError.couldNotCreate("unknown reason")
    }
    self.llvm = llvm
  }

  /// Retrieves the start address of this buffer.
  public var start: UnsafePointer<Int8> {
    return LLVMGetBufferStart(llvm)
  }

  /// Retrieves the size in bytes of this buffer.
  public var size: Int {
    return LLVMGetBufferSize(llvm)
  }

  /// Makes an iterator so this buffer can be traversed in a `for` loop.
  public func makeIterator() -> UnsafeBufferPointer<Int8>.Iterator {
    return UnsafeBufferPointer(start: start, count: size).makeIterator()
  }

  /// Deinitialize this value and dispose of its resources.
  deinit {
    guard self.ownsContext else {
      return
    }
    LLVMDisposeMemoryBuffer(llvm)
  }
}
