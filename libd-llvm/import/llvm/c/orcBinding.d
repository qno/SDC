/*===----------- llvm-c/OrcBindings.h - Orc Lib C Iface ---------*- C++ -*-===*\
|*                                                                            *|
|*                     The LLVM Compiler Infrastructure                       *|
|*                                                                            *|
|* This file is distributed under the University of Illinois Open Source      *|
|* License. See LICENSE.TXT for details.                                      *|
|*                                                                            *|
|*===----------------------------------------------------------------------===*|
|*                                                                            *|
|* This header declares the C interface to libLLVMOrcJIT.a, which implements  *|
|* JIT compilation of LLVM IR.                                                *|
|*                                                                            *|
|* Many exotic languages can interoperate with C code but have a harder time  *|
|* with C++ due to name mangling. So in addition to C, this interface enables *|
|* tools written in such languages.                                           *|
|*                                                                            *|
|* Note: This interface is experimental. It is *NOT* stable, and may be       *|
|*       changed without warning.                                             *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

module llvm.c.orcBinding;

import llvm.c.object;
import llvm.c.targetMachine;

extern(C) nothrow:

struct LLVMOrcOpaqueJITStack {};
alias LLVMOrcJITStackRef = LLVMOrcOpaqueJITStack*;
alias LLVMOrcModuleHandle = uint;
alias LLVMOrcTargetAddress = ulong;
alias LLVMOrcSymbolResolverFn = ulong function(const(char)* Name,
                                               void* LookupCtx);
alias LLVMOrcLazyCompileCallbackFn = ulong function(LLVMOrcJITStackRef JITStack,
                                                    void *CallbackCtx);

enum LLVMOrcErrorCode {
  Success = 0,
  Generic,
}

/**
 * Create an ORC JIT stack.
 *
 * The client owns the resulting stack, and must call OrcDisposeInstance(...)
 * to destroy it and free its memory. The JIT stack will take ownership of the
 * TargetMachine, which will be destroyed when the stack is destroyed. The
 * client should not attempt to dispose of the Target Machine, or it will result
 * in a double-free.
 */
LLVMOrcJITStackRef LLVMOrcCreateInstance(LLVMTargetMachineRef TM);

/**
 * Get the error message for the most recent error (if any).
 *
 * This message is owned by the ORC JIT Stack and will be freed when the stack
 * is disposed of by LLVMOrcDisposeInstance.
 */
const(char)* LLVMOrcGetErrorMsg(LLVMOrcJITStackRef JITStack);

/**
 * Mangle the given symbol.
 * Memory will be allocated for MangledSymbol to hold the result. The client
 */
void LLVMOrcGetMangledSymbol(LLVMOrcJITStackRef JITStack, char** MangledSymbol,
                             const(char)* Symbol);

/**
 * Dispose of a mangled symbol.
 */
void LLVMOrcDisposeMangledSymbol(char* MangledSymbol);

/**
 * Create a lazy compile callback.
 */
LLVMOrcTargetAddress
LLVMOrcCreateLazyCompileCallback(LLVMOrcJITStackRef JITStack,
                                 LLVMOrcLazyCompileCallbackFn Callback,
                                 void* CallbackCtx);

/**
 * Create a named indirect call stub.
 */
LLVMOrcErrorCode LLVMOrcCreateIndirectStub(LLVMOrcJITStackRef JITStack,
                                           const(char)* StubName,
                                           LLVMOrcTargetAddress InitAddr);

/**
 * Set the pointer for the given indirect stub.
 */
LLVMOrcErrorCode LLVMOrcSetIndirectStubPointer(LLVMOrcJITStackRef JITStack,
                                               const(char)* StubName,
                                               LLVMOrcTargetAddress NewAddr);

/**
 * Add module to be eagerly compiled.
 */
LLVMOrcModuleHandle
LLVMOrcAddEagerlyCompiledIR(LLVMOrcJITStackRef JITStack, LLVMModuleRef Mod,
                            LLVMOrcSymbolResolverFn SymbolResolver,
                            void* SymbolResolverCtx);

/**
 * Add module to be lazily compiled one function at a time.
 */
LLVMOrcModuleHandle
LLVMOrcAddLazilyCompiledIR(LLVMOrcJITStackRef JITStack, LLVMModuleRef Mod,
                           LLVMOrcSymbolResolverFn SymbolResolver,
                           void* SymbolResolverCtx);

/**
 * Add an object file.
 */
LLVMOrcModuleHandle
LLVMOrcAddObjectFile(LLVMOrcJITStackRef JITStack, LLVMObjectFileRef Obj,
                     LLVMOrcSymbolResolverFn SymbolResolver,
                     void* SymbolResolverCtx);

/**
 * Remove a module set from the JIT.
 *
 * This works for all modules that can be added via OrcAdd*, including object
 * files.
 */
void LLVMOrcRemoveModule(LLVMOrcJITStackRef JITStack, LLVMOrcModuleHandle H);

/**
 * Get symbol address from JIT instance.
 */
LLVMOrcTargetAddress LLVMOrcGetSymbolAddress(LLVMOrcJITStackRef JITStack,
                                             const(char)* SymbolName);

/**
 * Dispose of an ORC JIT stack.
 */
void LLVMOrcDisposeInstance(LLVMOrcJITStackRef JITStack);
