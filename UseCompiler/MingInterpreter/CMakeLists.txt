cmake_minimum_required(VERSION 3.13.4)

# 这里设置你 llvm 的路径
set(LLVM_PREFIX "/usr/local/opt/llvm")
# 这里是你 llvm 源码的路径
set(LLVM_SRC_DIR "~/Documents/GitHub/llvm-project/llvm")

# 支持 c++ 14
set(CMAKE_CXX_STANDARD 14)

find_package(LLVM REQUIRED CONFIG)
include(AddLLVM)
add_definitions(${LLVM_DEFINITIONS})
include_directories(${LLVM_INCLUDE_DIRS})
link_directories(${LLVM_LIB_DIRS})

set(LLVM_LINK_COMPONENTS interpreter bitreader asmparser selectiondag irreader)
set(LLVM_BUILD_TOOLS true)


add_library(mingInterpreter MODULE
    # 列出源文件
    mingInterpreter.cpp
    MInterpreter.cpp
)

# 使用 C++11 以上版本来编译 pass
target_compile_features(mingInterpreter PRIVATE cxx_range_for cxx_auto_type)

# LLVM 一般不会用 C++ RTTI，需要加上
set_target_properties(mingInterpreter PROPERTIES
    COMPILE_FLAGS "-fno-rtti"
)

# macOS 获取动态库的方式
if(APPLE)
    set_target_properties(mingInterpreter PROPERTIES
        LINK_FLAGS "-undefined dynamic_lookup"
    )
endif(APPLE)

target_link_libraries(mingInterpreter ffi)

# 添加额外的头文件，主要是要用安装时没有包含的 ExecutionEngine/Interpreter/Interpreter.h
include_directories(${LLVM_SRC_DIR}/lib)