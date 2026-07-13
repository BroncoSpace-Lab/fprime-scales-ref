module Components {

  @ Multiplexes two buffer producers into one asynchronous queue while retaining
  @ the producer identity needed to return buffer ownership correctly.
  passive component BufferQueueMux {
    guarded input port bufferIn: [2] Fw.BufferSend
    output port bufferInReturn: [2] Fw.BufferSend

    output port bufferOut: Fw.BufferSend
    guarded input port bufferReturn: Fw.BufferSend
  }
}
