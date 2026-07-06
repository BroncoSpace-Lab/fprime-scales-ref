#include "ImxDataProductsSubtopologyConfig.hpp"

namespace ImxDataProducts {
namespace Allocation {
// This instance can be changed to use a different allocator in the ImxDataProducts Subtopology
Fw::MallocAllocator mallocatorInstance;
Fw::MemAllocator& memAllocator = mallocatorInstance;
}  // namespace Allocation
}  // namespace ImxDataProducts
