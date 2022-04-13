#include "llvm/Pass.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include "llvm/IR/Module.h"
// #include "llvm/IR/DebugInfo.h"
using namespace llvm;

namespace {
    struct MingPass : public FunctionPass {
        static char ID;
        MingPass() : FunctionPass(ID) {}

        virtual bool runOnFunction(Function &F) {
            // // 获取对应源码信息
            // Instruction *inst = F.getEntryBlock().getFirstNonPHI();
            // DILocation *loc = inst->getDebugLoc();
            // unsigned line = loc->getLine();
            // StringRef file = loc->getFilename();
            // StringRef dir = loc->getDirectory();
            // errs() << *inst << "; file: " << file << "; dir: " << dir << "; line: " << line << "\n";


            // 从运行时库中获取函数
            LLVMContext &Context = F.getContext();
            std::vector<Type*> paramTypes = {Type::getInt32Ty(Context)};
            Type *retType = Type::getVoidTy(Context);
            FunctionType *funcType = FunctionType::get(retType, paramTypes, false);
            FunctionCallee logFunc = F.getParent()->getOrInsertFunction("runtimeLog", funcType);

            // 打印
            errs() << "函数名：" << F.getName() << "\n";
            errs() << "函数参数个数：" << F.arg_size() << "\n";
            for (auto &arg : F.args()) {
                errs() << "参数名：" << arg.getName() << "\n";
            }
            errs() << "函数返回值个数：" << F.getReturnType()->getTypeID() << "\n";
            errs() << "函数内容：\n";
            F.print(errs());
            errs() << "\n";
            for (auto &BB : F) {
                errs() << "基础块：" << BB.getName() << "\n";
                BB.print(errs());
                errs() << "\n";
                for (auto &I : BB) {
                    errs() << "指令：" << "\n";
                    I.print(errs());
                    errs() << "\n";
                    
                    // 把两个数操作换成相乘
                    if (auto *op = dyn_cast<BinaryOperator>(&I)) {
                        IRBuilder<> builder(op);
                        // // 取出 op 左右两个操作数
                        // Value *lhs = op->getOperand(0);
                        // Value *rhs = op->getOperand(1);
                        // // 构造新的指令
                        // Value *mul = builder.CreateMul(lhs, rhs);
                        // // 替换指令
                        // for(auto &U : op->uses()) {
                        //     User *user = U.getUser();
                        //     user->setOperand(U.getOperandNo(), mul);
                        // }
                        // // 删除旧指令
                        // op->eraseFromParent();
                        
                        // 在 op 后面加入新指令
                        builder.SetInsertPoint(&BB, ++builder.GetInsertPoint());
                        // 在函数中插入新指令
                        Value* args[] = {op};
                        builder.CreateCall(logFunc, args);

                        return true;
                    } // end if
                    
                } // end for (auto &I : BB)
            } // end for (auto &BB : F)
            errs() << "\n";
            return false;
        } // end runOnFunction
    }; // end struct MingPass
} // end namespace

char MingPass::ID = 0;

// 开启 pass
static void registerMingPass(const PassManagerBuilder &,
                             legacy::PassManagerBase &PM) {
    PM.add(new MingPass());
}
static RegisterStandardPasses
        RegisterMyPass(PassManagerBuilder::EP_EarlyAsPossible,
                       registerMingPass);