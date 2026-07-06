#ifndef COMCCSDSSUBTOPOLOGY_DEFS_HPP
#define COMCCSDSSUBTOPOLOGY_DEFS_HPP

#include <Fw/Types/MallocAllocator.hpp>
#include <Svc/BufferManager/BufferManager.hpp>
#include <Svc/FrameAccumulator/FrameDetector/CcsdsTcFrameDetector.hpp>
#include "ImxComCcsdsConfig/ImxComCcsdsSubtopologyConfig.hpp"
#include "ImxDeployment/Subtopologies/ImxComCcsds/ImxComCcsdsConfig/FppConstantsAc.hpp"

namespace ImxComCcsds {
struct SubtopologyState {
    // Empty - no external state needed for ImxComCcsds subtopology
};

struct TopologyState {
    SubtopologyState comCcsds;
};
}  // namespace ImxComCcsds

#endif
