module Components {

  @ Adapts GenericHub buffer ports to the context-carrying communications ports
  @ used by the F Prime framer and deframer stack.
  passive component HubComAdapter {

    @ Buffer from GenericHub to be framed and transmitted
    sync input port bufferIn: Fw.BufferSend

    @ Return ownership of a buffer received on bufferIn
    output port bufferInReturn: Fw.BufferSend

    @ Send a hub buffer into the framer
    output port comOut: Svc.ComDataWithContext

    @ Return a buffer after the framer/communications stack is done with it
    sync input port comReturnIn: Svc.ComDataWithContext

    @ Receive a deframed buffer from the communications stack
    guarded input port comIn: Svc.ComDataWithContext

    @ Return ownership of a buffer received on comIn
    output port comInReturn: Svc.ComDataWithContext

    @ Send the deframed buffer into GenericHub
    output port bufferOut: Fw.BufferSend

    @ Return a consumed deframed buffer to the deframer
    sync input port bufferOutReturn: Fw.BufferSend
  }
}
