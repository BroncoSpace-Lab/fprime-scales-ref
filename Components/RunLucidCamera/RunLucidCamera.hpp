// ======================================================================
// \title  RunLucidCamera.hpp
// \author scalesagx
// \brief  hpp file for RunLucidCamera component implementation class
// ======================================================================

#ifndef Components_RunLucidCamera_HPP
#define Components_RunLucidCamera_HPP

#include "JetsonDeployment/Components/RunLucidCamera/RunLucidCameraComponentAc.hpp"
#include <Fw/Types/FileNameString.hpp>

namespace Components {

  class RunLucidCamera :
    public RunLucidCameraComponentBase
  {

    public:

      // ----------------------------------------------------------------------
      // Component construction and destruction
      // ----------------------------------------------------------------------

      //! Construct RunLucidCamera object
      RunLucidCamera(
          const char* const compName //!< The component name
      );

      //! Destroy RunLucidCamera object
      ~RunLucidCamera();

    PRIVATE:

      // ----------------------------------------------------------------------
      // Handler implementations for commands
      // ----------------------------------------------------------------------

      //! Handler implementation for command TODO
      //!
      //! TODO
      void SAVE_PNG_cmdHandler(
          FwOpcodeType opCode, //!< The opcode
          U32 cmdSeq //!< The command sequence number
      ) override;

      //! Handler implementation for command SETUP_CAMERA
      void SETUP_CAMERA_cmdHandler(
        FwOpcodeType opCode, //!< The opcode
        U32 cmdSeq //!< The command sequence number
      ) override;

      //! Handler implementation for command SET_EXPOSURE
      void SET_EXPOSURE_cmdHandler(
        FwOpcodeType opCode, //!< The opcode
        U32 cmdSeq, //!< The command sequence number
        F64 param_name
      ) override;

      //! Handler implementation for command SET_GAIN
      void SET_GAIN_cmdHandler(
        FwOpcodeType opCode, //!< The opcode
        U32 cmdSeq, //!< The command sequence number
        F64 param_name
      ) override;

      Fw::FileNameString m_filename;

  };

}

#endif