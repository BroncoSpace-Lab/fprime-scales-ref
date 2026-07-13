// ======================================================================
// \title  BufferQueueMux.cpp
// \brief  Ownership-preserving mux for asynchronous Fw.Buffer queues
// ======================================================================

#include "Components/BufferQueueMux/BufferQueueMux.hpp"
#include "Fw/Types/Assert.hpp"

namespace Components {

BufferQueueMux::BufferQueueMux(const char* const compName) : BufferQueueMuxComponentBase(compName) {}

BufferQueueMux::~BufferQueueMux() = default;

void BufferQueueMux::bufferIn_handler(FwIndexType portNum, Fw::Buffer& buffer) {
    BufferOwner* available = nullptr;
    for (FwSizeType index = 0; index < MAX_OUTSTANDING_BUFFERS; ++index) {
        if (!this->m_owners[index].inUse) {
            available = &this->m_owners[index];
            break;
        }
    }

    FW_ASSERT(available != nullptr, static_cast<FwAssertArgType>(MAX_OUTSTANDING_BUFFERS));
    available->data = buffer.getData();
    available->port = portNum;
    available->inUse = true;
    this->bufferOut_out(0, buffer);
}

void BufferQueueMux::bufferReturn_handler(FwIndexType portNum, Fw::Buffer& buffer) {
    BufferOwner* owner = nullptr;
    for (FwSizeType index = 0; index < MAX_OUTSTANDING_BUFFERS; ++index) {
        if (this->m_owners[index].inUse && this->m_owners[index].data == buffer.getData()) {
            owner = &this->m_owners[index];
            break;
        }
    }

    FW_ASSERT(owner != nullptr);
    const FwIndexType ownerPort = owner->port;
    owner->inUse = false;
    owner->data = nullptr;
    this->bufferInReturn_out(ownerPort, buffer);
}

}  // namespace Components
