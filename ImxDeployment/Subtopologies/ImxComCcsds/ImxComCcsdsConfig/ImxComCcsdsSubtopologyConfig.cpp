#include "ImxComCcsdsSubtopologyConfig.hpp"

namespace ImxComCcsds {
namespace Allocation {
// This instance can be changed to use a different allocator in the ImxComCcsds Subtopology
Fw::MallocAllocator mallocatorInstance;
Fw::MemAllocator& memAllocator = mallocatorInstance;
}  // namespace Allocation
}  // namespace ImxComCcsds
