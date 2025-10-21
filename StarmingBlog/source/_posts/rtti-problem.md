---
title: 从汇编到 ABI：彻底搞懂 C++ 异常匹配为何只认地址不认名字
date: 2025-10-21 18:39:03
tags: [iOS, C++]
categories: Programming
banner_img: /uploads/rtti-problem/01.png
---

这个编译参数你没加对，程序就会崩崩崩崩崩。

## 忙人简阅

本文较长，如果你没有时间和精力可以看完我的简述就行。

这是一个关于 C++ RTTI（运行时类型信息）问题的技术梳理，核心问题是：

- 同名类型的 `type_info` 对象地址不一致
- 异常捕获失效（基类 `std::exception&` 无法捕获派生类 `std::runtime_error`）
- `dynamic_cast` 失败返回空指针

原因是混用了 `-frtti`（启用RTTI）和 `-fno-rtti`（禁用RTTI）编译选项，导致同一类型生成了多个本地/隐藏的 `type_info` 副本。由于异常匹配机制默认通过"指针相等"来比较类型（而非比较类型名字），导致类型匹配失败。

快速解决方案
- 统一启用 RTTI 编译选项
- 使用 `-D_LIBCPP_TYPEINFO_COMPARISON_IMPLEMENTATION=2` 让类型比较改为先比指针、再比名字
- 改为按具体类型捕获异常（而非基类）

就像一方古砚，匠人依祖传图谱复刻两方。虽铭文相同，然鉴者只辨石纹肌理（指针），不察铭文笔意（名讳），终是判作异品。

## 内容涵盖

如果你有时间，本文会带你踏上一场从表象到本质的技术考究：

从 C++ 异常的两阶段展开机制讲起，深入 `__cxa_throw`、`__gxx_personality_v0`、LSDA 表的二进制编码（ULEB128/DWARF），直至 `type_info::operator==` 的三种实现策略。你会理解为什么"指针相等"是默认选择，以及它如何成为这场灾难的导火索。通过 LLVM 源码（`ItaniumCXXABI.cpp`）揭秘 `-fno-rtti` 为何会生成本地 `type_info` 副本，符号可见性（weak/local/hidden）如何影响链接器的去重行为，以及 LTO、Strip、PGO 等优化手段可能埋下的隐患。从 `nm`/`objdump` 符号分析到 GDB/dtrace/eBPF 动态追踪，从自动化检测脚本到 CI 集成方案。你会掌握在茫茫二进制中定位"幽灵 type_info"的全套武器，以及如何在 iOS 真机、大型 CocoaPods 工程中排查这类"灵异事件"。

不止于"统一启用 RTTI"的标准答案，还会剖析 `_LIBCPP_TYPEINFO_COMPARISON_IMPLEMENTATION=2` 的权衡、`std::type_index` 污染的连锁反应，以及模块化边界、协程、多线程等现代 C++ 特性下的新挑战。异常安全等级、`std::exception_ptr` 的引用计数实现、`std::nested_exception` 的多继承魔法、Foreign exceptions 的跨语言传播、Sanitizers 的微妙干扰、C++20 模块的符号管理、Herb Sutter 的静态异常提案（P0709R4），以及协程/内存序与异常处理的罕见交互。

本文既是一次 ABI 层的考古，也是一场编译链的解谜，更是一份生产环境的避坑指南。读完之后，你不仅能修复眼前的崩溃，还能在下一次架构设计时，提前规避这类深层陷阱。
### 阅读指引

- **主线问题与根因**：`问题背景 → 极简示例 → 为什么 type_info 地址不同会导致异常捕获失败`，回答“为什么只认地址不认名字”。
- **原理深挖**：`两阶段展开 / throw / LSDA / type_info 比较`，解释异常匹配在 ABI/LSDA 层如何以指针判等。
- **工程成因**：`-fno-rtti → 本地 type_info → 符号可见性/链接 → LTO`，说明何以产生“多份身份证”。
- **方案与落地**：`如何解决 → 案例/诊断方法`，给出可操作的修复与排查。
- **扩展与附录**：`深入理解异常处理 / 真机问题 / 异常相关工具 / PGO/模块/协程等`。这些章节与主线的共同关联点是：它们会影响 `type_info` 的唯一性或异常展开路径，从而决定是否触发“只认地址”的不匹配。

接下来我们先从直观现象出发，再逐步深入到 ABI 细节与工程实践。


## 问题背景

且说那书生持官府勘合至钱庄兑银，掌柜验看良久，蹙眉道："此牒虽真，然敝号簿册竟无对应。"  
书生愕然："此乃府衙亲发，墨迹犹新！"  

掌柜捻须叹曰："老朽亦知非伪，然簿中字号偏生对不上，奇哉怪也！"

C++ 的 RTTI 机制也会遇到类似的"灵异事件"，表现为两大核心症状：

症状一：异常处理失效

```cpp
try {
    throw std::runtime_error("测试异常");  // 抛出子类
} catch (const std::exception& e) {        // 用基类捕获
    // 按理说应该能捕获...
}
// 结果：程序崩溃！异常没被捕获！
```

代码明明写了 `catch (std::exception&)`（基类），确实抛出了 `std::runtime_error`（子类，继承关系正确），但程序崩了，异常"穿透"了 catch 块。

症状二：`dynamic_cast` 返回空指针

```cpp
class Base { virtual ~Base() {} };
class Derived : public Base {};

Base* ptr = new Derived();
Derived* d = dynamic_cast<Derived*>(ptr);
// 结果：d == nullptr！明明继承关系正确！

// 或者引用版本直接抛出异常
try {
    Base& ref = *ptr;
    Derived& d = dynamic_cast<Derived&>(ref);  
} catch (std::bad_cast& e) {
    // 抛出了 bad_cast，本不该如此
}
```

继承关系明确：`Derived` 继承自 `Base`，对象确实是 `Derived` 类型，但 `dynamic_cast` 失败，返回 `nullptr` 或抛出 `std::bad_cast`

## 极简示例

理解了问题的表象，接下来通过一个可复现的极简示例，让你亲眼看到这个"灵异事件"是如何发生的。

本文通过一个极简示例，演示混用不同 RTTI（运行时类型信息）编译选项时，`type_info` 符号污染导致的异常处理失效问题，并深入分析 C++ 异常处理机制的底层实现原理。

main.cpp

```cpp
#include <iostream>
#include <stdexcept>
#include <typeinfo>

int main() {
try {
    throw std::runtime_error("测试异常");
} catch (const std::exception& e) {
    // 打印 typeid(e) 的信息
    std::cout << "typeid(e):" << std::endl;
    std::cout << "  name: " << typeid(e).name() << std::endl;
    std::cout << "  addr: " << &typeid(e) << std::endl;
    
    std::cout << std::endl;
    
    // 打印 typeid(std::runtime_error) 的信息
    std::cout << "typeid(std::runtime_error):" << std::endl;
    std::cout << "  name: " << typeid(std::runtime_error).name() << std::endl;
    std::cout << "  addr: " << &typeid(std::runtime_error) << std::endl;
    }
    
    return 0;
}
```

no_rtti_lib.cpp

```cpp
#include <stdexcept>

void never_called_function() {
    throw std::runtime_error("这个函数不会被main调用");
}
```

`no_rtti_lib.cpp` 不会被 `main.cpp` 调用，但它引用了 `std::runtime_error`，编译时使用 `-fno-rtti` 选项。

正常情况：都启用 RTTI

```bash
# 编译 main.cpp（启用 RTTI）
clang++ -std=c++17 -frtti -c main.cpp -o main_normal.o

# 编译 no_rtti_lib.cpp（启用 RTTI）
clang++ -std=c++17 -frtti -c no_rtti_lib.cpp -o no_rtti_lib_normal.o

# 链接
clang++ -std=c++17 main_normal.o no_rtti_lib_normal.o -o try_catch_normal
```

运行产物 `./try_catch_normal`，输出：

```
typeid(e):
  name: St13runtime_error
  addr: 0x1fe438940

typeid(std::runtime_error):
  name: St13runtime_error
  addr: 0x1fe438940
```

两个 `type_info` 的地址相同，这是正常且符合预期的行为。异常被成功捕获。

异常情况：no_rtti_lib 禁用 RTTI

```bash
# 编译 main.cpp（启用 RTTI）
clang++ -std=c++17 -frtti -c main.cpp -o main.o

# 编译 no_rtti_lib.cpp（禁用 RTTI）
clang++ -std=c++17 -fno-rtti -c no_rtti_lib.cpp -o no_rtti_lib.o

# 链接
clang++ -std=c++17 main.o no_rtti_lib.o -o try_catch_demo
```

运行 `./try_catch_demo`，输出：

```
typeid(e):
  name: St13runtime_error
  addr: 0x1fe438940

typeid(std::runtime_error):
  name: St13runtime_error
  addr: 0x10474c0e0
```

类型名称相同，都是 `St13runtime_error`，但地址不同！这就是问题的根源。

当某目标以 `-fno-rtti` 构建时，往往会在该目标内生成本地/隐藏的 `type_info`，与标准库中的同名类型彼此不合并，最终导致地址不一致。下列命令可快速验证：

```bash
nm -C main.o | grep "typeinfo for"
nm -C no_rtti_lib.o | grep "typeinfo for"
nm -C try_catch_demo | grep "typeinfo for std::runtime_error"
```

常见输出解读：

- `U typeinfo for std::runtime_error`：未定义符号，链接期期待从标准库解析（健康）。
- `S typeinfo for std::runtime_error` 或小写 `s`：本地/私有符号，意味着该目标内自生成副本（需警惕）。

MMKV 也曾经出现过这个问题，[MMKV Issue #744](https://github.com/Tencent/MMKV/issues/744)，[修复说明](https://github.com/Tencent/MMKV/releases/tag/v1.3.2)。

小结与过渡：到此我们已经在二进制层面实证了“同名不同址”。接下来转入异常机制本身，解释为何匹配只看指针地址，以及这会如何在展开流程中导致穿透。

## 为什么 type_info 地址不同会导致异常捕获失败

看到这里你可能会问：为什么仅仅是地址不同，就会导致如此严重的后果？这不只是一个简单的"指针比较"问题，背后涉及 C++ 异常处理机制的整个工作流程。让我们从底层实现一步步揭开这个谜题。

### 两阶段

C++ 异常处理就像快递退货流程

```
你（调用函数）          快递站（栈帧）           退货中心（catch块）
     │                       │                       │
     │ ① 发起退货             │                       │
     │ throw error()         │                       │
     ├──────────────────────→│                       │
     │                       │                       │
     │                       │ ② 阶段一: 打电话问     │
     │                       │   "谁能接收这个货？"     │
     │                       │   （搜索阶段-不动手）    │
     │                       ├──────────────────────→│
     │                       │←──────────────────────┤
     │                       │   "我能接收！"          │
     │                       │                       │
     │                       │ ③ 阶段二: 真的送货     │
     │                       │   - 沿路整理包装盒      │
     │                       │     (调用析构函数)      │
     │                       ├──────────────────────→│
     │                       │                       │
     │                       │                       │ ④ 接收并处理
     │                       │                       │ catch(error&){...}
     │←──────────────────────┴───────────────────────┘
     │ 继续执行
```

两个阶段极简示意：
```
Phase 1: search → personality 读 LSDA → 找到可处理者? yes → 记录
Phase 2: cleanup → 析构/cleanup → 跳转 landing pad → 执行 catch
```

阶段一时，"退货中心"怎么判断"货物类型"匹配？答案是比较货物的"身份证"（`type_info` 指针）。

悲剧场景：
- 货物出厂时贴了标签 A（地址 0x1000）
- 但因为某个环节用了 `-fno-rtti`，又生成了标签 B（地址 0x2000）
- 退货中心登记的是标签 B，但货物上贴的是标签 A
- 结果：明明是对的货，却被拒收！

实际的技术实现...

为什么需要两阶段展开？

这个设计决策来自 Itanium C++ ABI 的核心考量：

如果采用单阶段展开会有什么问题？

考虑以下场景：

```cpp
void process() {
    Resource r1;  // RAII 资源 1
    try {
        Resource r2;  // RAII 资源 2
        dangerous_operation();  // 可能抛出异常
    } catch (const SpecificError& e) {
        // 处理特定错误
    }
    // r1 仍需在此作用域中使用
}
```

单阶段方案的问题
- 提前析构困境：开始展开就必须立即调用析构函数（释放 r2）
- 匹配失败无法回滚：如果走到某个 catch 发现类型不匹配，但 RAII 对象已经被析构了
- 无法保证异常安全：如果析构函数本身抛出异常，系统状态混乱

两阶段方案的优势

```
阶段一（搜索阶段 - Search Phase）：
  目的：找到能处理异常的 handler，但不破坏任何状态
  操作：
    - 遍历调用栈
    - 查询每个函数的 LSDA
    - 调用 personality function 询问"能处理吗？"
    - 不调用析构函数
    - 不改变程序状态
  结果：
    - 找到 handler → 进入 阶段二
    - 未找到 → 调用 std::terminate

阶段二（清理阶段 - Cleanup Phase）：
  目的：真正展开栈，执行清理，跳转到 handler
  操作：
    - 从抛出点开始，逐帧展开
    - 调用所有 RAII 对象的析构函数
    - 执行 cleanup 代码
    - 最终跳转到阶段一找到的 handler
```

阶段一是"试探性"的，不破坏状态；只有确认有人能接住了，阶段二才真正开始清理。这保证了要么完全处理，要么完全未处理（terminate）。析构顺序可预测，不会因匹配失败而混乱，阶段一可以提前终止，避免不必要的清理。

两阶段展开的实际工作流程

C++ 异常处理遵循 [Itanium C++ ABI](https://itanium-cxx-abi.github.io/cxx-abi/abi-eh.html) 规范（即使在非 Itanium 平台上也广泛使用），整个流程可以分为以下几个阶段：

- 抛出异常（throw）：编译器生成调用 `__cxa_throw` 的代码
- 逐层回溯（Stack Unwinding）：通过 `_Unwind_RaiseException` 遍历调用栈
- 查找降落点（Landing Pad Search）：在每个栈帧中查找 LSDA（语言专属数据区，Language Specific Data Area）
- 类型匹配（Type Matching）：判断 catch 子句是否能捕获该异常
- 执行处理器：跳转到匹配的 catch 块执行

详见：[Two-Phase Unwinding](https://itanium-cxx-abi.github.io/cxx-abi/abi-eh.html#base-unwind)

阶段一 - 搜索阶段（`_UA_SEARCH_PHASE`）

```
抛出点
  ↓
_Unwind_RaiseException(&exception)
  ↓
遍历栈帧 1 → 调用 personality(_UA_SEARCH_PHASE, ...)
               ├─ 有匹配的 catch？
               │  ├─ Yes → 返回 _URC_HANDLER_FOUND，记录位置
               │  └─ No  → 返回 _URC_CONTINUE_UNWIND
               ↓
遍历栈帧 2 → personality(...) 
               ↓
             ...
               ↓
找到 handler → 记录"降落点" → 开始阶段二
未找到       → 调用 std::terminate()
```

阶段二 - 清理阶段（`_UA_CLEANUP_PHASE`）

```
从抛出点重新开始
  ↓
逐帧展开，调用 personality(_UA_CLEANUP_PHASE, ...)
  ├─ 析构局部 RAII 对象
  ├─ 执行 cleanup 代码
  └─ 到达阶段一记录的降落点时：
      ↓
     personality 返回 _URC_INSTALL_CONTEXT
      ↓
     跳转到 landing pad（catch 块入口）
      ↓
     执行 catch 代码
```

举个例子

```cpp
void level3() { throw std::runtime_error("error"); }

void level2() {
    Resource r2;  // 有析构函数
    level3();
}

void level1() {
    Resource r1;
    try {
        level2();
    } catch (const std::exception& e) {
        // handler 在这里
    }
}
```

执行流程如下：

```
1. level3 抛出异常
2. 阶段一搜索：
   - level3: 无 LSDA，继续
   - level2: 无 catch，继续
   - level1: 有 catch(std::exception&)
     → personality 检查 type_info 匹配
     → 匹配成功！返回 _URC_HANDLER_FOUND
3. 阶段二清理：
   - 回到 level3（无清理）
   - level2: 调用 r2 析构函数
   - level1: 调用 r1 析构函数，跳转到 catch 块
4. 执行 catch 代码
```

如果 type_info 污染，在阶段一的类型匹配步骤，如果 `type_info` 指针不一致，personality 会返回 `_URC_CONTINUE_UNWIND` 而非 `_URC_HANDLER_FOUND`，导致搜索失败，最终 `std::terminate`。

Ian Lance Taylor（Itanium ABI 设计者）在他[博客](https://www.airs.com/blog/archives/464)中详细解释了两阶段设计的权衡和动机。

### throw

理解了两阶段展开的宏观流程，接下来看看抛出异常时到底发生了什么。

throw 是如何实现的呢？

throw 做了三件事：分配异常对象、构造它、调用 `__cxa_throw` 并传入 type_info 指针。这个指针后续用于匹配。

当执行 `throw std::runtime_error("测试异常")` 时，编译器会生成类似以下的代码（简化表示）：

```cpp
// 分配异常对象
void* exception_ptr = __cxa_allocate_exception(sizeof(std::runtime_error));
// 构造异常对象
new (exception_ptr) std::runtime_error("测试异常");
// 抛出异常
__cxa_throw(exception_ptr, &typeid(std::runtime_error), destructor_ptr);
```

`__cxa_throw` 的第二个参数是指向 `type_info` 对象的指针，这个指针将用于后续的类型匹配。参见源码 [libcxxabi/src/cxa_exception.cpp](https://github.com/llvm/llvm-project/blob/main/libcxxabi/src/cxa_exception.cpp)。

```cpp
extern "C" void
__cxa_throw(void *thrown_object, std::type_info *tinfo, void (_LIBCXXABI_DTOR_FUNC *dest)(void *))
{
    __cxa_eh_globals *globals = __cxa_get_globals();
    __cxa_exception* exception_header = cxa_exception_from_thrown_object(thrown_object);

    exception_header->exceptionType = tinfo;  // 存储 type_info 指针
    exception_header->exceptionDestructor = dest;
    // ...
    _Unwind_RaiseException(&exception_header->unwindHeader);
}
```

### 栈展开与 LSDA

抛出异常后，系统需要回溯调用栈寻找能处理它的 catch 块。这个过程的关键就是 LSDA 表。

`_Unwind_RaiseException` 遍历栈帧，每帧调用 personality 读取 LSDA 表来判断能否处理异常。`_Unwind_RaiseException` 会遍历调用栈，对每个栈帧调用 personality routine。在 C++ 中，这个函数是 `__gxx_personality_v0`。

`__gxx_personality_v0` 决策分支（伪代码）

```c
int personality(int phase, exception_object* ex, lsda* L) {
  if (phase == SEARCH_PHASE) {
    for (auto& cs : L->call_sites) {
      if (pc_in_range(cs.start, cs.len)) {
        if (cs.action == 0) continue; // cleanup only
        for (auto a = action_at(cs); a; a = a->next) {
          if (a->typeIndex == 0) continue; // cleanup
          const type_info* catchType = L->type_table[a->typeIndex];
          if (__cxa_can_catch(catchType, ex->type, &adj))
            return HANDLER_FOUND; // Phase 1 告知可处理
        }
      }
    }
    return CONTINUE_UNWIND; // 未找到
  } else { // CLEANUP_PHASE
    run_cleanups_and_maybe_enter_landing_pad();
    return INSTALL_CONTEXT; // 切换到 landing pad
  }
}
```

真实实现还需处理 `filter`（如 `catch(...)`）、`foreign exception`、以及位移/访问控制等细节，完整逻辑以 libc++abi 源码为准。

核心数据结构 [LSDA（语言专属数据区，Language Specific Data Area）](https://itanium-cxx-abi.github.io/cxx-abi/abi-eh.html#lsda) 是编译器为每个函数生成的异常处理表。包含记录哪些代码区域有 try 块的 Call-Site 表，记录每个 landing pad 对应的 catch 类型的Action 表，还有保存 catch 子句能接受的类型（`type_info*` 的编码索引）的 Type 表，Type 表中存储的是 `type_info` 指针。如果该指针指向"假货"（本地副本），匹配就会失败。源码参考：[libcxxabi/src/cxa_personality.cpp](https://github.com/llvm/llvm-project/blob/main/libcxxabi/src/cxa_personality.cpp)

LSDA 二进制布局在不同平台/编译器具体编码略有差异，下图为 Itanium 风格常见形态，省略 LEB128 与对齐细节。

```
+-------------------+  LSDA header
| lpStart (ULEB128) |
| ttypeEnc (u8)     |→ 描述 Type Table 的编码方式
| ttypeOff (ULEB128)|→ 从 LSDA 头到 Type Table 的偏移
| csEnc (u8)        |→ Call-Site 表中地址/范围的编码
+-------------------+
|  Call-Site Table  |
|  [start, len,     |
|   landingPad,     |
|   action]  × N    |
+-------------------+
|    Action Table   |
|  [typeIndex,next] |
|   ... 链表结构     |
+-------------------+
|     Type Table    |
|  [T1, T2, ...]    |  Ti 通常编码为对 `type_info*` 的引用（索引为负值反向引用）
+-------------------+
```

`action` 为 0 通常表示仅清理；非 0 表示有 `catch` 链，`typeIndex` 为负值时，按"反向索引"从 Type Table 末尾回溯，personality 按 encodings 解码地址范围，沿 action 链逐项匹配类型。

LSDA 用变长编码 LEB128 压缩数据。无论编码如何，存的都是 type_info 指针，指针错了就全错。

为什么需要复杂的编码方案？

LSDA 是异常处理的"指导手册"，每个可能抛出异常的函数都需要一份。问题在于大型项目可能有数万个函数，每个函数的 LSDA 可能有几十到几百字节，累积起来可达数 MB，影响二进制大小和加载时间。正常路径（无异常）：LSDA 完全不被访问，零开销，异常路径：需要快速解析 LSDA，找到正确的 handler。使用变长编码和多种指针表示方式，在空间和速度之间取得平衡。

ULEB128（Unsigned LEB128）编码原理

```
原理：每字节 7 位存数据，最高位（bit 7）标识是否继续
- bit 7 = 1: 后面还有字节
- bit 7 = 0: 这是最后一个字节

示例 1：编码 127（0x7F）
  二进制：0111 1111
  只需 1 字节：0x7F（bit 7 = 0，结束）

示例 2：编码 300（0x12C = 0001 0010 1100）
  拆分为 7 位：
    低 7 位：010 1100 (0x2C)
    高 7 位：000 0010 (0x02)
  编码结果：
    第 1 字节：1010 1100 (0xAC) ← bit 7=1，继续
    第 2 字节：0000 0010 (0x02) ← bit 7=0，结束
```

小整数（< 128）：1 字节，中等整数（128-16383）：2 字节，大整数（> 16383）：按需扩展。在 LSDA 中，大多数偏移量、索引都是小整数，平均只需 1-2 字节。

SLEB128（Signed LEB128）支持负数，用于 Type Table 的反向索引。Action 记录中 `typeIndex = -2` 表示是倒数第 2 个类型。

DWARF 指针编码（DW_EH_PE_*）在不同场景下指针的表示方式不同，通过编码标志选择：

基础编码类型

| 编码常量 | 值 | 含义 | 何时使用 |
|---------|---|------|---------|
| `DW_EH_PE_absptr` | 0x00 | 绝对地址（4/8字节） | 固定加载地址 |
| `DW_EH_PE_uleb128` | 0x01 | ULEB128 整数 | 小整数/索引 |
| `DW_EH_PE_udata2` | 0x02 | 2字节无符号 | 小范围偏移 |
| `DW_EH_PE_udata4` | 0x03 | 4字节无符号 | 中等范围 |
| `DW_EH_PE_udata8` | 0x04 | 8字节无符号 | 大范围/64位 |
| `DW_EH_PE_sleb128` | 0x09 | SLEB128 整数 | 有符号偏移 |
| `DW_EH_PE_sdata4` | 0x0B | 4字节有符号 | 相对偏移 |

应用方式修饰符

| 修饰符 | 值 | 含义 | 为什么需要 |
|-------|---|------|-----------|
| `DW_EH_PE_pcrel` | 0x10 | 相对 PC 偏移 | **位置无关代码（PIC）** |
| `DW_EH_PE_datarel` | 0x30 | 相对数据段基址 | 共享库 |
| `DW_EH_PE_indirect` | 0x80 | 间接指针 | 延迟绑定 |

组合使用示例

```c
// 常见组合
DW_EH_PE_pcrel | DW_EH_PE_sdata4  // PC 相对的 4 字节偏移
DW_EH_PE_datarel | DW_EH_PE_udata4  // 数据段相对的 4 字节偏移
```

为什么 PIC 需要 `pcrel`（PC 相对寻址）？

共享库（.so/.dylib）加载地址不固定

```
非 PIC（绝对地址）：
  type_info 地址：0x12345000  ← 写死在 LSDA 中
  问题：库加载到不同地址（如 0x20000000）时，地址失效

PIC（PC 相对）：
  type_info 偏移：+0x1000 (相对当前 PC)
  优势：无论库加载到哪里，偏移量不变
```

实际代码：

```c
// LSDA header 解码（libcxxabi 简化）
uint8_t ttypeEnc = read_byte(lsda);  // 例如：0x9B
// 分解编码：
//   基础类型：0x0B (DW_EH_PE_sdata4)
//   应用方式：0x90 (DW_EH_PE_pcrel | DW_EH_PE_indirect)
// 含义：通过 PC 相对偏移间接访问 4 字节指针

if (ttypeEnc != DW_EH_PE_omit) {
    ttypeOffset = read_uleb128(lsda);  // 到 Type Table 的偏移
    // 实际访问：
    // type_info* = **(current_pc + ttypeOffset)
}
```

典型 LSDA 布局的空间分析

假设一个中等复杂度函数（2 个 try 块，3 个 catch）：

```
组件               | 字节数 | 说明
-------------------|--------|------
Header             | 3-5    | lpStart/ttype/csEnc
Call-Site Table    | 15-20  | 2 个 try 区域
Action Table       | 9-12   | 3 个 catch 链
Type Table         | 12-15  | 3 个 type_info* (pcrel)
-------------------|--------|------
总计               | ~40-50 | 使用绝对地址约 60-80 字节
```

变长编码 + PC 相对寻址，节省约 30-40% 空间。

无论使用哪种编码，Type Table 最终存储的是 `type_info*` 的引用。

```c
// personality function 解码后：
const std::type_info* catch_type = decode_pointer(type_table[index], encoding);

// 匹配时：
if (catch_type == thrown_type) {  // ← 指针比较
    // 如果 catch_type 和 thrown_type 来自不同副本，
    // 即使名称相同，比较也会失败
}
```

影响

```bash
# 查看 LSDA 编码信息（需要 dwarf 工具）
readelf --debug-dump=frames your_binary | grep -A10 "FDE"

# 或使用 llvm-dwarfdump
llvm-dwarfdump --eh-frame your_binary
```

不同编码只影响存储方式，不影响最终的 `type_info*` 值。污染问题的根源在于多份 `type_info` 的存在，而非编码方式。

参考：
- DWARF 指针编码详解：[DWARF5 Standard §7.7](http://dwarfstd.org/doc/DWARF5.pdf)
- Ian Lance Taylor 关于编码选择的讨论：[Exception Frames](https://www.airs.com/blog/archives/464)
- LEB128 编码的效率分析：[DWARF Committee Discussion](http://dwarfstd.org/)


### 异常对象的内存管理

在讨论 type_info 匹配之前，还需要了解一个细节：异常对象是如何分配的？虽然这与污染问题的直接关联不大，但理解内存分配策略有助于我们排查某些特殊场景（如 OOM 时的异常处理）。

异常对象优先从 TLS 缓冲池分配，OOM 时用紧急缓冲区。污染问题与分配策略无关，但 emergency buffer 也会受影响。

`__cxa_allocate_exception` 的分配策略：

- 正常路径：从 TLS（线程局部存储）的 exception buffer pool 分配；pool 通常维护少量小块缓存（如 1KB × 4）以避免频繁系统调用。
- 大对象：超过 pool 单块上限时，直接 `malloc`。
- Emergency buffer：当 pool 耗尽且 `malloc` 失败（如 OOM 或在信号处理器中），回退到静态紧急缓冲区；通常约 4KB，复用前需检查当前是否正在被占用。

源码片段（简化）：

```cpp
void* __cxa_allocate_exception(size_t size) noexcept {
    size_t total = size + sizeof(__cxa_exception);
    // 尝试从 TLS pool
    void* p = pool_allocate(total);
    if (p) return adjust_pointer(p);
    // 回退系统分配
    p = malloc(total);
    if (p) return adjust_pointer(p);
    // 最后使用 emergency buffer（有限且需互斥）
    return emergency_allocate(total);
}
```

释放：`__cxa_free_exception` 根据对象来源（pool/malloc/emergency）回收；若在 emergency buffer 未释放前再次抛出，可能触发 `std::terminate`。

libc++abi 的 emergency buffer 默认大小通常为 4KB（具体值因版本而异，可在编译时配置）。在内存受限的嵌入式环境中，这个机制尤为重要。emergency buffer 不受 RTTI flags 影响，但其标准库实现依赖 `type_info` 的唯一性；污染后即使在 emergency 路径也会匹配失败。

### type_info 指针比较

现在到了最关键的环节：异常匹配时，系统究竟如何判断类型是否匹配？这是整个问题的核心所在。

当 personality routine 查找匹配的 catch 块时，会调用 `__cxa_can_catch` 函数进行类型匹配。每个 C++ 类型都有一个全局唯一的"身份证"——`type_info` 对象。异常匹配时，系统要验证"抛出的异常"和"catch 声明的类型"是不是"同一个人"。

但这里有个关键细节：系统默认只看证件编号（指针地址），不看姓名（类型名字符串）。

源码见：[libcxxabi/src/private_typeinfo.cpp](https://github.com/llvm/llvm-project/blob/main/libcxxabi/src/private_typeinfo.cpp)

```cpp
extern "C" bool
__cxa_can_catch(const std::type_info *catchType, 
                const std::type_info *excpType,
                void **adjustedPtr)
{
    return catchType->__do_catch(excpType, nullptr, adjustedPtr);
}
```

对于类类型，`__do_catch` 的实现在 `__class_type_info` 中：

```cpp
bool __class_type_info::__do_catch(
    const type_info *thrown_type,
    void **thrown_object,
    unsigned outer) const
{
    if (*this == *thrown_type)  // 关键：比较 type_info
        return true;
    
    // 检查继承关系
    const __class_type_info *thrown_class_type = 
        dynamic_cast<const __class_type_info *>(thrown_type);
    if (thrown_class_type == nullptr)
        return false;
    
    // 递归检查基类
    __dynamic_cast_info info = {/* ... */};
    thrown_class_type->has_unambiguous_public_base(&info, this, outer);
    // ...
}
```

重点来了 `type_info` 的 `operator==` 实现：

```cpp
bool type_info::operator==(const type_info& rhs) const noexcept
{
#if _LIBCPP_TYPEINFO_COMPARISON_IMPLEMENTATION == 1
    // 实现 1：只比较指针地址（默认且最快）
    return this == &rhs;
#elif _LIBCPP_TYPEINFO_COMPARISON_IMPLEMENTATION == 2
    // 实现 2：先比较指针，再比较名字
    return (this == &rhs) || (strcmp(this->name(), rhs.name()) == 0);
#elif _LIBCPP_TYPEINFO_COMPARISON_IMPLEMENTATION == 3
    // 实现 3：只比较名字（最慢但最安全）
    return strcmp(this->name(), rhs.name()) == 0;
#endif
}
```

用刷卡类比：
- 实现 1：刷卡机只认芯片编号（指针） - 快但容易出问题，
- 实现 2：先刷芯片，刷不过再看卡上的名字 - 
- 实现 3：折中方案，不管芯片，只看名字 - 慢但万无一失。

大多数系统用实现 1，所以"两张卡"（两份 type_info）就会被识别为"两个人"！

源码见：[libcxx/include/typeinfo](https://github.com/llvm/llvm-project/blob/main/libcxx/include/typeinfo)

本文描述的是 libc++ 的实现（通过宏控制）。libstdc++（GCC 标准库）的实现略有不同，通常直接比较指针或名字，且没有官方宏切换机制。MSVC 的实现基于不同的 ABI（SEH），本文描述主要针对 Itanium 风格实现（Clang/GCC/libc++，广泛用于 Linux/macOS/iOS/Android）。关于 `type_info` 的标准定义，参见 [cppreference: std::type_info](https://en.cppreference.com/w/cpp/types/type_info) 和 [C++ Standard [expr.typeid]](https://eel.is/c++draft/expr.typeid)。ODR（One Definition Rule）详见 [C++ Standard [basic.def.odr]](https://eel.is/c++draft/basic.def.odr)。

在大多数配置下，libc++ 使用实现 1，即只比较 `type_info` 的指针地址。这要求整个程序中每个类型只能有一个 `type_info` 实例（ODR - One Definition Rule）。

这就是问题的根源

- 抛出异常时，`__cxa_throw` 使用的 `type_info` 指针来自标准库（地址 0x1fe438940）
- catch 子句的 LSDA 中记录的 `std::runtime_error` 的 `type_info` 指针来自 `no_rtti_lib.o` 生成的副本（地址 0x10474c0e0）
- 指针比较 `this == &rhs` 返回 `false`，即使它们表示同一个类型
- 异常无法被捕获，程序崩溃

继承关系检查算法详解（`has_unambiguous_public_base`）

当抛出类型与 catch 类型不完全匹配时，personality 调用 `has_unambiguous_public_base` 检查继承：

源码见：[libcxxabi/src/private_typeinfo.cpp](https://github.com/llvm/llvm-project/blob/main/libcxxabi/src/private_typeinfo.cpp)

```cpp
void __class_type_info::has_unambiguous_public_base(
    __dynamic_cast_info* info,
    const void* adjustedPtr,
    int pathBelow) const
{
    if (*this == *info->dst_type) {
        info->found_dst_path(adjustedPtr, pathBelow);
        return;
    }
    // 对于单继承（__si_class_type_info）
    if (is_single_inheritance) {
        base->has_unambiguous_public_base(info, adjustedPtr, pathBelow);
    }
    // 对于多继承（__vmi_class_type_info），遍历所有基类
    for (auto& base : bases) {
        void* newPtr = adjust_pointer(adjustedPtr, base.offset);
        base.type->has_unambiguous_public_base(info, newPtr, pathBelow | base.flags);
    }
}
```

关键结构 `__dynamic_cast_info`：

```cpp
struct __dynamic_cast_info {
    const __class_type_info* dst_type;  // catch 的目标类型
    const void* static_ptr;              // 抛出对象指针
    const __class_type_info* src_type;   // 抛出类型
    int number_of_dst_found;             // 找到目标类型次数（检测多义性）
    // ...
};
```

多重和虚继承的影响：

- 多重继承：需调整指针偏移（base.offset），若有多条到达目标类型的路径（多义性），匹配失败。
- 虚继承：offset 动态计算（通过 vtable），需额外检查 `is_virtual` 标志；虚基类只能有一条路径。
- private/protected 继承：`base.flags` 中的 `__public_mask` 位标识可见性；非公开继承路径会被忽略。

即便继承关系正确，若 `*this == *info->dst_type` 时因 `type_info*` 地址不同而失败，后续遍历也无济于事。多重继承和虚继承的场景下也需要指针调整，但若 type_info 污染，连第一步类型判断都过不了，更谈不上后续的指针调整。

多重继承案例

```cpp
struct A { virtual ~A() {} };
struct B { virtual ~B() {} };
struct C : public A, public B {};  // 多重继承

void test() {
    try {
        throw C();
    } catch (A&) { /* 匹配，pointer 需调整 */ }
    catch (B&) { /* 匹配，pointer 需调整到 B subobject */ }
}
```

正常情况下，personality 会判断 `C != A`，进入继承检查；遍历 C 的基类，找到 A，调整指针到 A subobject 起始位置；匹配成功，进入 catch(A&)。

但若 A/B/C 的 `type_info` 被污染（地址不一致），第一步 `*this == *thrown_type` 与第二步 `*this == *info->dst_type` 均失败，抛出成为未捕获异常。

关于多重继承和虚继承的内存布局，参见 [Itanium C++ ABI: Class Layout](https://itanium-cxx-abi.github.io/cxx-abi/abi.html#layout)。推荐阅读 *Inside the C++ Object Model* by Stanley Lippman (ISBN: 0-201-83454-5)，这是理解 C++ 对象模型的经典著作。

### 为什么 -fno-rtti 会生成重复的 type_info

到这里我们已经知道了异常匹配依赖 type_info 指针比较。那么问题来了：为什么 `-fno-rtti` 会导致 type_info 重复？编译器为何不能"聪明"地复用标准库中已有的？

用"地下工厂"来打个比喻。

正常情况 `type_info` 就像央行印钞，全国只有一个"中国人民银行"印人民币，每张 100 元钞票都是官方的，序列号唯一，大家认的是"官方渠道的钞票"（标准库的 type_info）。

启用 `-fno-rtti` 后就像开了"地下印钞厂"，明明央行已经印好了"std::runtime_error"的身份证，你的代码又私自印了一批（local type_info），虽然长得一样，但序列号（地址）不同，系统只认央行版本，你的"私货"不被承认。

编译器是怎么做的？

这涉及到编译器的实现细节。查看 LLVM 源码中的 `ItaniumCXXABI.cpp`：

源码位置：[llvm/lib/CodeGen/ItaniumCXXABI.cpp](https://github.com/llvm/llvm-project/blob/main/clang/lib/CodeGen/ItaniumCXXABI.cpp)

```cpp
llvm::Constant *ItaniumCXXABI::BuildTypeInfo(QualType Ty) {
    // 检查是否应该使用外部的 type_info
    if (IsStandardLibraryRTTIDescriptor(Ty) ||
        ShouldUseExternalRTTIDescriptor(CGM, Ty))
        return GetAddrOfExternalRTTIDescriptor(Ty);
    
    // 否则生成新的 type_info
    // ...
}

bool ItaniumCXXABI::ShouldUseExternalRTTIDescriptor(CodeGenModule &CGM, QualType Ty) {
    // 如果禁用了 RTTI，直接返回 false
    if (!Context.getLangOpts().RTTI) 
        return false;  // ← 关键！
    
    // 其他检查...
}
```

正常情况（启用 RTTI）：编译器检测到类型已在标准库中定义，生成未定义符号（U），链接时使用标准库的 `type_info`。禁用 RTTI 后：`ShouldUseExternalRTTIDescriptor` 返回 `false`，编译器为异常处理强制生成本地 `type_info`（标记为 local symbol）。

这样做的原因是异常处理机制依赖 `type_info`，即使禁用了 RTTI，也需要为 `throw`/`catch` 中涉及的类型生成 `type_info`。但这些 `type_info` 被标记为局部符号，不参与全局链接，导致符号污染。

### 符号可见性与链接行为

有了编译器生成的 type_info 副本，链接器为何不能将它们合并？这涉及到符号可见性和链接机制的深层细节。

在 Itanium ABI 中，`type_info` 的唯一性通过以下机制保证（详见 [Itanium C++ ABI: RTTI Layout](https://itanium-cxx-abi.github.io/cxx-abi/abi.html#rtti)）。标准情况下，`type_info` 是 weak 符号，链接器会合并所有相同的 weak 符号。使用 `default` 可见性，确保跨动态库共享。关于符号可见性和链接行为，参见 [GCC Wiki: Visibility](https://gcc.gnu.org/wiki/Visibility) 和 [Linker and Libraries Guide](https://docs.oracle.com/cd/E19683-01/816-1386/6m7qcoblk/index.html)。

但禁用 RTTI 后，生成的 `type_info` 是 local/hidden 符号。链接器不会合并这些符号，最终可执行文件中存在多个相同类型的 `type_info` 实例，指针比较失败，异常捕获失效。

可以通过以下命令查看符号的详细信息：

```bash
# 查看符号类型和可见性
objdump -t no_rtti_lib.o | grep runtime_error
nm -gU no_rtti_lib.o  # 查看外部符号
nm -u no_rtti_lib.o   # 查看未定义符号
```

总的来说因果链如下：

```
-fno-rtti 编译选项
    ↓
编译器生成本地 type_info（local symbol）
    ↓
链接器不合并本地符号
    ↓
同一类型存在多份 type_info（地址不同）
    ↓
operator== 只比指针（实现 1）
    ↓
匹配失败，异常捕获失效
```


### LTO（Link-Time Optimization）的特殊影响

除了 `-fno-rtti`，还有一个容易被忽视的"帮凶"——链接时优化（LTO）。LTO 的激进优化可能会折叠或移除看似重复的 type_info，进一步加剧问题。

启用 `-flto` 后，编译器在链接阶段会进行全局优化，可能会将"看起来相同"的 type_info 合并，但如果合并的依据错误（比如基于名字而非语义），可能导致某些异常无法被基类捕获。这是一个更隐蔽的陷阱，需要在启用 LTO 时特别注意 RTTI 配置的一致性。

到这里，我们已经完整梳理了 type_info 污染问题的技术链条。但实际工程中，异常处理的复杂性远不止于此。接下来的章节会探讨一些与本问题密切相关的扩展场景——它们或许不是直接原因，但理解这些知识有助于你在更复杂的环境中排查和预防类似问题。

## 深入理解异常处理

前面我们聚焦于 type_info 污染的核心机制。但在真实的大型项目中，异常处理还会遇到许多相关的技术挑战。这些扩展话题虽然不是污染问题的直接成因，但它们与 type_info 机制紧密交织，理解它们能让你在排查时更加得心应手。

阅读提示：以下小节多为“相关但非根因”的扩展。每节关注点要么影响 `type_info` 的唯一性，要么改变异常展开是否能正确抵达类型匹配点，请在排查时与主线问题对照辨析。

本问题相邻的坑

下面这些情况虽然表现类似（异常捕获失败），但根因不同。了解它们有助于避免"头痛医脚"：

- 手写/Hook 汇编桩未携带完整 CFI（`.cfi_startproc/.cfi_endproc` 等），导致展开在该帧中止，例如拦截 `objc_msgSend` 却未补全 CFI 信息。
- 错误的链接/裁剪移除了必要的异常/展开元数据（Darwin 上的 `__TEXT,__unwind_info` 或相应 LSDA），或目标被 LTO/裁剪优化到不可达路径从而丢失处理器。
- 在部分目标禁用异常（`-fno-exceptions`）但仍期望跨边界抛接，导致 personality/LSDA 缺失，配合 `-fno-rtti` 问题更隐蔽。

与主题的关联：当 CFI/LSDA 不完整时，展开可能在抵达类型匹配前被迫中止，表现为“基类未命中”的相似崩溃，应与 RTTI 污染（多份 `type_info`）区分。

Darwin/arm64 反汇编与 CFI/landing pad 标注示例

命令示例：

```bash
otool -arch arm64 -tV try_catch_demo | sed -n '1,200p'
otool -l try_catch_demo | grep -A2 __unwind_info
llvm-objdump -d --mcpu=apple-m1 --show-cfi try_catch_demo | sed -n '1,200p'
```

典型片段（示意）：

```
__Z4testv:
  stp x29, x30, [sp, #-16]!
  mov x29, sp
  bl  __Z15throw_somethingv
  b   Lret
Llanding_pad:                  ; LSDA 指向的落地点
  bl  __cxa_begin_catch
  bl  __cxa_end_catch
  b   Lret
Lret:
  ldp x29, x30, [sp], #16
  ret

; CFI 注记（llvm-objdump --show-cfi 可见）
.cfi_startproc
.cfi_def_cfa  sp, 16
.cfi_offset   x29, -16
.cfi_offset   x30, -8
.cfi_endproc
```

`Llanding_pad` 是阶段二将要安装的上下文入口；自行改 prologue/epilogue 或 hook 而缺少 CFI 时，展开可能在该帧终止。

一些常见误区澄清（踩坑复盘）

- "`std::is_base_of` 为 true 就一定能被基类 catch 住"——错。模板在编译期判定继承，运行期匹配依赖 `type_info` 指针相等（默认实现）。
- "名字相同就行"——错。除非启用名字比较实现或命中非唯一 RTTI 的回退路径，否则只比地址。
- "我没直接用到那个目标文件，怎么也会影响"——对，因为只要有 `throw`/`catch` 涉及该类型，编译器就可能为它生成本地 `type_info`，即便代码路径不被调用。
- "把可见性设默认应该能合并吧"——未必。`-fno-rtti` 生成的 `type_info` 常被标记为本地/隐藏，不参与去重；细节见附录。
- "`std::type_index` 在容器中当 Key 就没事了吧"——错！ `std::type_index` 内部包装的就是 `type_info` 指针。污染后，同一类型的不同 `type_info` 实例会产生不等价的 `type_index`，导致在 `std::map<std::type_index, ...>` 或 `std::unordered_map` 中出现"重复"的键，破坏类型注册表等设计模式。

`std::type_index` 污染的实际影响

`std::type_index` 是 `std::type_info` 的包装器，常用于在关联容器中以类型作为键：

```cpp
#include <typeindex>
#include <unordered_map>
#include <iostream>

// 工厂模式示例：类型注册表
std::unordered_map<std::type_index, std::function<void*()>> factory;

void register_type() {
    factory[std::type_index(typeid(std::runtime_error))] = []() -> void* {
        return new std::runtime_error("factory created");
    };
}

void* create(const std::type_info& type) {
    auto it = factory.find(std::type_index(type));
    if (it != factory.end()) {
        return it->second();
    }
    return nullptr;
}

int main() {
    register_type();
    
    // 在污染场景下，这里的 typeid(std::runtime_error) 
    // 可能与 register_type() 中的地址不同
    void* obj = create(typeid(std::runtime_error));
    
    if (obj == nullptr) {
        std::cout << "查找失败！type_index 不匹配" << std::endl;
        // 打印容器内容，会看到"重复"的 runtime_error 条目
        for (auto& [idx, func] : factory) {
            std::cout << "  注册类型: " << idx.name() << std::endl;
        }
    }
}
```

污染后的后果是同一类型的不同 `type_info*` 产生不同的 `type_index`，容器中出现名称相同但 hash 值不同的"重复"键，查找失败，工厂模式、插件系统、序列化框架等依赖类型索引的机制失效，`type_index` 的 `operator==` 和 `hash()` 都基于 `type_info*` 地址（而非名称）。

诊断方法

```cpp
// 在不同编译单元检查 type_index 的一致性
std::type_index idx1(typeid(T));
std::type_index idx2(typeid(T));
assert(idx1 == idx2);  // 污染时可能失败！

// 打印 hash 值
std::cout << "hash: " << idx1.hash_code() << std::endl;
```

解决方式是与异常处理相同——统一 RTTI 配置，或启用名字比较回退。

异常规范与 `std::terminate` 触发机制

异常规范违反、未捕获异常、析构函数抛出等都会触发 `std::terminate`。type_info 污染会让本该捕获的异常变成"未捕获"。

异常规范的演进

C++ 异常规范经历了重大演进，从动态规范到 `noexcept`：

```cpp
// C++98: 动态异常规范（已废弃）
void old_style() throw(std::runtime_error, std::logic_error) {
    // 只能抛出声明的异常类型
}

// C++11/17: noexcept 规范（推荐）
void new_style() noexcept {
    // 不应抛出任何异常
}

// C++17: noexcept 带条件
template<typename T>
void conditional() noexcept(std::is_nothrow_copy_constructible_v<T>) {
    T obj;
}
```

为什么废弃动态异常规范？

- 运行时开销：需要在运行时检查抛出的异常类型是否在规范中
- 类型匹配问题：检查时依赖 `type_info` 比较——正是本文讨论的痛点！
- 组合复杂：模板、继承、虚函数的组合下，规范难以正确维护

```cpp
// 动态异常规范的底层实现（简化）
void func() throw(std::runtime_error) {
    // 编译器生成的伪代码：
    try {
        // 函数实际代码
        actual_function_body();
    } catch (...) {
        // 检查异常类型是否在规范中
        std::type_info* thrown = __cxa_current_exception_type();
        if (thrown == &typeid(std::runtime_error)) {
            throw;  // 允许的类型，重新抛出
        } else {
            std::unexpected();  // 不允许的类型，调用 unexpected
        }
    }
}
```

type_info 污染影响表现在如果 `thrown == &typeid(std::runtime_error)` 因地址不一致而返回 `false`，即使抛出的确实是 `std::runtime_error`，也会触发 `std::unexpected`！

`std::terminate` 的触发条件是什么？

根据 Itanium C++ ABI 和 C++ 标准，以下情况会调用 `std::terminate`：

1. 未捕获异常：
```cpp
void no_catch() {
    throw std::runtime_error("uncaught");
    // 没有 catch，程序终止
}
```

2. `noexcept` 函数抛出异常：
```cpp
void strict() noexcept {
    throw std::exception();  // 立即 std::terminate
}
```

3. 析构函数在栈展开期间抛出异常：
```cpp
struct Bad {
    ~Bad() noexcept(false) {  // 显式允许抛出（不推荐）
        throw std::exception();
    }
};

void dangerous() {
    Bad b1;
    Bad b2;
    throw std::runtime_error("first");  
    // b2、b1 析构时若再抛出，触发 terminate
}
```

4. 异常处理机制内部错误：
   - Phase 1 或 Phase 2 返回 `_URC_FATAL_PHASE*_ERROR`
   - personality function 崩溃
   - LSDA 损坏或缺失

5. `std::unexpected` 抛出不允许的异常（C++17 前）

type_info 污染的触发情况

```cpp
try {
    throw std::runtime_error("test");
} catch (const std::exception& e) {
    // 如果因 type_info 污染而未匹配
    // 异常"穿透" catch，成为"未捕获异常"
    // 触发 std::terminate
}
```

可以自定义 terminate handler 来记录诊断信息：

```cpp
#include <exception>
#include <iostream>
#include <cstdlib>

void my_terminate_handler() {
    std::cerr << "=== std::terminate 被调用 ===" << std::endl;
    
    // 尝试获取当前异常信息
    std::exception_ptr eptr = std::current_exception();
    if (eptr) {
        try {
            std::rethrow_exception(eptr);
        } catch (const std::exception& e) {
            std::cerr << "未捕获异常: " << e.what() << std::endl;
            std::cerr << "类型: " << typeid(e).name() << std::endl;
            
            // 输出 type_info 地址以诊断污染
            std::cerr << "type_info 地址: " << &typeid(e) << std::endl;
        } catch (...) {
            std::cerr << "未知异常类型" << std::endl;
        }
    } else {
        std::cerr << "无当前异常（可能是 noexcept 违反）" << std::endl;
    }
    
    std::abort();  // 或其他清理操作
}

int main() {
    std::set_terminate(my_terminate_handler);
    
    // 测试代码...
}
```

建议

- 在程序启动时设置自定义 terminate handler
- 记录关键诊断信息（异常类型、type_info 地址、调用栈）
- 在 iOS/Android 上，发送到崩溃报告系统
- 重要：handler 本身必须 `noexcept`，否则会递归调用 `std::terminate`

Itanium C++ ABI 定义了如何处理非 C++ 异常（foreign exceptions）。

每个 C++ 异常对象都有一个"异常类别"标识（exception class），C++ 异常的标识为 `"GNUCC++\0"`（或类似值）。

```cpp
// libcxxabi 中的判断（简化）
bool is_cxx_exception(const _Unwind_Exception* unwind_exception) {
    return unwind_exception->exception_class == kOurExceptionClass;
}
```

处理的策略是在阶段一搜索时 C++ personality 通常忽略 foreign exception，返回 `_URC_CONTINUE_UNWIND`。

阶段二清理时执行 C++ 对象的析构，但不进入 catch 块。

最后 foreign exception 穿过 C++ 代码，由其原始语言的机制处理。

Foreign exception 不涉及 `type_info` 匹配，因此不受污染影响，但如果混用 C++ 和 Objective-C 异常，需特别注意边界。

Objective-C 互操作示例

```cpp
// .mm 文件
#include <exception>
#import <Foundation/Foundation.h>

void cpp_to_objc_bridge() {
    @try {
        try {
            throw std::runtime_error("C++ exception");
        } catch (const std::exception& e) {
            // 转换为 NSException
            @throw [NSException exceptionWithName:@"CppException"
                                           reason:[NSString stringWithUTF8String:e.what()]
                                         userInfo:nil];
        }
    } @catch (NSException* ex) {
        NSLog(@"Caught: %@", ex);
    }
}
```

最佳实践是

- C++ 异常不要穿越 C 函数或非 C++ 边界
- 在边界处使用 `noexcept` 或显式捕获并转换
- 记录边界穿越的异常以便诊断

C++ 异常被称为"零成本"（Zero-cost），指正常路径（无抛出）几乎无开销，代价集中在抛出路径。传统方法（setjmp/longjmp）是在 try 入口设置跳转点，正常路径需保存/恢复上下文，开销显著。表驱动（Itanium 风格）是编译器在 LSDA/DWARF 中记录异常处理信息，正常路径无额外指令；抛出时由 libunwind 读表回溯。

更多零成本异常内容可以参看

- 零成本异常的权衡分析：[Zero-cost Exception Handling (Hubička)](https://www.ucw.cz/~hubicka/papers/abi/node25.html)
- LLVM 官方文档：[Exception Handling in LLVM](https://llvm.org/docs/ExceptionHandling.html)

零成本的"成本"在于：

- 二进制膨胀：每个可能抛出的函数需 LSDA 表项；多层嵌套 try 会增大表；启用 `-fexceptions` 比 `-fno-exceptions` 通常增加 10-20% 二进制大小。
- 抛出延迟：栈展开需遍历调用栈、解析 LSDA、调用 personality、执行析构；深层嵌套可能数十微秒至毫秒。
- 指令 Cache：LSDA/personality 代码路径冷，首次抛出可能 Cache Miss。

你可以构造 N 层函数调用（如 N=10/50/100），在最深层抛出，测量到达 catch 的时间；对比 `-O2` 与 `-O3 -flto`、不同深度的影响。

了解异常安全等级与 RAII 有助于设计抗"污染"的边界。

- 无抛出保证（No-throw / noexcept）：函数不抛异常；若抛出则 `std::terminate`；最安全的边界。
- 强保证（Strong）：操作要么完全成功，要么回滚到操作前状态；依赖 RAII 与两阶段提交。
- 基本保证（Basic）：不泄漏资源、对象保持有效状态，但状态可能改变。
- 无保证：可能泄漏/损坏。

在跨模块/动态库边界，建议公开 API 采用 `noexcept` 或错误码。内部实现用异常处理，在边界转换。避免让异常穿越"污染"风险区（不同 RTTI 配置的模块）。

Address Sanitizer (ASan)、UndefinedBehavior Sanitizer (UBSan) 等工具与异常处理有微妙交互（参见 [AddressSanitizer](https://github.com/google/sanitizers/wiki/AddressSanitizer) 和 [UndefinedBehaviorSanitizer](https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html)）：

- ASan shadow memory：栈展开时，ASan 需同步"毒化"被析构对象的内存；若 LSDA 缺失或 CFI 损坏，ASan 可能误报。
- UBSan 与 RTTI：UBSan 的 vptr 检查依赖完整 RTTI；`-fno-rtti` 后 vptr 检查可能失效或误报。
- TSan：多线程抛异常时，TSan 监控 TLS exception buffer 的互斥；竞态可能触发 TSan 警告。

调试建议：
- 若在 Sanitizer 下异常捕获失败，先排除是否为工具本身的 false positive；
- 使用 `ASAN_OPTIONS=halt_on_error=0` 继续运行，观察后续行为；
- 对比无 Sanitizer 构建，确认是否为 RTTI 污染。

跨语言边界的异常处理（C/Rust/Swift/ObjC）

- C 与 C++：C 无异常机制；C++ 异常不可穿越 C 函数（除非 C 函数用 `extern "C"` 且明确不做任何可能异常的操作）；建议在 C++ → C 边界捕获并转换为错误码。
- Rust 与 C++：Rust panic 与 C++ 异常不兼容；FFI 边界需用 `std::panic::catch_unwind` 或 `extern "C"` + 错误码。
- Swift 与 C++/ObjC：Swift 的 `throw` 编译为类似 ObjC 异常（某些场景）或错误返回；与 C++ 异常互不兼容；桥接需显式转换。
- Objective-C 与 C++：`.mm` 文件可混编，但 `@try/@catch` 捕获 `NSException`，与 C++ 异常独立；需 `-fobjc-exceptions` 且避免混抛。

最佳实践：
- 边界函数标记 `noexcept` 或 `extern "C"`；
- 内部用异常，边界转为 `Result<T,E>` / `std::expected` / `NSError**`；
- 明确文档标注"不可跨边界抛出"。

`std::nested_exception` 用于在捕获一个异常后抛出另一个异常，同时保留原始异常信息，形成"异常链"：

```cpp
#include <exception>
#include <stdexcept>
#include <iostream>

void level1() {
    throw std::runtime_error("底层错误");
}

void level2() {
    try {
        level1();
    } catch (...) {
        std::throw_with_nested(std::logic_error("中间层处理失败"));
    }
}

void print_exception(const std::exception& e, int level = 0) {
    std::cerr << std::string(level, ' ') << e.what() << '\n';
    try {
        std::rethrow_if_nested(e);
    } catch (const std::exception& nested) {
        print_exception(nested, level + 2);
    }
}

int main() {
    try {
        level2();
    } catch (const std::exception& e) {
        print_exception(e);
    }
}
```

输出：
```
中间层处理失败
  底层错误
```

`std::throw_with_nested` 的简化实现：

```cpp
template<typename T>
[[noreturn]] void throw_with_nested(T&& t) {
    if constexpr (std::is_class_v<std::decay_t<T>> && 
                  !std::is_final_v<std::decay_t<T>>) {
        // 创建多继承类，既是 T 又是 nested_exception
        struct Nested : std::decay_t<T>, std::nested_exception {
            explicit Nested(T&& t) : std::decay_t<T>(std::forward<T>(t)) {}
        };
        throw Nested(std::forward<T>(t));
    } else {
        throw std::forward<T>(t);
    }
}
```

`Nested` 是动态生成的多继承类型，包含用户抛出的类型 `T`，`std::nested_exception`（持有 `std::exception_ptr`）。

若 `T` 的 `type_info` 被污染（如 `std::logic_error`），基类 catch 可能失败。`std::nested_exception` 本身也有 `type_info`，若被污染，`std::rethrow_if_nested` 的 `dynamic_cast` 可能失败。

```cpp
void std::rethrow_if_nested(const std::exception& e) {
    // dynamic_cast 依赖 RTTI
    if (auto* nested = dynamic_cast<const std::nested_exception*>(&e)) {
        nested->rethrow_nested();
    }
}
```

混用 `-frtti` 与 `-fno-rtti` 时，`dynamic_cast` 可能因 `type_info*` 不一致而返回 `nullptr`，导致异常链断裂。

建议统一 RTTI 配置，否则 `std::nested_exception` 不可靠。在关键边界记录完整异常链（序列化为字符串）而非依赖运行时类型转换。若必须跨"污染"边界，使用自定义异常基类 + 手动链表而非 `std::nested_exception`。

为了溯源下面是代码出处速览：

- `__cxa_throw`：`libcxxabi/src/cxa_exception.cpp`
- `__gxx_personality_v0` 与 LSDA 解析：`libcxxabi/src/cxa_personality.cpp`
- `__cxa_can_catch` 与 `__class_type_info::__do_catch`：`libcxxabi/src/private_typeinfo.cpp`
- `type_info::operator==`：`libcxx/include/typeinfo`
- Clang 生成 RTTI 的逻辑：`clang/lib/CodeGen/ItaniumCXXABI.cpp`

回到主线：以上原理可归结为“类型匹配基于指针、工程导致指针分裂”。下面把结论收束为可执行的工程方案。

## 如何解决

理解了问题的前因后果，现在到了最实际的环节：如何解决？根据前面的分析，我们已经明确了问题根源——混用编译选项导致的 type_info 污染。解决方案也呼之欲出：要么统一配置，要么改比较方式，要么绕过基类匹配。

混用 `-frtti` 和 `-fno-rtti` 导致多份 `type_info`，指针比较失败。解决方案自然就清楚了：要么统一配置，要么改比较方式，要么绕过基类匹配。

决策树

```
发现异常捕获失败？
    ↓
【快速验证】
用具体类型 catch 能接住吗？
    ├─ 不能 → 不是本文问题，检查其他原因（继承关系、异常规范等）
    └─ 能接住 → 确认是 type_info 污染
        ↓
【场景判断】
项目对二进制大小非常敏感吗？（嵌入式/IoT）
    ├─ 不敏感（99% 的项目）
    │   └─ 方案1：统一启用 RTTI
    │       优势：最安全，一劳永逸
    │       代价：增加 5-10% 体积
    │       
    └─ 体积敏感
        ↓
        能否完全不用异常？
        ├─ 可以
        │   └─ 方案2：禁用 RTTI + 异常
        │       优势：体积最小
        │       代价：需改用错误码
        │       
        └─ 必须用异常
            ↓
            能接受少量性能损失吗？
            ├─ 可以（推荐）
            │   └─ 方案3：启用名字比较回退
            │       优势：兼容混配
            │       代价：字符串比较开销
            │       
            └─ 不能（不推荐）
                └─ 方案4：具体类型捕获
                    优势：局部修复
                    代价：代码改动大，破坏多态
```

### 统一启用 RTTI

这是最简单且最安全的方案。移除所有 `-fno-rtti` 编译选项，统一使用默认的 RTTI 配置。

```bash
# 所有模块都启用 RTTI
clang++ -std=c++17 -frtti -c main.cpp -o main.o
clang++ -std=c++17 -frtti -c no_rtti_lib.cpp -o no_rtti_lib.o
clang++ -std=c++17 main.o no_rtti_lib.o -o program
```

这个方案优点是彻底解决问题，无副作用。缺点是 RTTI 会增加二进制大小（通常增加 5-10%）

### 同时禁用 RTTI 和异常

如果确实需要减小二进制大小，可以同时禁用 RTTI 和异常处理：

```bash
clang++ -std=c++17 -fno-rtti -fno-exceptions -c module.cpp -o module.o
```

优点是大幅减小二进制大小，缺点是无法使用异常处理机制，需要使用错误码等替代方案。

### 修改 type_info 比较实现

通过编译选项强制使用名字比较而非指针比较：

```bash
clang++ -std=c++17 -D_LIBCPP_TYPEINFO_COMPARISON_IMPLEMENTATION=2 \
    -fno-rtti -c no_rtti_lib.cpp -o no_rtti_lib.o
```

先比较指针（快速路径），再比较名字（回退路径），这种方案优点是可以在禁用 RTTI 的同时保持异常处理正常工作。缺点是性能略有下降（字符串比较开销），需要在所有编译单元中统一设置，不是所有标准库实现都支持这个宏。

### 使用具体类型捕获

如果只在特定位置出现问题，可以修改代码使用具体类型捕获：

```cpp
try {
    throw std::runtime_error("测试异常");
} catch (const std::runtime_error& e) {  // 使用具体类型
    // 处理异常
} catch (const std::exception& e) {      // 回退处理
    // 其他异常
}
```

优点是局部修复，不需要修改编译选项，缺点是需要修改大量代码，违反多态原则。

过渡：有了策略，我们再看真实项目如何触发、如何排查与验证修复是否生效。

## 案例

理论和解决方案都有了，现在看看实际项目中会遇到什么情况。

与主题的关联：下面的场景与清单，都围绕“哪一步制造/隐藏了多份 `type_info`，或让展开走不到匹配点”来组织，便于对号入座。

### 大项目常见场景

在大型 iOS/Android 项目中，这个问题特别容易出现：

- CocoaPods/第三方库：某些第三方库为了减小体积使用 `-fno-rtti`
- 模块化编译：不同模块使用不同的编译选项
- 动静态库混用：动态库禁用 RTTI，主程序启用 RTTI

例如 MMKV（知名的键值存储库）就曾遇到这个问题（[GitHub Issue #744](https://github.com/Tencent/MMKV/issues/744)）。

### 诊断检测方法

当遇到疑似此类问题时，可以按以下步骤诊断：

```cpp
try {
    throw std::runtime_error("test");
} catch (const std::runtime_error& e) {  // 具体类型
    std::cout << "Caught by runtime_error" << std::endl;
} catch (const std::exception& e) {      // 基类
    std::cout << "Caught by exception" << std::endl;
}
```

如果第一个 catch 执行，说明是 `type_info` 地址不一致问题。

检查编译选项

```bash
# 查找所有使用 -fno-rtti 的地方
grep -r "fno-rtti" .
```

分析符号表

```bash
# 查找重复的 type_info（同名但地址不同）
nm -C program | grep "typeinfo for" | sed -E 's/^[0-9a-f ]* [a-zA-Z] //' | sort | uniq -c | awk '$1 > 1'
```

使用调试器

```cpp
// 在 catch 块前设置断点，比较地址
const std::type_info& thrown_type = typeid(std::runtime_error);
const std::type_info& catch_type = typeid(std::exception);
std::cout << &thrown_type << " vs " << &catch_type << std::endl;
```

避免的配置

- 混用 `-frtti` 和 `-fno-rtti`
- 只在部分模块禁用 RTTI
- 使用 `-fvisibility=hidden` 隐藏 `type_info` 符号

Xcode/Pods 构建设置对照

- `OTHER_CPLUSPLUSFLAGS`：检查是否混入 `-frtti`/`-fno-rtti`、`-fno-exceptions`。
- `GCC_ENABLE_CPP_EXCEPTIONS`：应为 YES；与上项保持一致。
- `GCC_SYMBOLS_PRIVATE_EXTERN`（Symbols Hidden by Default）：为 YES 时更易形成局部符号；谨慎配合 RTTI/异常使用。
- `OTHER_LDFLAGS`：关注 `-dead_strip`、`-force_load` 等；不当裁剪可能影响异常元数据的保留。
- CocoaPods：留意不同 Pod target 的 flags 是否统一；必要时在 `post_install` 钩子里强制对齐。

诊断清单

- 先做"能否用具体类型接住"的对照用例；若能接住而基类接不住，八成是 `type_info` 地址问题。
- 搜索工程：`grep -r "-fno-rtti\|-fno-exceptions"`，核对各 target 统一性。
- 看符号表：`nm -C binary | grep "typeinfo for" | sed -E 's/^[0-9a-f ]* [a-zA-Z] //' | sort | uniq -c | awk '$1 > 1'`，是否同一类型出现多个实例。
- 看可见性：`nm -m binary | grep typeinfo` 或 `objdump -t`，排查 local/hidden 符号来源。
- 看展开信息：`otool -l binary | grep -A2 __unwind_info`，确认存在；手写汇编需补全 CFI。

使用 GDB 脚本、clang-tidy 规则、dtrace 等工具实现自动化诊断和实时追踪。

在调试器中自动比较多个 type_info 地址，无需手动逐个检查。

```gdb
# typeinfo_check.gdb
# 用法：gdb -x typeinfo_check.gdb ./your_binary

define check_typeinfo
    set $type_name = $arg0
    
    # 在不同编译单元取地址
    printf "Checking type_info for: %s\n", $type_name
    
    # 方法 1：直接比较符号
    info address $type_name
    
    # 方法 2：运行时获取（需要运行到某个点）
    if $_isvoid($__cxa_current_exception_type)
        printf "  [WARN] Not in exception context\n"
    else
        set $thrown_type = __cxa_current_exception_type()
        printf "  Thrown type addr: %p\n", $thrown_type
    end
end

# 使用示例
break main
run
check_typeinfo "typeinfo for std::runtime_error"

# 高级：批量检查
define check_common_types
    check_typeinfo "typeinfo for std::exception"
    check_typeinfo "typeinfo for std::runtime_error"
    check_typeinfo "typeinfo for std::logic_error"
end
```

跨模块比较

```python
# typeinfo_diff.py - GDB Python 脚本
import gdb

class TypeInfoChecker(gdb.Command):
    """Check type_info consistency across modules"""
    
    def __init__(self):
        super(TypeInfoChecker, self).__init__(
            "check-typeinfo", gdb.COMMAND_USER
        )
    
    def invoke(self, arg, from_tty):
        type_name = arg.strip()
        if not type_name:
            print("Usage: check-typeinfo <typename>")
            return
        
        # 搜索所有匹配的符号
        symbol_name = f"typeinfo for {type_name}"
        results = gdb.execute(
            f"info symbol '{symbol_name}'", 
            to_string=True
        )
        
        addresses = set()
        for line in results.split('\n'):
            if symbol_name in line:
                # 解析地址
                parts = line.split()
                if len(parts) > 0:
                    addr = parts[0]
                    addresses.add(addr)
                    print(f"  Found: {addr} - {line}")
        
        # 检测重复
        if len(addresses) > 1:
            print(f"WARNING: {len(addresses)} different addresses found!")
            print(f"   This indicates type_info pollution!")
        elif len(addresses) == 1:
            print(f"OK: Unique type_info found")
        else:
            print(f"No type_info found (may be stripped)")

TypeInfoChecker()
```

使用方式

```bash
gdb ./your_binary
(gdb) source typeinfo_diff.py
(gdb) check-typeinfo std::runtime_error
```

构建时静态检查（clang-tidy 自定义规则），在编译时警告混用 RTTI 配置。

第一种方法是使用 clang-tidy 的 misc-definitions-in-headers。

```yaml
# .clang-tidy
Checks: '-*,misc-definitions-in-headers,readability-*'
CheckOptions:
  - key: misc-definitions-in-headers.UseHeaderFileExtension
    value: true
```

第二种方法是自定义编译后检查脚本。

```python
#!/usr/bin/env python3
# check_rtti_consistency.py

import subprocess
import sys
import re
from collections import defaultdict

def check_object_file(obj_file):
    """检查单个 .o 文件的 type_info 符号"""
    try:
        result = subprocess.run(
            ['nm', '-C', obj_file],
            capture_output=True, text=True, check=True
        )
        
        typeinfo_symbols = {}
        for line in result.stdout.split('\n'):
            if 'typeinfo for' in line:
                parts = line.split()
                if len(parts) >= 3:
                    symbol_type = parts[1]  # U, S, T, etc.
                    symbol_name = ' '.join(parts[2:])
                    typeinfo_symbols[symbol_name] = symbol_type
        
        return typeinfo_symbols
    except subprocess.CalledProcessError:
        return {}

def check_project(obj_files):
    """检查整个项目的 type_info 一致性"""
    # 收集所有 type_info
    all_symbols = defaultdict(list)
    
    for obj_file in obj_files:
        symbols = check_object_file(obj_file)
        for name, stype in symbols.items():
            all_symbols[name].append((obj_file, stype))
    
    # 检测不一致
    issues = []
    for name, occurrences in all_symbols.items():
        types = set(t for _, t in occurrences)
        
        # 如果同一 type_info 有 U (undefined) 和 S (local)
        if 'U' in types and 'S' in types:
            issues.append({
                'type': name,
                'problem': 'Mixed U and S symbols',
                'files': occurrences
            })
        # 如果有多个 S (多个本地副本)
        elif len([t for t in types if t.lower() == 's']) > 1:
            issues.append({
                'type': name,
                'problem': 'Multiple local symbols',
                'files': occurrences
            })
    
    return issues

def main():
    import glob
    
    # 查找所有 .o 文件
    obj_files = glob.glob('**/*.o', recursive=True)
    
    print(f"Checking {len(obj_files)} object files...")
    issues = check_project(obj_files)
    
    if issues:
        print(f"\nFound {len(issues)} potential RTTI pollution issues:\n")
        for issue in issues:
            print(f"Type: {issue['type']}")
            print(f"Problem: {issue['problem']}")
            print("Affected files:")
            for file, stype in issue['files']:
                print(f"  [{stype}] {file}")
            print()
        sys.exit(1)
    else:
        print("✅ No RTTI pollution detected")
        sys.exit(0)

if __name__ == '__main__':
    main()
```

集成到 CMake

```cmake
# CMakeLists.txt
add_custom_target(check-rtti
    COMMAND python3 ${CMAKE_SOURCE_DIR}/scripts/check_rtti_consistency.py
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    COMMENT "Checking RTTI consistency..."
)

# 添加到默认构建目标
add_dependencies(all check-rtti)
```

第三种方法运行时动态追踪（dtrace / eBPF）

实时监控异常抛出和 type_info 比较，无需修改代码。

macOS / iOS (dtrace)

```d
#!/usr/sbin/dtrace -s
# exception_trace.d
# 用法：sudo dtrace -s exception_trace.d -p <PID>

/* 追踪 __cxa_throw */
pid$target::__cxa_throw:entry
{
    self->exception_type = arg1;  /* type_info* */
    printf("=== Exception Thrown ===\n");
    printf("  type_info*: %p\n", arg1);
    printf("  thread: %d\n", tid);
    ustack();
}

/* 追踪 type_info 比较 */
pid$target::*type_info*operator*:entry
/self->exception_type/
{
    printf("  type_info::operator== called\n");
    printf("    this: %p, rhs: %p\n", arg0, arg1);
    printf("    result: %s\n", arg0 == arg1 ? "EQUAL" : "NOT EQUAL");
}

/* 追踪 __cxa_can_catch */
pid$target::__cxa_can_catch:entry
{
    printf("=== __cxa_can_catch ===\n");
    printf("  catchType: %p\n", arg0);
    printf("  excpType:  %p\n", arg1);
}

pid$target::__cxa_can_catch:return
{
    printf("  result: %s\n", arg1 ? "CAN CATCH" : "CANNOT CATCH");
}
```

Linux (bpftrace)

```bash
#!/usr/bin/env bpftrace
# exception_trace.bt
# 用法：sudo bpftrace exception_trace.bt -p <PID>

uprobe:/lib/x86_64-linux-gnu/libc++abi.so:__cxa_throw
{
    $type_info = arg1;
    printf("=== Exception Thrown ===\n");
    printf("  type_info*: %p\n", $type_info);
    printf("  PID/TID: %d/%d\n", pid, tid);
    printf("  Stack:\n%s\n", ustack);
}

uprobe:/lib/x86_64-linux-gnu/libc++abi.so:__cxa_can_catch
{
    printf("=== Type Matching ===\n");
    printf("  catchType: %p\n", arg0);
    printf("  excpType:  %p\n", arg1);
}

uretprobe:/lib/x86_64-linux-gnu/libc++abi.so:__cxa_can_catch
{
    printf("  match result: %d\n", retval);
}
```

输出

```
=== Exception Thrown ===
  type_info*: 0x7ffff7a12340
  thread: 12345

=== __cxa_can_catch ===
  catchType: 0x7ffff7b23450  ← 不同地址！
  excpType:  0x7ffff7a12340
  result: CANNOT CATCH    ← 匹配失败

=== std::terminate called ===
```

第四种方法是符号差异可视化

```bash
#!/bin/bash
# visualize_typeinfo_diff.sh
# 生成 HTML 报告展示 type_info 差异

BINARY=$1
OUTPUT="typeinfo_report.html"

cat > $OUTPUT << 'EOF'
<!DOCTYPE html>
<html>
<head><title>type_info Analysis</title>
<style>
  .duplicate { background-color: #ffcccc; }
  .ok { background-color: #ccffcc; }
  table { border-collapse: collapse; width: 100%; }
  td, th { border: 1px solid #ddd; padding: 8px; }
</style>
</head>
<body>
<h1>type_info Symbol Analysis</h1>
<table>
<tr><th>Type Name</th><th>Count</th><th>Addresses</th><th>Status</th></tr>
EOF

nm -C "$BINARY" | grep "typeinfo for" | \
  sed -E 's/^([0-9a-f ]*) ([a-zA-Z]) (.*)$/\2 \1 \3/' | \
  sort -k3 | \
  awk '
    { types[$3]++; addrs[$3] = addrs[$3] " " $2 }
    END {
      for (type in types) {
        count = types[type];
        class = count > 1 ? "duplicate" : "ok";
        status = count > 1 ? "DUPLICATE" : "OK";
        print "<tr class=\"" class "\">";
        print "<td>" type "</td>";
        print "<td>" count "</td>";
        print "<td>" addrs[type] "</td>";
        print "<td>" status "</td>";
        print "</tr>";
      }
    }
  ' >> $OUTPUT

cat >> $OUTPUT << 'EOF'
</table>
</body>
</html>
EOF

echo "Report generated: $OUTPUT"
open $OUTPUT  # macOS
# xdg-open $OUTPUT  # Linux
```

完整的 CI 检查流程

```yaml
# .github/workflows/rtti-check.yml
name: RTTI Consistency Check

on: [push, pull_request]

jobs:
  check-rtti:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Build
        run: |
          cmake -B build
          cmake --build build
      
      - name: Static Check
        run: |
          python3 scripts/check_rtti_consistency.py
      
      - name: Symbol Analysis
        run: |
          ./scripts/visualize_typeinfo_diff.sh build/your_binary
      
      - name: Upload Report
        if: failure()
        uses: actions/upload-artifact@v2
        with:
          name: typeinfo-report
          path: typeinfo_report.html
```

这样就可以自动化发现 type_info 污染，在 CI 中提前预警，实时追踪异常处理流程并生成可视化报告辅助排查。

### 真机问题

iOS 真机上 type_info 符号可能因 Strip、Hidden Visibility、App Store 优化等原因完全缺失或不一致，问题比模拟器更隐蔽。

与主题的关联：真机上的可见性/裁剪策略更易制造或隐藏多份 `type_info`，因此更容易出现“只认地址”的未命中，需要与模拟器构建分别核对。

在 iOS 真机上，`type_info` 符号的问题比模拟器更加隐蔽且严重。真机（arm64）有更激进的优化（App Store 构建），更严格的符号管理，Release 配置的特殊设置（Strip、Dead Code Stripping），问题更容易暴露且难以调试。

iOS 编译时可能使用了 `-fvisibility=hidden`，导致 `type_info` 符号变为私有。

验证方法

```bash
# 查看所有符号（包括私有）
nm -a try_catch_demo | grep runtime_error

# 查看 mach-o 符号表
otool -I -v try_catch_demo | grep runtime_error

# 使用 dyldinfo 查看导出符号
dyldinfo -export try_catch_demo | grep runtime_error
```

可能输出

```
# 符号存在但被标记为 private external
0000000100004000 (__DATA,__const) external (was private external) _ZTISt13runtime_error
```

符号被 Strip。Release 构建可能使用了 `-Wl,-dead_strip` 或 `-Wl,-x`，移除了"未使用"的符号。

检查编译选项

```bash
# 查看链接器选项
xcodebuild -showBuildSettings | grep STRIP
xcodebuild -showBuildSettings | grep DEAD_CODE_STRIPPING
```

常见设置

```
DEAD_CODE_STRIPPING = YES
STRIP_STYLE = non-global
```

虽然 `type_info` 在运行时会被使用，但链接器的静态分析可能认为它"未使用"，特别是当函数从未被调用时（如 `never_called_function()`）。

真机诊断场景

场景一：符号完全缺失

```bash
$ nm -C try_catch_demo | grep "typeinfo for std::runtime_error"
# 没有输出！
```

可能被 strip 了或 hidden visibility，也可能完全来自系统库。运行时异常可能穿透 catch 块，程序崩溃。

场景二：只有未定义符号

```bash
$ nm -C try_catch_demo | grep "typeinfo for std::runtime_error"
                 U typeinfo for std::runtime_error
```

原因是本地生成的被优化掉了，或只保留了引用，或者运行时从系统库加载。

运行时行为为通常会正常工作（所有引用指向系统库的同一实例）。

场景三：符号隐藏（最隐蔽）

```bash
$ nm -C try_catch_demo | grep "typeinfo for std::runtime_error"
# 没有输出

$ nm -a -C try_catch_demo | grep "typeinfo for std::runtime_error"
0000000100004000 (__DATA,__const) private external _ZTISt13runtime_error
```

问题是符号存在但被标记为 private，外部看不到但内部可能有多个实例，这样问题被掩盖，难以诊断。

真机专用调试技巧，使用 lldb 运行时检查。

```bash
lldb try_catch_demo

(lldb) b main
(lldb) run
(lldb) p &typeid(std::runtime_error)
# 输出地址 A

# 在异常处理代码处断点
(lldb) b main.cpp:10
(lldb) c
(lldb) p &typeid(e)
# 输出地址 B

# 比较两个地址是否一致
```

还可以使用 dtrace 追踪。

```bash
# 追踪 type_info 相关的函数调用
sudo dtrace -n 'pid$target::*type_info*:entry { printf("%s", probefunc); }' -p <pid>
```

对比真机和模拟器构建产物

```bash
# 模拟器
nm -C Build/Simulator/app.app/app | grep typeinfo > sim_symbols.txt

# 真机
nm -C Build/Device/app.app/app | grep typeinfo > device_symbols.txt

# 对比差异
diff sim_symbols.txt device_symbols.txt
```

## 异常相关

本节为附录：收录与本主题强相关的命令清单与检查要点，用于快速定位“地址不一致”的来源与落点，辅助主线排查。

### 符号

以下命令与输出形态，可以帮助定位是否存在本地/隐藏的 `type_info` 实例与地址不一致。

查看各目标内的 typeinfo 符号。

```bash
nm -C main.o | grep "typeinfo for"
nm -C no_rtti_lib.o | grep "typeinfo for"
nm -C try_catch_demo | grep "typeinfo for std::runtime_error"
```

```bash
# 检查模块接口中的 type_info 符号
nm -C module.o | grep "typeinfo for"

# 对比模块与非模块编译单元的符号
nm -C traditional.o | grep typeinfo > traditional.txt
nm -C modular.o | grep typeinfo > modular.txt
diff traditional.txt modular.txt
```

输出解读

- `U typeinfo for std::runtime_error`：未定义符号，链接期期待从标准库解析（健康）。
- `S typeinfo for std::runtime_error` 或本地小写 `s`：本地/私有符号，意味着该目标内自生成副本（需警惕）。

查看可见性与段信息

```bash
nm -m try_catch_demo | grep typeinfo
objdump -t no_rtti_lib.o | grep runtime_error
```

若可见性为 `private extern`/`hidden`，跨镜像无法合并，易形成多份 `type_info`。

链接裁剪的影响

```bash
otool -l try_catch_demo | grep -A2 __unwind_info
```

确认存在异常展开元数据；若结合 `-Wl,-dead_strip` 使用，注意不可达路径的处理器和类型表可能被裁剪。

一步到位的排查脚本示例：

```bash
#!/usr/bin/env bash
set -euo pipefail

BIN="$1"  # 可执行或静态/动态库

echo "[flags suspect]"
grep -R "-fno-rtti\|-fno-exceptions" --include='*.xcconfig' --include='Podfile*' --include='*.podspec' . || true

echo "\n[typeinfo duplicates]"
nm -C "$BIN" | grep "typeinfo for" | sed -E 's/^[0-9a-f ]* [a-zA-Z] //' | sort | uniq -c | sort -nr | head -50

echo "\n[visibility hints]"
nm -m "$BIN" | grep typeinfo | head -50 || true

echo "\n[unwind info present?]"
otool -l "$BIN" | grep -A2 __unwind_info || true
```

用法：`bash tools/check_eh.sh <your_binary>`


### RTTI 的成本

与主题的关联：成本评估帮助你在“统一启用 RTTI / 名字比较回退 / 调整异常边界与策略”之间做出工程权衡。

`type_info` 数据中每个多态类型约 100-200 字节。vtable 指针每对象额外 8 字节（64 位）。`dynamic_cast`/`typeid` 查表，中大型项目启用 RTTI 常见增量 5-10%。

关于 RTTI 的性能开销测量，参见 [The cost of C++ exceptions](https://monoinfinito.wordpress.com/series/exception-handling-in-c/) 和 [Benchmark: Cost of RTTI](https://artificial-mind.net/blog/2020/10/03/cost-of-rtti)。

### 引用捕获和值捕获的区别

建议使用 `catch(const T& )`，避免对象切片与额外复制。`catch(T)` 可能触发拷贝构造，且类型擦除/切片导致信息丢失。即使使用引用捕获，异常匹配阶段仍然依赖 `type_info` 指针比较，用值捕获也无法绕过 `type_info` 地址不一致导致的问题。

### noexcept 与异常边界

`noexcept(true)` 的函数若抛出异常将触发 `std::terminate`。大型系统里，合理布置“异常边界”（如线程入口、`main`、回调桥接处）统一捕获与上报。若因 `type_info` 污染导致基类匹配失败，异常可能越过预期边界，触发 `terminate`。

### `std::exception_ptr`/`std::rethrow_exception`

用于跨线程/异步传递异常（详见 [cppreference: std::exception_ptr](https://en.cppreference.com/w/cpp/error/exception_ptr)）。其底层仍携带异常类型信息（含 `type_info` 指针），因此污染问题仍可能影响最终 rethrow 的匹配。在线程池中抓取异常到 `exception_ptr`，在主线程 `rethrow_exception`，并按具体类型优先 catch，基类兜底。

### `std::exception_ptr` 实现细节深入剖析

`std::exception_ptr` 是一个智能指针，指向堆上保存的异常对象，支持跨线程/异步传递。

核心结构（简化）

```cpp
// libc++abi 实现（简化示意）
class __cxa_exception {
    std::type_info* exceptionType;           // 指向 type_info
    void (*exceptionDestructor)(void*);      // 析构函数
    std::unexpected_handler unexpectedHandler;
    std::terminate_handler terminateHandler;
    __cxa_exception* nextException;          // 异常链
    int handlerCount;                        // 引用计数
    // ...
    _Unwind_Exception unwindHeader;          // unwind 库使用
};

namespace std {
    class exception_ptr {
        void* __ptr_;  // 指向 __cxa_exception 或 nullptr
    public:
        exception_ptr() noexcept : __ptr_(nullptr) {}
        exception_ptr(const exception_ptr& other) noexcept;
        ~exception_ptr();
        // ...
    };
}
```

关键操作的操作有捕获异常（`std::current_exception`）：

```cpp
exception_ptr current_exception() noexcept {
    // 获取当前线程正在处理的异常对象
    __cxa_eh_globals* globals = __cxa_get_globals();
    __cxa_exception* header = globals->caughtExceptions;
    if (!header) return exception_ptr();
    
    // 增加引用计数（异常对象可能被多个 exception_ptr 持有）
    __cxa_increment_exception_refcount(header);
    return exception_ptr(header);
}
```

重新抛出（`std::rethrow_exception`）：

```cpp
[[noreturn]] void rethrow_exception(exception_ptr p) {
    __cxa_exception* header = static_cast<__cxa_exception*>(p.__ptr_);
    if (!header) std::terminate();
    
    // 标记为"正在被重抛"，跳过某些清理
    header->handlerCount = -header->handlerCount;
    
    // 调用 unwind 库，重新进入异常展开流程
    _Unwind_RaiseException(&header->unwindHeader);
    
    // 如果返回（理论上不应该），终止
    std::terminate();
}
```

引用计数管理

```cpp
void __cxa_increment_exception_refcount(void* thrown_object) noexcept {
    if (!thrown_object) return;
    __cxa_exception* header = cxa_exception_from_thrown_object(thrown_object);
    __sync_add_and_fetch(&header->handlerCount, 1);  // 原子递增
}

void __cxa_decrement_exception_refcount(void* thrown_object) noexcept {
    if (!thrown_object) return;
    __cxa_exception* header = cxa_exception_from_thrown_object(thrown_object);
    if (__sync_sub_and_fetch(&header->handlerCount, 1) == 0) {
        // 引用计数归零，销毁异常对象
        if (header->exceptionDestructor)
            header->exceptionDestructor(thrown_object);
        __cxa_free_exception(thrown_object);
    }
}
```

`exception_ptr` 内部存储的 `exceptionType` 指针在捕获时固定，指向抛出时的 `type_info`。若抛出线程使用的 `type_info`（地址 A）与 rethrow 线程使用的 `type_info`（地址 B）不一致（因混用 `-fno-rtti`），rethrow 后的 catch 匹配会失败。即使跨线程传递，污染问题依然存在且更隐蔽（因异常来源与处理不在同一线程/模块）。

线程池/异步任务必须统一 RTTI 配置。使用 `exception_ptr` 时，考虑在捕获线程立即记录异常类型名（`typeid(e).name()`）与 `what()`，在主线程判断后再决定如何处理。若无法统一配置，考虑自定义错误传递机制（如序列化异常信息为结构体）。

### 其他 ABI 的差异

MSVC ABI：依赖 SEH（Structured Exception Handling），异常元数据与 Itanium 不同（参见 [MSVC Exception Handling](https://learn.microsoft.com/en-us/cpp/cpp/structured-exception-handling-c-cpp)）。WebAssembly/Emscripten：可模拟 C++ 异常，匹配语义接近 Itanium（参见 [WebAssembly Exception Handling](https://github.com/WebAssembly/exception-handling)）。Android NDK：libunwind/llvm unwinder 的组合不同版本差异可见，需要结合编译链版本确认行为。

### 未来趋势/提案

C++23/26 社区围绕"异常成本/可预测性"的探索持续。Herb Sutter 的 P0709R4（静态异常）尝试用类型系统与返回值替代运行时展开。即使采用替代方案，跨边界错误传递仍需统一协议，避免"半静态、半运行时"的割裂。

### C++20 模块与 RTTI

C++20 引入了模块（Modules）系统，改变了传统的头文件包含模型：

```cpp
// 传统头文件模式
#include <vector>  // 重复预处理、符号膨胀

// C++20 模块
import std;  // 预编译、符号隔离
```

模块只解析一次，避免重复预处理，模块内部符号默认不导出，`export` 关键字控制可见性。模块对 `type_info` 处理的影响理论上是有更强的符号控制。

```cpp
// my_module.cppm
export module my_module;
import std;

export class MyException : public std::exception {
    // ...
};

// 模块内部的 type_info 处理：
// 1. 编译器为 MyException 生成 type_info
// 2. type_info 默认随模块接口导出
// 3. 符号可见性由模块系统管理，而非 -fvisibility
```

模块系统提供了一致的符号导出机制，减少了因手动配置 `-fvisibility` 导致的错误，`type_info` 的可见性由模块接口决定，更可预测。传统编译单元中，`-fno-rtti` 容易产生本地 `type_info`，模块系统下，符号隔离更明确，编译器可以更智能地处理。模块边界提供了天然的 ODR 检查点，编译器可以在模块接口级别检测类型定义冲突。

实际上还有很有挑战的。

```cpp
// 场景：混用模块与传统代码
module;  // 全局模块片段

// 包含传统头文件
#include <stdexcept>  // ← 使用 -fno-rtti 编译？

export module my_module;

export void foo() {
    throw std::runtime_error("...");  // ← type_info 来自哪里？
}
```

模块与非模块代码共存时，RTTI 配置必须一致，全局模块片段（`module;` 部分）中包含的头文件仍受传统编译选项影响，标准库在模块化之前，`import std;` 的实现依赖编译器支持度。GCC、Clang、MSVC 对模块的实现细节不同，符号导出、RTTI 处理的策略各异，跨编译器兼容性是新的挑战。构建系统（CMake、Bazel）对模块的支持尚不完善，`-fno-rtti` 与模块的交互未充分测试，错误诊断信息可能不够清晰。

扩展阅读

- [C++20 Modules 官方提案 P1103R3](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p1103r3.pdf)
- [GCC Modules 文档](https://gcc.gnu.org/wiki/cxx-modules)
- [Clang Modules 实现状态](https://clang.llvm.org/docs/StandardCPlusPlusModules.html)
- [MSVC Modules 教程](https://learn.microsoft.com/en-us/cpp/cpp/modules-cpp)

### PGO（Profile-Guided Optimization）对异常路径的影响

PGO 会将异常路径标记为冷路径优化。但 profdata 必须覆盖异常情况，否则可能导致意外裁剪。

PGO（Profile-Guided Optimization）通过收集实际运行的性能剖析数据（如分支频率、函数调用次数、热点路径），指导编译器优化

```bash
# 第一步：构建插桩版本
clang++ -fprofile-generate=./pgo_data -O2 app.cpp -o app_instrumented

# 第二步：运行典型工作负载，生成 profdata
./app_instrumented <typical_workload>

# 第三步：合并并用于优化构建
llvm-profdata merge -output=default.profdata ./pgo_data
clang++ -fprofile-use=default.profdata -O2 app.cpp -o app_optimized
```

PGO 会将"几乎不抛出"的异常路径标记为冷路径（cold），personality/LSDA 解析代码被放置到远离热点的位置。指令 Cache 局部性提升，正常路径性能更优。编译器可能将 landing pad 代码块放置在函数末尾或独立段，减少热路径指令膨胀。分支预测提示：将"不抛出"分支标记为 likely，抛出分支为 unlikely。若 profdata 显示某函数从未抛出异常，编译器可能更激进地内联。若某路径频繁抛出，可能避免内联以保持 LSDA 简洁。未命中的 catch 分支可能被裁剪或合并，Type Table 中冷门类型的 encoding 可能降低优先级。

PGO 基于 profdata 假设异常类型分布；若训练数据未覆盖某些异常类型，实际运行时可能触发未优化路径，性能下降。若 profdata 收集时使用统一 RTTI，但实际部署时混用 `-fno-rtti`，PGO 的分支预测/内联决策可能失效，甚至加剧污染问题（因优化后的代码路径与训练不一致）。

需要注意的是 PGO 的 profdata 收集阶段若未覆盖异常路径，优化后的代码可能将异常路径视为"dead code"并裁剪，导致实际运行时触发未定义行为。因此训练数据必须覆盖所有关键路径。

训练数据必须覆盖异常路径；可人工注入测试用例或使用生产流量回放。PGO 构建与最终部署的 RTTI/异常配置必须一致；否则重新收集 profdata。对比 PGO vs 非 PGO 的异常捕获延迟，确认优化未引入回归。使用 `llvm-profdata show` 检查异常相关函数的 counter 是否合理。

### C++ 标准提案演进：静态异常与替代方案

社区在探索"静态异常"（P0709R4）等替代方案，目标是零开销+确定性延迟。但传统异常仍需长期支持。

虽然 C++ 异常号称"零成本"，但在某些场景下仍存在问题，比如嵌入式/实时系统的栈展开延迟不可预测，无法满足硬实时要求。

虽然 C++ 异常号称"零成本"，但在某些场景下仍存在问题，比如嵌入式/实时系统的栈展开延迟不可预测，无法满足硬实时要求。LSDA/DWARF 表增加 10-20% 体积，对资源受限设备不友好。跨语言/ABI 边界方面与 C/Rust/Swift 的互操作代价高。还有某些编译器（如旧版嵌入式工具链）异常支持不完整。

P0709R4：静态异常（Herb Sutter）

提案链接：[P0709R4 - Zero-overhead deterministic exceptions](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p0709r4.pdf)

```cpp
// 传统异常
int divide(int a, int b) {
    if (b == 0) throw std::invalid_argument("除数为零");
    return a / b;
}

// 静态异常（提案语法示意）
int divide(int a, int b) throws {
    if (b == 0) throw std::invalid_argument("除数为零");
    return a / b;
}
```

函数签名显式标注可能抛出，编译器在调用处生成错误检查代码（类似返回 `std::expected<T,E>`）。异常对象通过特殊寄存器/栈槽返回，而非栈展开；类似 Go 的多返回值。调用链静态分析，无运行时展开，延迟可预测。可与传统异常共存；`throws` vs `throw` 在 ABI 层有区分。

优点是零开销且确定性延迟，二进制体积接近无异常版本，跨语言边界友好（类似错误码）。缺点是会破坏现有代码（需迁移至 `throws`），调用链中必须逐层传播错误，失去"跳跃式展开"的便利，与 RAII 的交互需重新设计。

相关提案：

- **P1640R1**：Error handling model（探讨基于 `std::expected` 的统一错误模型）。
- **P2544R0**：Saturation arithmetic（饱和算术，避免异常）。
- **Contracts (P2900R0)**：合约编程，部分场景替代异常前置条件检查。

若未来 C++ 采用静态异常，`type_info` 污染问题将不复存在（因不依赖 RTTI）。但传统异常仍需长期支持，混用"静态异常"与"动态异常"可能引入新的边界问题。工程实践：关注标准提案进展，评估迁移成本；短期内仍需治理 RTTI/异常配置一致性。

现有替代方案（C++23/26 已引入或提议中）

- `std::expected<T, E>`（C++23）：类似 Rust 的 `Result<T,E>`，显式错误返回（参见 [cppreference: std::expected](https://en.cppreference.com/w/cpp/utility/expected)）。
- `std::optional<T>` + `std::error_code`：轻量级错误传递（参见 [cppreference: std::error_code](https://en.cppreference.com/w/cpp/error/error_code)）。
- Outcome/Result 库（第三方，如 Boost.Outcome）：更丰富的语义（参见 [Boost.Outcome](https://www.boost.org/doc/libs/release/libs/outcome/)）。

新代码可优先使用 `std::expected`，避免异常。库边界采用错误码/expected，内部实现仍可用异常。关注 C++26/29 标准化进展，为可能的迁移做准备。

### 异常与协程（C++20 Coroutines）

协程的 `unhandled_exception()` 捕获未处理异常。type_info 污染会影响协程的异常传播。C++20 引入协程后，异常处理与协程的交互带来了新的复杂性（详见 [cppreference: Coroutines](https://en.cppreference.com/w/cpp/language/coroutines)）。

协程通过三个关键类型控制：

```cpp
struct MyPromise {
    auto get_return_object();
    auto initial_suspend();
    auto final_suspend() noexcept;
    void return_void();
    void unhandled_exception();  // ← 关键！
    // ...
};

struct MyTask {
    using promise_type = MyPromise;
    // ...
};

MyTask my_coroutine() {
    co_await something();
    co_return;
}
```

异常在协程中的传播路径，协程体内抛出异常：

```cpp
MyTask coro() {
    try {
        throw std::runtime_error("协程内错误");
    } catch (...) {
        // 可以在协程内捕获
    }
    co_return;
}
```

若协程体内异常未被捕获，编译器生成的代码会调用 `promise.unhandled_exception()`：

```cpp
void MyPromise::unhandled_exception() {
    // 标准做法：保存异常到 exception_ptr
    exception_ = std::current_exception();
}
```

C++20 标准要求 `final_suspend()` 必须为 `noexcept`；若抛出异常会直接调用 `std::terminate`，无法被外层捕获。`unhandled_exception()` 本身可以抛出异常（会被外层捕获），但通常不建议这样做。

在 `co_await` 结果中重新抛出

```cpp
MyTask coro() {
    throw std::runtime_error("错误");
    co_return;
}

void caller() {
    try {
        auto task = coro();  // 不会立即抛出
        task.resume();       // 或 co_await task
        task.get_result();   // 此时才 rethrow_exception
    } catch (const std::exception& e) {
        // 捕获协程内的异常
    }
}
```

协程的异常传播涉及多个模块/编译单元，协程函数定义在模块 A（使用 `-frtti`），Promise 类型定义在模块 B（使用 `-fno-rtti`），调用者在模块 C（使用 `-frtti`）。

若 `unhandled_exception()` 使用 `std::current_exception()` 捕获异常，其 `type_info*` 来自模块 A；当模块 C 调用 `rethrow_exception` 后尝试 catch，可能因模块 B 的 Promise 引入的污染而失败。

协程的"栈"实际上是堆上的协程帧（coroutine frame），销毁时需正确调用局部对象析构：

```cpp
MyTask coro() {
    RAII_Guard guard;  // 需要在协程销毁时析构
    co_await something();
    co_return;
}
```

若协程因异常终止，编译器生成的清理代码会调用所有已构造对象的析构函数。若 LSDA/CFI 信息缺失或 `type_info` 污染导致异常匹配失败，协程帧清理可能不完整，导致资源泄漏。

协程的 `final_suspend()` 通常标记为 `noexcept`。

```cpp
auto final_suspend() noexcept { return std::suspend_always{}; }
```

若 `unhandled_exception()` 或 `final_suspend()` 抛出异常，会触发 `std::terminate`。

统一协程相关模块（Promise、Task、调用者）的 RTTI/异常配置，`unhandled_exception()` 中使用 `exception_ptr` 保存异常，在外部 `rethrow` 前做类型判断或日志记录，关键协程边界使用 `noexcept` + 错误码，避免异常穿越，测试协程销毁路径的 RAII 行为（使用 ASan/Valgrind 检测泄漏）。

在 `unhandled_exception()` 中添加断点或日志，记录异常类型与 `type_info*` 地址。使用 `co_await` 前后的 try-catch 包裹，缩小异常来源范围。对比同步版本与协程版本的异常捕获行为，排查是否为协程特定问题。

跨线程传递 `exception_ptr` 时需注意内存序。异常对象的引用计数用原子操作保证线程安全。异常处理涉及多线程时，与内存序/同步原语有微妙交互（详见 [cppreference: std::memory_order](https://en.cppreference.com/w/cpp/atomic/memory_order)）。

每个线程维护独立的异常状态（`__cxa_eh_globals`），存储在 TLS：

```cpp
struct __cxa_eh_globals {
    __cxa_exception* caughtExceptions;   // 当前捕获的异常链
    unsigned int uncaughtExceptions;     // 未捕获异常计数
};

__cxa_eh_globals* __cxa_get_globals() {
    static thread_local __cxa_eh_globals globals;
    return &globals;
}
```

TLS 访问本身不需要显式同步（每线程独立），但若多线程共享 `exception_ptr`，需通过原子操作/互斥量保护。

前文提到 `exception_ptr` 的引用计数使用原子操作：

```cpp
__sync_add_and_fetch(&header->handlerCount, 1);  // 原子递增
__sync_sub_and_fetch(&header->handlerCount, 1);  // 原子递减
```

对应 C++11 的 `std::atomic`：

```cpp
std::atomic<int> handlerCount;
handlerCount.fetch_add(1, std::memory_order_relaxed);  // 或 acq_rel
```

内存序选择

- `memory_order_relaxed`：仅保证原子性，不同步其他内存操作；适用于纯引用计数。
- `memory_order_acquire` / `release`：同步相关内存操作；如引用计数归零时需确保异常对象可见性，需用 `release`（递减）+ `acquire`（读取）。
- `memory_order_seq_cst`：全局顺序一致；开销较高，通常不必要。

libc++abi 的实际实现通常使用 `relaxed`（递增）+ `acq_rel`（递减到零时），确保最后一个持有者看到完整的异常对象状态。实际的内存序选择需要权衡性能与正确性。对于纯引用计数，`relaxed` 足够；但异常对象包含数据时，递减到零需要 `release`，确保析构函数能看到完整状态。

抛出异常前，编译器不会自动插入内存屏障；若异常对象依赖外部共享状态，需手动同步：

```cpp
std::atomic<bool> ready{false};
int shared_data = 0;

// 线程 A
shared_data = 42;
ready.store(true, std::memory_order_release);  // 确保 shared_data 可见

// 线程 B
if (ready.load(std::memory_order_acquire)) {
    if (shared_data != 42) {
        throw std::runtime_error("数据不一致");  // 异常对象可能引用 shared_data
    }
}
```

若未正确同步，线程 B 看到的 `shared_data` 可能是旧值（数据竞争），抛出的异常携带错误信息。

多个线程同时调用 `std::terminate` 时，行为是未定义的（通常只有一个线程的 terminate handler 会执行）。

若因 `type_info` 污染导致未捕获异常，在多线程环境下可能触发竞态的 `terminate`：

```cpp
// 线程 A 与 B 同时抛出未捕获异常
std::thread t1([] { throw std::runtime_error("A"); });
std::thread t2([] { throw std::runtime_error("B"); });
t1.join();  // 若 A 未被主线程捕获，可能 terminate
t2.join();  // 若 B 也未捕获，竞态
```

协程的 `promise` 对象与协程帧在堆上分配，多线程访问需保护：

```cpp
MyTask coro();
auto task = coro();

// 线程 A
task.resume();

// 线程 B（错误：未同步）
task.resume();  // 数据竞争！
```

若协程内抛出异常并保存到 `exception_ptr`，线程 A 的 `unhandled_exception()` 写入与线程 B 的读取需用 `acquire-release` 同步。

这里有些建议，使用 TSan（Thread Sanitizer）检测异常相关的数据竞争。跨线程传递 `exception_ptr` 时，配合 `std::mutex` 或 `std::shared_ptr`（本身线程安全）。异常对象若引用外部状态，确保该状态的生命周期与可见性（使用 `shared_ptr` 或 `acquire-release`）。避免在信号处理器中抛出异常（与异步信号安全冲突）。

## 参考资料

- [Itanium C++ ABI: Exception Handling](https://itanium-cxx-abi.github.io/cxx-abi/abi-eh.html) - 两阶段展开、LSDA、personality function 的官方规范（**必读**）
- [Itanium C++ ABI: RTTI Layout](https://itanium-cxx-abi.github.io/cxx-abi/abi.html#rtti) - type_info 的内存布局和符号规范
- [C++ Standard: Exception Handling](https://eel.is/c++draft/except) - C++ 标准中关于异常处理的定义
- [C++ Standard: RTTI](https://eel.is/c++draft/expr.typeid) - C++ 标准中关于 RTTI 的定义
- [DWARF Debugging Standard v5](http://dwarfstd.org/doc/DWARF5.pdf) - CFI 和异常表格式规范
- [LLVM libcxxabi: Exception Handling](https://github.com/llvm/llvm-project/tree/main/libcxxabi/src)
   - [cxa_exception.cpp](https://github.com/llvm/llvm-project/blob/main/libcxxabi/src/cxa_exception.cpp) - `__cxa_throw` 等核心函数
   - [cxa_personality.cpp](https://github.com/llvm/llvm-project/blob/main/libcxxabi/src/cxa_personality.cpp) - `__gxx_personality_v0` 和 LSDA 解析
   - [private_typeinfo.cpp](https://github.com/llvm/llvm-project/blob/main/libcxxabi/src/private_typeinfo.cpp) - `__cxa_can_catch` 和类型匹配
- [LLVM libc++: typeinfo](https://github.com/llvm/llvm-project/blob/main/libcxx/include/typeinfo) - `type_info::operator==` 实现和比较策略宏
- [Clang: ItaniumCXXABI.cpp](https://github.com/llvm/llvm-project/blob/main/clang/lib/CodeGen/ItaniumCXXABI.cpp) - RTTI 生成逻辑，包含 `-fno-rtti` 的处理
- [LLVM libunwind](https://github.com/llvm/llvm-project/tree/main/libunwind) - 栈展开库实现
- [Ian Lance Taylor: Exception Frames](https://www.airs.com/blog/archives/464) - 强推Itanium ABI 设计者对异常表的经典解读
- [Zero-cost Exception Handling](https://www.ucw.cz/~hubicka/papers/abi/node25.html) - 零成本异常的实现原理和权衡
- [GCC Wiki: Visibility](https://gcc.gnu.org/wiki/Visibility) - 符号可见性和链接行为详解
- [LLVM Exception Handling Documentation](https://llvm.org/docs/ExceptionHandling.html) - LLVM 异常处理概览
- [GCC Exception Handling ABI](https://gcc.gnu.org/onlinedocs/libstdc++/manual/using_exceptions.html) - GCC 异常处理文档
- [MSVC Exception Handling](https://learn.microsoft.com/en-us/cpp/cpp/structured-exception-handling-c-cpp) - Windows SEH 机制
- [MMKV Issue #744](https://github.com/Tencent/MMKV/issues/744) - 第三方库 `-fno-rtti` 导致的异常处理失效真实案例
- [LLVM Issue #26576](https://github.com/llvm/llvm-project/issues/26576) - LTO 相关的 type_info 问题讨论
- [GCC Bugzilla #65958](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=65958) - 编译器优化导致的符号折叠问题
- [cppreference: std::type_info](https://en.cppreference.com/w/cpp/types/type_info) - type_info 的标准库参考
- [cppreference: std::exception_ptr](https://en.cppreference.com/w/cpp/error/exception_ptr) - 异常跨线程传递
- [cppreference: Coroutines](https://en.cppreference.com/w/cpp/language/coroutines) - C++20 协程与异常
- [P0709R4 - Zero-overhead deterministic exceptions](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p0709r4.pdf) - 静态异常提案
- [P1103R3 - Modules](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2019/p1103r3.pdf) - C++20 模块提案
- [Android NDK: C++ Library Support](https://developer.android.com/ndk/guides/cpp-support) - NDK 中的标准库和 RTTI 配置

































