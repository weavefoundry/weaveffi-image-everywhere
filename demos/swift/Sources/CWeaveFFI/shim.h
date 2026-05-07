#ifndef WEAVEFFI_SHIM_H
#define WEAVEFFI_SHIM_H
// Re-export the generated header. The system library target requires a
// header inside the module dir, so we forward to sdk/c/weaveffi.h via
// -Xcc -I (configured in the build command).
#include "weaveffi.h"
#endif
