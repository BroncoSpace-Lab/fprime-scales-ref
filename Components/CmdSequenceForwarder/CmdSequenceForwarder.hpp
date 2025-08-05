// ======================================================================
// \title  CmdSequenceForwarder.hpp
// \author xf104starfighter
// \brief  hpp file for CmdSequenceForwarder component implementation class
// ======================================================================

#ifndef Components_CmdSequenceForwarder_HPP
#define Components_CmdSequenceForwarder_HPP

#include "Components/CmdSequenceForwarder/CmdSequenceForwarderComponentAc.hpp"

namespace Components {

  class CmdSequenceForwarder :
    public CmdSequenceForwarderComponentBase
  {

    public:

      // ----------------------------------------------------------------------
      // Component construction and destruction
      // ----------------------------------------------------------------------

      //! Construct CmdSequenceForwarder object
      CmdSequenceForwarder(
          const char* const compName //!< The component name
      );

      //! Destroy CmdSequenceForwarder object
      ~CmdSequenceForwarder();

    PRIVATE:

      // ----------------------------------------------------------------------
      // Handler implementations for user-defined typed input ports
      // ----------------------------------------------------------------------

      //! Handler implementation for cmdResponseIn
      //!
      //! Port for receiving cmdResponseIn (Local)
      void cmdResponseIn_handler(
          FwIndexType portNum, //!< The port number
          FwOpcodeType opCode, //!< Command Op Code
          U32 cmdSeq, //!< Command Sequence
          const Fw::CmdResponse& response //!< The command response argument
      ) override;

      //! Handler implementation for seqCmdBuf
      //!
      //! Port for receiving seqCmdBuf from hub (Remote)
      void seqCmdBuf_handler(
          FwIndexType portNum, //!< The port number
          Fw::ComBuffer& data, //!< Buffer containing packet data
          U32 context //!< Call context value; meaning chosen by user
      ) override;

    PRIVATE:

      // ----------------------------------------------------------------------
      // Handler implementations for commands
      // ----------------------------------------------------------------------

      //! Handler implementation for command TODO
      //!
      //! TODO
      void TODO_cmdHandler(
          FwOpcodeType opCode, //!< The opcode
          U32 cmdSeq //!< The command sequence number
      ) override;

  };

}

#endif