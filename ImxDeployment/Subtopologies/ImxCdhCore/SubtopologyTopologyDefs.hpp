#ifndef IMXCDHCORESUBTOPOLOGY_DEFS_HPP
#define IMXCDHCORESUBTOPOLOGY_DEFS_HPP

#include "ImxDeployment/Subtopologies/ImxCdhCore/ImxCdhCoreConfig/FppConstantsAc.hpp"

namespace ImxCdhCore {
// State for topology construction
struct SubtopologyState {
    // Empty - no external state needed for ImxCdhCore subtopology
};

struct TopologyState {
    SubtopologyState imxCdhCore;
};
}  // namespace ImxCdhCore

#endif
