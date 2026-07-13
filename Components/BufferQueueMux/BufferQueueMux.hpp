// ======================================================================
// \title  BufferQueueMux.hpp
// \brief  Ownership-preserving mux for asynchronous Fw.Buffer queues
// ======================================================================

#ifndef Components_BufferQueueMux_HPP
#define Components_BufferQueueMux_HPP

#include "Components/BufferQueueMux/BufferQueueMuxComponentAc.hpp"

namespace Components {

class BufferQueueMux final : public BufferQueueMuxComponentBase {
  public:
    explicit BufferQueueMux(const char* const compName);
    ~BufferQueueMux() override;

  private:
    struct BufferOwner {
        U8* data;
        FwIndexType port;
        bool inUse;
    };

    static constexpr FwSizeType MAX_OUTSTANDING_BUFFERS = 128;

    void bufferIn_handler(FwIndexType portNum, Fw::Buffer& buffer) override;
    void bufferReturn_handler(FwIndexType portNum, Fw::Buffer& buffer) override;

    BufferOwner m_owners[MAX_OUTSTANDING_BUFFERS] = {};
};

}  // namespace Components

#endif
