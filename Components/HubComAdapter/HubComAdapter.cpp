// ======================================================================
// \title  HubComAdapter.cpp
// \brief  Buffer/communications interface adapter for GenericHub framing
// ======================================================================

#include "Components/HubComAdapter/HubComAdapter.hpp"

namespace Components {

HubComAdapter::HubComAdapter(const char* const compName) : HubComAdapterComponentBase(compName) {}

HubComAdapter::~HubComAdapter() = default;

void HubComAdapter::bufferIn_handler(FwIndexType portNum, Fw::Buffer& buffer) {
    ComCfg::FrameContext context;
    this->comOut_out(0, buffer, context);
}

void HubComAdapter::comReturnIn_handler(FwIndexType portNum,
                                        Fw::Buffer& buffer,
                                        const ComCfg::FrameContext& context) {
    this->bufferInReturn_out(0, buffer);
}

void HubComAdapter::comIn_handler(FwIndexType portNum,
                                  Fw::Buffer& buffer,
                                  const ComCfg::FrameContext& context) {
    this->bufferOut_out(0, buffer);
}

void HubComAdapter::bufferOutReturn_handler(FwIndexType portNum, Fw::Buffer& buffer) {
    ComCfg::FrameContext context;
    this->comInReturn_out(0, buffer, context);
}

}  // namespace Components
