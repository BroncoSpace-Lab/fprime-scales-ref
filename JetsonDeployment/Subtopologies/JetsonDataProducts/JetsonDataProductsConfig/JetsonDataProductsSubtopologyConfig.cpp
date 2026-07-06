#include "JetsonDataProductsSubtopologyConfig.hpp"

namespace JetsonDataProducts {
namespace Allocation {
// This instance can be changed to use a different allocator in the JetsonDataProducts Subtopology
Fw::MallocAllocator mallocatorInstance;
Fw::MemAllocator& memAllocator = mallocatorInstance;
}  // namespace Allocation
}  // namespace JetsonDataProducts
