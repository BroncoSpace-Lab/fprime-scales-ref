set(MODULE_NAME lib_ArenaSDK)

add_library(${MODULE_NAME} INTERFACE)
target_include_directories(${MODULE_NAME} INTERFACE
	${CMAKE_CURRENT_LIST_DIR}/include/Arena
	${CMAKE_CURRENT_LIST_DIR}/GenICam/library/CPP/include
	${CMAKE_CURRENT_LIST_DIR}/include/Save
	${CMAKE_CURRENT_LIST_DIR}/include/GenTL
	)

target_link_libraries(${MODULE_NAME} INTERFACE
    # Your existing libraries
    JetsonDeployment_Components_RunLucidCamera
    
    # Arena SDK libraries - provide full paths to .so or .a files
    ${CMAKE_CURRENT_LIST_DIR}/lib/libarena.so          # Core Arena library
    ${CMAKE_CURRENT_LIST_DIR}/lib/libarena.so.0          # Core Arena library
    ${CMAKE_CURRENT_LIST_DIR}/lib/libsavec.so          # Save functionality
    ${CMAKE_CURRENT_LIST_DIR}/lib/libgentl.so          # GenTL functionality
    ${CMAKE_CURRENT_LIST_DIR}/lib/liblucidlog.so       # Lucid logging
	${CMAKE_CURRENT_LIST_DIR}/lib/libsave.so
	${CMAKE_CURRENT_LIST_DIR}/lib/libarenac.so

	${CMAKE_CURRENT_LIST_DIR}/ffmpeg/libavcodec.so
	${CMAKE_CURRENT_LIST_DIR}/ffmpeg/libavformat.so
	${CMAKE_CURRENT_LIST_DIR}/ffmpeg/libavutil.so
	${CMAKE_CURRENT_LIST_DIR}/ffmpeg/libswresample.so


    # GenICam libraries
    ${CMAKE_CURRENT_LIST_DIR}/GenICam/library/lib/Linux64_ARM/libGenApi_gcc54_v3_3_LUCID.so
    ${CMAKE_CURRENT_LIST_DIR}/GenICam/library/lib/Linux64_ARM/libGCBase_gcc54_v3_3_LUCID.so
    ${CMAKE_CURRENT_LIST_DIR}/GenICam/library/lib/Linux64_ARM/libMathParser_gcc54_v3_3_LUCID.so
    ${CMAKE_CURRENT_LIST_DIR}/GenICam/library/lib/Linux64_ARM/liblog4cpp_gcc54_v3_3_LUCID.so
    ${CMAKE_CURRENT_LIST_DIR}/GenICam/library/lib/Linux64_ARM/libLog_gcc54_v3_3_LUCID.so
    ${CMAKE_CURRENT_LIST_DIR}/GenICam/library/lib/Linux64_ARM/libNodeMapData_gcc54_v3_3_LUCID.so
    ${CMAKE_CURRENT_LIST_DIR}/GenICam/library/lib/Linux64_ARM/libXmlParser_gcc54_v3_3_LUCID.so
)