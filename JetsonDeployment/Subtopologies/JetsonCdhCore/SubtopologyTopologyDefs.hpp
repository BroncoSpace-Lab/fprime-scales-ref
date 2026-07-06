#ifndef JETSONCDHCORESUBTOPOLOGY_DEFS_HPP
#define JETSONCDHCORESUBTOPOLOGY_DEFS_HPP

#include "JetsonDeployment/Subtopologies/JetsonCdhCore/JetsonCdhCoreConfig/FppConstantsAc.hpp"

namespace JetsonCdhCore {
// State for topology construction
struct SubtopologyState {
    // Empty - no external state needed for JetsonCdhCore subtopology
};

struct TopologyState {
    SubtopologyState jetsonCdhCore;
};
}  // namespace JetsonCdhCore

#endif
