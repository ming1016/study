add_library(MingPass MODULE
    # 列出源文件
    MingPass.cpp
)

# 使用 C++11 以上版本来编译 pass
target_compile_features(MingPass PRIVATE cxx_range_for cxx_auto_type)

# LLVM 一般不会用 C++ RTTI，需要加上
set_target_properties(MingPass PROPERTIES
    COMPILE_FLAGS "-fno-rtti"
)

# macOS 获取动态库的方式
if(APPLE)
    set_target_properties(MingPass PROPERTIES
        LINK_FLAGS "-undefined dynamic_lookup"
    )
endif(APPLE)
