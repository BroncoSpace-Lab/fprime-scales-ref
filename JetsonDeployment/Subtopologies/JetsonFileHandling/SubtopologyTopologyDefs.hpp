#ifndef JETSONFILEHANDLINGSUBTOPOLOGY_DEFS_HPP
#define JETSONFILEHANDLINGSUBTOPOLOGY_DEFS_HPP

#include "JetsonDeployment/Subtopologies/JetsonFileHandling/JetsonFileHandlingConfig/FppConstantsAc.hpp"

namespace JetsonFileHandling {
// State for topology construction
struct SubtopologyState {
    // Empty - no external state needed for JetsonFileHandling subtopology
};

struct TopologyState {
    SubtopologyState fileHandling;
};
}  // namespace JetsonFileHandling

#endif
