""" MLComponent Python component implementation

This is the Python implementation for the MLComponent component. This class extends the auto-coded python base
class MLComponentBase that provides the necessary plumbing to connect to the C++ stub connected to the rest of
the F Prime topology.
"""
import fprime_py
from MLComponentBaseAc import MLComponentBase


class MLComponent(MLComponentBase):
    """ Python implementation for the MLComponent component """
    
    def SET_ML_PATH_cmdHandler(self, opCode, cmdSeq, path):
        """ Handle the SET_ML_PATH command """
        # TODO: Implement command handler
        self.cmdResponse_out(opCode, cmdSeq, fprime_py.Fw.CmdResponse(fprime_py.Fw.CmdResponse.T.OK))
    def SET_INFERENCE_PATH_cmdHandler(self, opCode, cmdSeq, path):
        """ Handle the SET_INFERENCE_PATH command """
        # TODO: Implement command handler
        self.cmdResponse_out(opCode, cmdSeq, fprime_py.Fw.CmdResponse(fprime_py.Fw.CmdResponse.T.OK))
    def MULTI_INFERENCE_cmdHandler(self, opCode, cmdSeq):
        """ Handle the MULTI_INFERENCE command """
        # TODO: Implement command handler
        self.cmdResponse_out(opCode, cmdSeq, fprime_py.Fw.CmdResponse(fprime_py.Fw.CmdResponse.T.OK))
    def CLEAR_INFERENCE_PATH_cmdHandler(self, opCode, cmdSeq):
        """ Handle the CLEAR_INFERENCE_PATH command """
        # TODO: Implement command handler
        self.cmdResponse_out(opCode, cmdSeq, fprime_py.Fw.CmdResponse(fprime_py.Fw.CmdResponse.T.OK))