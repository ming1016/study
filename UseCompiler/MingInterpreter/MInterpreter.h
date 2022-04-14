#ifndef M_Interpreter_H
#define M_Interpreter_H

#include <vector>
#include "llvm/IR/InstVisitor.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "ExecutionEngine/Interpreter/Interpreter.h"

// 使用 public 访问内部
// template<typename SubClass, typename RetTy=void>
class PInterpreter : public llvm::ExecutionEngine,
                     public llvm::InstVisitor<llvm::Interpreter> {
    public:
    llvm::GenericValue ExitValue;
    llvm::DataLayout TD;
    llvm::IntrinsicLowering *IL;
    std::vector<llvm::ExecutionContext> ECStack;
    std::vector<llvm::Function*> AtExitHandlers;
};

// template<typename SubClass, typename RetTy=void>
class MInterpreter : public llvm::ExecutionEngine {
    public:
    llvm::Interpreter *interp;
    PInterpreter *pItp;
    llvm::Module *module;

    explicit MInterpreter(llvm::Module *M);
    virtual ~MInterpreter();

    virtual void run();
    virtual void execute(llvm::Instruction &I);

    // 入口
    virtual int runMain(std::vector<std::string> args,
                        char * const *envp = 0);
    
    // 遵循 ExecutionEngine 接口
    llvm::GenericValue runFunction(
        llvm::Function *F,
        const std::vector<llvm::GenericValue> &ArgValues
    );
    void *getPointerToNamedFunction(const std::string &Name,
                                    bool AbortOnFailure = true);
    void *recompileAndRelinkFunction(llvm::Function *F);
    void freeMachineCodeForFunction(llvm::Function *F);
    void *getPointerToFunction(llvm::Function *F);
    void *getPointerToBasicBlock(llvm::BasicBlock *BB);
};

// 解释运行 bitcode 时所需的一些功能
template <typename InterpreterType>
int itpUtility(std::string bcFile, std::vector<std::string> args, char * const *envp) {
    llvm::LLVMContext &Constext = llvm::getGlobalContext();

    // 读 bitcode 文件
    llvm::SMDiagnostic Err;
    llvm::Module *Mod = llvm::ParseIRFile(bcFile, Err, Constext);
    if (!Mod) {
        llvm::errs() << "bitcode parsing failed\n";
        return -1;
    }
    
    // 检查 bitcode 文件是否有效
    std::string ErrStr;
    if (Mod->MaterializeAllPermanently(&ErrStr)) {
        llvm::errs() << "bitcode materialization failed: " << ErrStr << "\n";
        return -1;
    }

    // 处理参数
    if (llvm::StringRef(bcFile).endswith(".bc"))
        bcFile.erase(bcFile.end() - 3, bcFile.end());
    args.insert(args.begin(), bcFile); // 将文件名作为第一个参数

    // 创建解释器
    MInterpreter *itp = new InterpreterType(Mod);
    int retcode = itp->runMain(args, envp);
    delete itp;
    return retcode;
}

#endif