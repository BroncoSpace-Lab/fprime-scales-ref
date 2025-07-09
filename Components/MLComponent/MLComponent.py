""" MLComponent.py:

Python implementation of the MLComponent fprime component. This component is dependent on autocoded bindings that
map to this component. **Note:** ensure this file is renamed to MLComponent.py in the current folder.
"""

# Required imports for the implementation to work
import fprime_pybind

# Typical, but optional, imports
import Fw
import Components


import importlib
import os
import resnet_cifar100
import resnet_inference
import time



class MLComponent(fprime_pybind.MLComponentBase):
    """ Implementation of MLComponent component. """

    def __init__(self):
        """ Constructor implementation """
        self.model = None
        self.path = None
        self.outputs = None
        pass

    def SET_ML_PATH_cmdHandler(self, opCode, cmdSeq, path):
        """ Command handler for SET_ML_PATH """
        try:
            self.model = importlib.import_module(path)
        except Exception as e:
            self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_VALIDATION_ERROR)
            return
        
        self.log_ACTIVITY_HI_MLSet(Fw.LogStringArg(path))
        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)

    def SET_INFERENCE_PATH_cmdHandler(self, opCode, cmdSeq, path):
        """ Command handler for SET_INFERENCE_PATH """
        if not os.path.isdir(path):
            self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_VALIDATION_ERROR)
            return
        
        self.path = path
        self.log_ACTIVITY_HI_InferenceSet(Fw.LogStringArg(path))
        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)

    def MULTI_INFERENCE_cmdHandler(self, opCode, cmdSeq):
        """ Command handler for MULTI_INFERENCE """
        
        try:
            self.outputs = self.model.main(self.path)
            
                
        except Exception as e:
            self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_EXECUTION_ERROR)
        
        if self.outputs:
            for file, classification in self.outputs:
                file_output = Fw.LogStringArg(file)
                classification_output = Fw.LogStringArg(classification)
                self.log_ACTIVITY_HI_InferenceOutput(file, classification)
                time.sleep(0.1)
                
        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)
        
        
        
    def CLEAR_INFERENCE_PATH_cmdHandler(self, opCode, cmdSeq):
        """ Command handler for CLEAR_INFERENCE_PATH """
        self.path = None
        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)

    
    