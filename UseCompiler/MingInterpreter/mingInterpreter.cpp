#include "llvm/Support/CommandLine.h"
#include "llvm/Support/PrettyStackTrace.h"
#include "llvm/Support/Signals.h"
#include "MInterpreter.h"

using namespace llvm;

namespace {
    cl::opt<std::string>
    bcFile(cl::desc("<input bitcode>"), cl::Positional, cl::init("-"));
    cl::list<std::string>
    commandArgs(cl::ConsumeAfter, cl::desc("<program arguments>..."));
}

class MingInterpreter : public MInterpreter {
    public:
    MingInterpreter(Module *M) : MInterpreter(M) {};
    virtual void execute(Instruction &I) {
        I.print(errs());
        MInterpreter::execute(I);
    }
};

int main(int argc, char **argv, char * const *envp) {
    sys::PrintStackTraceOnErrorSignal();
    PrettyStackTraceProgram X(argc, argv);

    cl::ParseCommandLineOptions(argc, argv, " LLVM Interpreter\n");
    return itpUtility<MingInterpreter>(bcFile, commandArgs, envp);
    
}




