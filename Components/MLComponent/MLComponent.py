import fprime_py
import Fw
import Components

from MLComponentBaseAc import MLComponentBase

import importlib
import os
import time

import resnet_cifar100
import resnet_inference


class MLComponent(MLComponentBase):

    def __init__(self):
        super().__init__()
        self.model = None
        self.path = None
        self.outputs = None

    def SET_ML_PATH_cmdHandler(self, opCode, cmdSeq, path):
        try:
            self.model = importlib.import_module(path)
        except Exception:
            self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_VALIDATION_ERROR)
            return

        self.log_ACTIVITY_HI_MLSet(Fw.LogStringArg(path))
        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)

    def SET_INFERENCE_PATH_cmdHandler(self, opCode, cmdSeq, path):
        if not os.path.isdir(path):
            self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_VALIDATION_ERROR)
            return

        self.path = path
        self.log_ACTIVITY_HI_InferenceSet(Fw.LogStringArg(path))
        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)

    def MULTI_INFERENCE_cmdHandler(self, opCode, cmdSeq):
        if self.model is None or self.path is None:
            self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_VALIDATION_ERROR)
            return

        try:
            self.outputs = self.model.main(self.path)
        except Exception:
            self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_EXECUTION_ERROR)
            return

        if self.outputs:
            for file, classification in self.outputs:
                self.log_ACTIVITY_HI_InferenceOutput(
                    Fw.LogStringArg(file),
                    Fw.LogStringArg(classification),
                )
                time.sleep(0.1)

        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)

    def CLEAR_INFERENCE_PATH_cmdHandler(self, opCode, cmdSeq):
        self.path = None
        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)