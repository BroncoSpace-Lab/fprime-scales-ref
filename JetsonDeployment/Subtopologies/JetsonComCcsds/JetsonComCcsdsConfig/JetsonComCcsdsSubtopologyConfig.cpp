#include "JetsonComCcsdsSubtopologyConfig.hpp"

namespace JetsonComCcsds {
namespace Allocation {
// This instance can be changed to use a different allocator in the JetsonComCcsds Subtopology
Fw::MallocAllocator mallocatorInstance;
Fw::MemAllocator& memAllocator = mallocatorInstance;
}  // namespace Allocation
}  // namespace JetsonComCcsds
