#ifndef JETSONCDHCORE_PINGENTRIES_HPP
#define JETSONCDHCORE_PINGENTRIES_HPP

namespace PingEntries {
struct JetsonCdhCore_cmdDisp {
    enum { WARN = 3, FATAL = 5 };
};
struct JetsonCdhCore_events {
    enum { WARN = 3, FATAL = 5 };
};
struct JetsonCdhCore_tlmSend {
    enum { WARN = 3, FATAL = 5 };
};
}  // namespace PingEntries

#endif
