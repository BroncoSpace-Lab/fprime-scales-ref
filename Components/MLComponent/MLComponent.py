"""MLComponent — SET_ML_PATH + SET_INFERENCE_PATH + MULTI_INFERENCE."""

import fprime_pybind
import Fw
import Components
import importlib
import os
import resnet_cifar100  # noqa: F401 — optional SET_ML_PATH target
import time

_PATH_MAX = 128
_CLASS_MAX = 256


class MLComponent(fprime_pybind.MLComponentBase):
    def __init__(self):
        self.model = None
        self.path = None
        self.outputs = None

    def SET_ML_PATH_cmdHandler(self, opCode, cmdSeq, path):
        try:
            self.model = importlib.import_module(path)
        except Exception as e:
            print(f"[MLComponent] SET_ML_PATH failed for {path!r}: {e}", flush=True)
            self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_VALIDATION_ERROR)
            return
        self.log_ACTIVITY_HI_MLSet(Fw.LogStringArg(path))
        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)

    def SET_INFERENCE_PATH_cmdHandler(self, opCode, cmdSeq, path):
        resolved = os.path.abspath(path)
        if not os.path.isdir(resolved):
            self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_VALIDATION_ERROR)
            return
        self.path = resolved
        self.log_ACTIVITY_HI_InferenceSet(Fw.LogStringArg(resolved))
        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)

    def MULTI_INFERENCE_cmdHandler(self, opCode, cmdSeq):
        if self.model is None or not self.path:
            self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_VALIDATION_ERROR)
            return
        try:
            self.outputs = self.model.main(self.path)
        except Exception as e:
            print(f"[MLComponent] {e}", flush=True)
            self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_EXECUTION_ERROR)
            return
        for file, cls in self.outputs or []:
            p, c = str(file), str(cls)
            if len(p) > _PATH_MAX:
                p = p[: _PATH_MAX - 3] + "..."
            if len(c) > _CLASS_MAX:
                c = c[: _CLASS_MAX - 3] + "..."
            self.log_ACTIVITY_HI_InferenceOutput(Fw.LogStringArg(p), Fw.LogStringArg(c))
            time.sleep(0.1)
        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)

    def CLEAR_INFERENCE_PATH_cmdHandler(self, opCode, cmdSeq):
        self.path = None
        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)
