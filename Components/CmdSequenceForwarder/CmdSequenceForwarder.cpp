// ======================================================================
// \title  CmdSequenceForwarder.cpp
// \author xf104starfighter
// \brief  cpp file for CmdSequenceForwarder component implementation class
// ======================================================================

#include "Components/CmdSequenceForwarder/CmdSequenceForwarder.hpp"
#include "FpConfig.hpp"

namespace Components {

  // ----------------------------------------------------------------------
  // Component construction and destruction
  // ----------------------------------------------------------------------

  CmdSequenceForwarder ::
    CmdSequenceForwarder(const char* const compName) :
      CmdSequenceForwarderComponentBase(compName)
  {

  }

  CmdSequenceForwarder ::
    ~CmdSequenceForwarder()
  {

  }

  // ----------------------------------------------------------------------
  // Handler implementations for user-defined typed input ports
  // ----------------------------------------------------------------------

  void CmdSequenceForwarder ::
    cmdResponseIn_handler(
        FwIndexType portNum,
        FwOpcodeType opCode,
        U32 cmdSeq,
        const Fw::CmdResponse& response
    )
  {
    this->seqCmdStatus_out(portNum, opCode, cmdSeq, response);
  }

  void CmdSequenceForwarder ::
    seqCmdBuf_handler(
        FwIndexType portNum,
        Fw::ComBuffer& data,
        U32 context
    )
  {
    this->comCmdOut_out(portNum, data, context);
  }

  // ----------------------------------------------------------------------
  // Handler implementations for commands
  // ----------------------------------------------------------------------

  void CmdSequenceForwarder ::
    TODO_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq
    )
  {
    // TODO
    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
  }

}