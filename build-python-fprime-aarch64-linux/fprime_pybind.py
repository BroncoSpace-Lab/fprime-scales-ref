""" WARNING WARNING THIS IS AN AUTOCODED FILE WARNING WARNING """
import Fw

import Components

import Fw





class MLComponentBase(object):
    """ Autocoded base for the python code """

    def _init_ac(self, this):
        """ Initialize 'this' to redirect into the CPP """
        self.this = this

    

    
    def cmdResponse_out(self, opcode: int, cmd_seq: int, response: Fw.CmdResponse):
        """ Command response handler """
        self.this.cmdResponse_out(opcode, cmd_seq, response)
    
    def getTime(self):
        """ getTime handler """
        return self.this.getTime()
    
    
    def log_ACTIVITY_HI_MLSet(self, status):
        self.this.log_ACTIVITY_HI_MLSet(Fw.LogStringArg(status) if isinstance(status, str) else status)

    def log_ACTIVITY_HI_InferenceSet(self, status):
        self.this.log_ACTIVITY_HI_InferenceSet(Fw.LogStringArg(status) if isinstance(status, str) else status)

    def log_ACTIVITY_HI_InferenceOutput(self, path, classification):
        self.this.log_ACTIVITY_HI_InferenceOutput(Fw.LogStringArg(path) if isinstance(path, str) else path,Fw.LogStringArg(classification) if isinstance(classification, str) else classification)

    
    








