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

    def send_cmd_response(self, opCode, cmdSeq, response):
        self.cmdResponse_out(
            int(opCode),
            int(cmdSeq),
            fprime_py.Fw.CmdResponse(response),
        )

    def SET_ML_PATH_cmdHandler(self, opCode, cmdSeq, path):
        try:
            self.model = importlib.import_module(str(path))
        except Exception:
            self.send_cmd_response(
                opCode,
                cmdSeq,
                fprime_py.Fw.CmdResponse.VALIDATION_ERROR,
            )
            return

        self.log_ACTIVITY_HI_MLSet(str(path))

        self.send_cmd_response(
            opCode,
            cmdSeq,
            fprime_py.Fw.CmdResponse.OK,
        )

    def SET_INFERENCE_PATH_cmdHandler(self, opCode, cmdSeq, path):
        path_str = str(path)

        if not os.path.isdir(path_str):
            self.send_cmd_response(
                opCode,
                cmdSeq,
                fprime_py.Fw.CmdResponse.VALIDATION_ERROR,
            )
            return

        self.path = path_str
        self.log_ACTIVITY_HI_InferenceSet(path_str)

        self.send_cmd_response(
            opCode,
            cmdSeq,
            fprime_py.Fw.CmdResponse.OK,
        )

    def MULTI_INFERENCE_cmdHandler(self, opCode, cmdSeq):
        if self.model is None or self.path is None:
            self.send_cmd_response(
                opCode,
                cmdSeq,
                fprime_py.Fw.CmdResponse.VALIDATION_ERROR,
            )
            return

        try:
            self.outputs = self.model.main(self.path)
        except Exception:
            self.send_cmd_response(
                opCode,
                cmdSeq,
                fprime_py.Fw.CmdResponse.EXECUTION_ERROR,
            )
            return

        if self.outputs:
            for file, classification in self.outputs:
                self.log_ACTIVITY_HI_InferenceOutput(
                    str(file),
                    str(classification),
                )
                time.sleep(0.1)

        self.send_cmd_response(
            opCode,
            cmdSeq,
            fprime_py.Fw.CmdResponse.OK,
        )

    def CLEAR_INFERENCE_PATH_cmdHandler(self, opCode, cmdSeq):
        self.path = None

        self.send_cmd_response(
            opCode,
            cmdSeq,
            fprime_py.Fw.CmdResponse.OK,
        )