// ======================================================================
// \title  JetsonDeploymentTopologyDefs.hpp
// \brief required header file containing the required definitions for the topology autocoder
//
// ======================================================================
#ifndef JETSONDEPLOYMENT_JETSONDEPLOYMENTTOPOLOGYDEFS_HPP
#define JETSONDEPLOYMENT_JETSONDEPLOYMENTTOPOLOGYDEFS_HPP

// Subtopology PingEntries includes
#include "JetsonDeployment/Subtopologies/JetsonCdhCore/PingEntries.hpp"
#include "JetsonDeployment/Subtopologies/JetsonComCcsds/PingEntries.hpp"
#include "JetsonDeployment/Subtopologies/JetsonDataProducts/PingEntries.hpp"
#include "JetsonDeployment/Subtopologies/JetsonFileHandling/PingEntries.hpp"

// SubtopologyTopologyDefs includes
#include "JetsonDeployment/Subtopologies/JetsonCdhCore/SubtopologyTopologyDefs.hpp"
#include "JetsonDeployment/Subtopologies/JetsonComCcsds/SubtopologyTopologyDefs.hpp"
#include "JetsonDeployment/Subtopologies/JetsonDataProducts/SubtopologyTopologyDefs.hpp"
#include "JetsonDeployment/Subtopologies/JetsonFileHandling/SubtopologyTopologyDefs.hpp"

//JetsonComCcsds Enum Includes
#include "JetsonDeployment/Subtopologies/JetsonComCcsds/Ports_ComPacketQueueEnumAc.hpp"
#include "JetsonDeployment/Subtopologies/JetsonComCcsds/Ports_ComBufferQueueEnumAc.hpp"

// Include autocoded FPP constants
#include "JetsonDeployment/Top/FppConstantsAc.hpp"

/**
 * \brief required ping constants
 *
 * The topology autocoder requires a WARN and FATAL constant definition for each component that supports the health-ping
 * interface. These are expressed as enum constants placed in a namespace named for the component instance. These
 * are all placed in the PingEntries namespace.
 *
 * Each constant specifies how many missed pings are allowed before a WARNING_HI/FATAL event is triggered. In the
 * following example, the health component will emit a WARNING_HI event if the component instance cmdDisp does not
 * respond for 3 pings and will FATAL if responses are not received after a total of 5 pings.
 *
 * ```c++
 * namespace PingEntries {
 * namespace cmdDisp {
 *     enum { WARN = 3, FATAL = 5 };
 * }
 * }
 * ```
 */
namespace PingEntries {
    namespace JetsonDeployment_jetson_rateGroup1 {enum { WARN = 3, FATAL = 5 };}
    namespace JetsonDeployment_jetson_rateGroup2 {enum { WARN = 3, FATAL = 5 };}
    namespace JetsonDeployment_jetson_rateGroup3 {enum { WARN = 3, FATAL = 5 };}
    namespace JetsonDeployment_jetson_cmdSeq {enum { WARN = 3, FATAL = 5 };}
}  // namespace PingEntries

// Definitions are placed within the same namespace as the FPP module that contains the topology.
namespace JetsonDeployment {

/**
 * \brief required type definition to carry state
 *
 * The topology autocoder requires an object that carries state with the name `JetsonDeployment::TopologyState`. Only the type
 * definition is required by the autocoder and the contents of this object are otherwise opaque to the autocoder. The
 * contents are entirely up to the definition of the project. This deployment uses subtopologies.
 */
struct TopologyState {
    const char* hostname;   //!< Hostname for TCP communication
    U16 port;              //!< Port for TCP communication
    JetsonCdhCore::SubtopologyState cdhCore;           //!< Subtopology state for JetsonCdhCore
    JetsonComCcsds::SubtopologyState comCcsds;         //!< Subtopology state for JetsonComCcsds
    JetsonDataProducts::SubtopologyState dataProducts; //!< Subtopology state for JetsonDataProducts
    JetsonFileHandling::SubtopologyState fileHandling; //!< Subtopology state for JetsonFileHandling
};

namespace PingEntries = ::PingEntries;
}  // namespace JetsonDeployment

#endif
