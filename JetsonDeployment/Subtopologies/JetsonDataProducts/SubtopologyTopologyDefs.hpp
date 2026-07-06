#ifndef JETSONDATAPRODUCTSSUBTOPOLOGY_DEFS_HPP
#define JETSONDATAPRODUCTSSUBTOPOLOGY_DEFS_HPP

#include <Fw/Types/MallocAllocator.hpp>
#include <Os/FileSystem.hpp>
#include <Svc/BufferManager/BufferManager.hpp>
#include "JetsonDataProductsConfig/JetsonDataProductsSubtopologyConfig.hpp"
#include "JetsonDeployment/Subtopologies/JetsonDataProducts/JetsonDataProductsConfig/FppConstantsAc.hpp"

namespace JetsonDataProducts {
// State for topology construction
struct SubtopologyState {
    // Empty - no external state needed for JetsonDataProducts subtopology
};

struct TopologyState {
    SubtopologyState dataProducts;
};
}  // namespace JetsonDataProducts

#endif
