#include "MInterpreter.h"
#include <cerrno>
#include "llvm/Support/DynamicLibrary.h"

using namespace llvm;

MInterpreter::MInterpreter(Module *M) :
      ExecutionEngine(M),
      module(M)
{
  interp = new Interpreter(M);
  pItp = (PInterpreter *)pItp;  // GIANT HACK

  // 数据布局 ExecutionEngine::runFunctionAsMain().
  setDataLayout(interp->getDataLayout());

  Modules.clear();
}

MInterpreter::~MInterpreter() {
  delete interp;
}

// 解释器主循环
void MInterpreter::run() {
  while (!pItp->ECStack.empty()) {
    ExecutionContext &EC = pItp->ECStack.back();
    Instruction &I = *EC.CurInst++;
    execute(I);
  }
}

void MInterpreter::execute(Instruction &I) {
  pItp->visit(I);
}

// 包装入口
int MInterpreter::runMain(std::vector<std::string> args,
                          char * const *envp) {
    // 获得 main 函数
    Function *mainF = module->getFunction("main");
    if (!mainF) {
        errs() << "No main function found in module.\n";
        return -1;
    }

    // 重置 errno 为 0
    errno = 0;
    
    std::string ErrorMsg;
    if (sys::DynamicLibrary::LoadLibraryPermanently(0, &ErrorMsg)) {
        errs() << "Could not load dynamic library: " << ErrorMsg << "\n";
        return -1;
    }

    // 返回 main
    return runFunctionAsMain(mainF, args, envp);
}

// 包装 runFunction
GenericValue MInterpreter::runFunction(Function *F,
                                       const std::vector<GenericValue> &ArgValues) {
    std::vector<GenericValue> ActualArgs;
    const unsigned NumArgs = F->getFunctionType()->getNumParams();
    for (unsigned i = 0; i < NumArgs; i++)
    {
        NumArgs.push_back(ArgValues[i]);
    }
    interp->callFunction(F, ActualArgs);
    run();
    return pItp->ExitValue;
}
void *MInterpreter::getPointerToNamedFunction(const std::string &Name,
                                              bool AbortOnFailure) {
    return 0;
}
void *MInterpreter::recompileAndRelinkFunction(Function *F) {
    return getPointerToFunction(F);
}
void MInterpreter::freeMachineCodeForFunction(Function *F) {
}
void *MInterpreter::getPointerToFunction(Function *F) {
    return (void *)F;
}
void *MInterpreter::getPointerToBasicBlock(BasicBlock *BB) {
    return （void *)BB;
}