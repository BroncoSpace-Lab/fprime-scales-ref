""" PythonComponent.py:

Python implementation of the PythonComponent fprime component. This component is dependent on autocoded bindings that
map to this component. **Note:** ensure this file is renamed to PythonComponent.py in the current folder.
"""

# Required imports for the implementation to work
import fprime_pybind

# Typical, but optional, imports
import Fw
import Components


class PythonComponent(fprime_pybind.PythonComponentBase):
    """ Implementation of PythonComponent component. """

    def __init__(self):
        """ Constructor implementation """
        self.m_greetingCount = 0
        pass # TODO: fill out custom constructing logic

    
    def SAY_HELLO_cmdHandler(self, opCode, cmdSeq, greeting):
        """ Command handler for SAY_HELLO """
        eventGreeting = Fw.LogStringArg(greeting)
        self.log_ACTIVITY_HI_Hello(eventGreeting)
        
        self.m_greetingCount += 1
        self.tlmWrite_GreetingCount(self.m_greetingCount)
        
        self.cmdResponse_out(opCode, cmdSeq, Fw.CmdResponse.COMMAND_OK)

    