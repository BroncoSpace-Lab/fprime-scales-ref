#ifndef FILEHANDLINGSUBTOPOLOGY_DEFS_HPP
#define FILEHANDLINGSUBTOPOLOGY_DEFS_HPP

#include "ImxDeployment/Subtopologies/ImxFileHandling/ImxFileHandlingConfig/FppConstantsAc.hpp"

namespace ImxFileHandling {
// State for topology construction
struct SubtopologyState {
    // Empty - no external state needed for ImxFileHandling subtopology
};

struct TopologyState {
    SubtopologyState fileHandling;
};
}  // namespace ImxFileHandling

#endif
