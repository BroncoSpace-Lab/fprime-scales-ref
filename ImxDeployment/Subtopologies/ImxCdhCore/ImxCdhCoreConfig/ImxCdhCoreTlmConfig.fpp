module ImxCdhCore{

    instance tlmSend: Svc.TlmChan base id ImxCdhCoreConfig.BASE_ID + 0x06000 \
        queue size ImxCdhCoreConfig.QueueSizes.tlmSend \
        stack size ImxCdhCoreConfig.StackSizes.tlmSend \
        priority ImxCdhCoreConfig.Priorities.tlmSend \

    # Uncomment the following block and comment the above block to use TlmPacketizer instead of TlmChan
    # instance tlmSend: Svc.TlmPacketizer base id ImxCdhCoreConfig.BASE_ID + 0x06000 \
    #    queue size ImxCdhCoreConfig.QueueSizes.tlmSend \
    #    stack size ImxCdhCoreConfig.StackSizes.tlmSend \
    #    priority ImxCdhCoreConfig.Priorities.tlmSend \
    # {
    #    # NOTE: The Name Ref is specific to the Reference deployment, Ref
    #    # This name will need to be updated if wishing to use this in a custom deployment
    #    phase Fpp.ToCpp.Phases.configComponents """
    #    ImxCdhCore::tlmSend.setPacketList(
    #        Ref::Ref_RefPacketsTlmPackets::packetList, 
    #        Ref::Ref_RefPacketsTlmPackets::omittedChannels, 
    #        1
    #    );
    #    """
    # }
}
