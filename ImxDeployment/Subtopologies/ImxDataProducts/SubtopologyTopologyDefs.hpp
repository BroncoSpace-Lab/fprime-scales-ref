#ifndef DATAPRODUCTSSUBTOPOLOGY_DEFS_HPP
#define DATAPRODUCTSSUBTOPOLOGY_DEFS_HPP

#include <Fw/Types/MallocAllocator.hpp>
#include <Os/FileSystem.hpp>
#include <Svc/BufferManager/BufferManager.hpp>
#include "ImxDataProductsConfig/ImxDataProductsSubtopologyConfig.hpp"
#include "ImxDeployment/Subtopologies/ImxDataProducts/ImxDataProductsConfig/FppConstantsAc.hpp"

namespace ImxDataProducts {
// State for topology construction
struct SubtopologyState {
    // Empty - no external state needed for ImxDataProducts subtopology
};

struct TopologyState {
    SubtopologyState dataProducts;
};
}  // namespace ImxDataProducts

#endif
