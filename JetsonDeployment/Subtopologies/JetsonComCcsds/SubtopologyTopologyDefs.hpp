#ifndef JETSONCOMCCSDSSUBTOPOLOGY_DEFS_HPP
#define JETSONCOMCCSDSSUBTOPOLOGY_DEFS_HPP

#include <Fw/Types/MallocAllocator.hpp>
#include <Svc/BufferManager/BufferManager.hpp>
#include <Svc/FrameAccumulator/FrameDetector/CcsdsTcFrameDetector.hpp>
#include "JetsonComCcsdsConfig/JetsonComCcsdsSubtopologyConfig.hpp"
#include "JetsonDeployment/Subtopologies/JetsonComCcsds/JetsonComCcsdsConfig/FppConstantsAc.hpp"

namespace JetsonComCcsds {
struct SubtopologyState {
    // Empty - no external state needed for JetsonComCcsds subtopology
};

struct TopologyState {
    SubtopologyState comCcsds;
};
}  // namespace JetsonComCcsds

#endif
