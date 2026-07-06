#ifndef IMXCDHCORE_PINGENTRIES_HPP
#define IMXCDHCORE_PINGENTRIES_HPP

namespace PingEntries {
struct ImxCdhCore_cmdDisp {
    enum { WARN = 3, FATAL = 5 };
};
struct ImxCdhCore_events {
    enum { WARN = 3, FATAL = 5 };
};
struct ImxCdhCore_tlmSend {
    enum { WARN = 3, FATAL = 5 };
};
}  // namespace PingEntries

#endif
