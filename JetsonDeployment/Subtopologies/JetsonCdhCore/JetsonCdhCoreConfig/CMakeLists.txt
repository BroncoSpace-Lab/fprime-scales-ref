register_fprime_config(
    EXCLUDE_FROM_ALL
    AUTOCODER_INPUTS
        "${CMAKE_CURRENT_LIST_DIR}/JetsonCdhCoreConfig.fpp"
        "${CMAKE_CURRENT_LIST_DIR}/JetsonCdhCoreFatalHandlerConfig.fpp"
        "${CMAKE_CURRENT_LIST_DIR}/JetsonCdhCoreTlmConfig.fpp"
    INTERFACE
)
