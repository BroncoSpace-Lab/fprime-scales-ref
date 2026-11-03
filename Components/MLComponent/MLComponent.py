import fprime_py
import Fw
import Components

from MLComponentBaseAc import MLComponentBase

import importlib
import os
import time

# Removed resnet_inference since the module was removed
# Removed the resnet_cifar100 benchmark since we dont need it at runtime and will slow the boot time

def _is_model_module_name(name): #_ is internal to this file
    """True for names shaped like '<package>.inference.<module>'.""" # docstring using """ ... """
    parts = name.split(".") # splits a string into a list at each .
    return(
        len(parts) == 3
        and parts[1] == "inference"
        and all(part.isidentifier() for part in parts)
    )

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
        name = str(path)

        # Check the name of the module before if gets imported, so a wrong SET_ML_PATH doesnt excecute with a validation error, instead just returns
        if not _is_model_module_name(name):
            self.send_cmd_response(
                opCode,
                cmdSeq,
                fprime_py.Fw.CmdResponse.VALIDATION_ERROR,
            )
            return

        try:
            self.model = importlib.import_module(name)

        except Exception:
            self.send_cmd_response(
                opCode,
                cmdSeq,
                fprime_py.Fw.CmdResponse.VALIDATION_ERROR,
            )
            return

        self.log_ACTIVITY_HI_MLSet(name)

        self.send_cmd_response(
            opCode,
            cmdSeq,
            fprime_py.Fw.CmdResponse.OK,
        )

    def SET_INFERENCE_PATH_cmdHandler(self, opCode, cmdSeq, path):
        path_str = os.path.abspath(str(path))

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