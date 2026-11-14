// lucid_set_ip: give the LUCID camera a persistent static IP so the flight
// software (Jetson, 10.3.2.0/24) can always reach it.
//
//   ./lucid_set_ip --show                       list cameras and their IP (read-only)
//   ./lucid_set_ip --ip 10.3.2.4                force + persist 10.3.2.4/24, gateway 0.0.0.0
//   ./lucid_set_ip --ip 10.3.2.4 --mask 255.255.255.0 --gateway 0.0.0.0 [--serial 222401887]
//
// Why: without a persistent IP, a camera that restarts (power/PoE glitch) comes
// back on DHCP or, with no DHCP server, a link-local 169.254.x.x address that
// the 10.3.2.x machines can't reach. Steps (as LUCID's Cpp_ForceIp and
// Cpp_IpConfig_Manual examples):
//   1. ForceIP the target address (temporary) so the camera can be opened
//   2. GevPersistentIPAddress/SubnetMask/DefaultGateway = target,
//      GevCurrentIPConfigurationPersistentIP = true, ...DHCP = false
//   3. re-discover and verify
#include "ArenaApi.h"

#include <arpa/inet.h>
#include <chrono>
#include <cstring>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

static bool parse_ip(const std::string& s, uint32_t& out) {
  in_addr a{};
  if (inet_pton(AF_INET, s.c_str(), &a) != 1) return false;
  out = ntohl(a.s_addr);
  return true;
}

static std::string ip_str(uint64_t v) {
  return std::to_string((v >> 24) & 255) + "." + std::to_string((v >> 16) & 255) + "." +
         std::to_string((v >> 8) & 255) + "." + std::to_string(v & 255);
}

static std::vector<Arena::DeviceInfo> discover(Arena::ISystem* sys) {
  std::vector<Arena::DeviceInfo> d;
  for (int t = 0; t < 5 && d.empty(); t++) { sys->UpdateDevices(1000); d = sys->GetDevices(); }
  return d;
}

static void usage(const char* p) {
  std::cout << "usage: " << p << " --show\n"
            << "       " << p << " --ip A.B.C.D [--mask 255.255.255.0] [--gateway 0.0.0.0] [--serial N]\n";
}

int main(int argc, char** argv) {
  std::cout << std::unitbuf;
  bool show = false;
  std::string ip_s, mask_s = "255.255.255.0", gw_s = "0.0.0.0", serial;
  for (int i = 1; i < argc; i++) {
    std::string a = argv[i];
    auto next = [&](std::string& v) { if (i + 1 < argc) { v = argv[++i]; return true; } return false; };
    if (a == "--show") show = true;
    else if (a == "--ip" && next(ip_s)) {}
    else if (a == "--mask" && next(mask_s)) {}
    else if (a == "--gateway" && next(gw_s)) {}
    else if (a == "--serial" && next(serial)) {}
    else { usage(argv[0]); return (a == "-h" || a == "--help") ? 0 : 1; }
  }
  if (!show && ip_s.empty()) { usage(argv[0]); return 1; }
  uint32_t ip = 0, mask = 0, gw = 0;
  if (!show && (!parse_ip(ip_s, ip) || !parse_ip(mask_s, mask) || !parse_ip(gw_s, gw))) {
    std::cerr << "invalid --ip/--mask/--gateway\n";
    return 1;
  }

  Arena::ISystem* sys = nullptr;
  Arena::IDevice* dev = nullptr;
  int rc = 0;
  try {
    sys = Arena::OpenSystem();
    auto devs = discover(sys);
    if (devs.empty()) { std::cerr << "No LUCID camera found on any interface.\n"; Arena::CloseSystem(sys); return 2; }
    for (auto& d : devs)
      std::cout << "camera: " << d.ModelName() << "  serial " << d.SerialNumber() << "  MAC " << d.MacAddressStr()
                << "  IP " << d.IpAddressStr() << "/" << d.SubnetMaskStr() << "  gw " << d.DefaultGatewayStr() << "\n";
    if (show) { Arena::CloseSystem(sys); return 0; }

    int idx = -1;
    for (size_t i = 0; i < devs.size(); i++)
      if (serial.empty() ? devs.size() == 1 : std::string(devs[i].SerialNumber().c_str()) == serial) idx = static_cast<int>(i);
    if (idx < 0) {
      std::cerr << (serial.empty() ? "More than one camera: pass --serial.\n" : "No camera with that serial.\n");
      Arena::CloseSystem(sys);
      return 1;
    }
    Arena::DeviceInfo info = devs[idx];
    std::string sn = info.SerialNumber().c_str();
    uint64_t mac = info.MacAddress();

    // 1. Force the target IP (temporary, until the camera restarts) if needed
    if (info.IpAddress() != ip || info.SubnetMask() != mask) {
      std::cout << "Forcing temporary IP " << ip_s << "/" << mask_s << " ...\n";
      sys->ForceIp(mac, ip, mask, gw);
      std::this_thread::sleep_for(std::chrono::seconds(2));
      bool found = false;
      for (int t = 0; t < 10 && !found; t++) {
        sys->UpdateDevices(1000);
        for (auto& d : sys->GetDevices())
          if (std::string(d.SerialNumber().c_str()) == sn && d.IpAddress() == ip) { info = d; found = true; }
      }
      if (!found) { std::cerr << "Camera did not come back on " << ip_s << " after ForceIP.\n"; Arena::CloseSystem(sys); return 3; }
      std::cout << "  camera now answers on " << info.IpAddressStr() << "\n";
    }

    // 2. Persist it
    dev = sys->CreateDevice(info);
    GenApi::INodeMap* nm = dev->GetNodeMap();
    Arena::SetNodeValue<int64_t>(nm, "GevPersistentIPAddress", static_cast<int64_t>(ip));
    Arena::SetNodeValue<int64_t>(nm, "GevPersistentSubnetMask", static_cast<int64_t>(mask));
    try { Arena::SetNodeValue<int64_t>(nm, "GevPersistentDefaultGateway", static_cast<int64_t>(gw)); }
    catch (GenICam::GenericException&) { std::cout << "  (camera has no writable GevPersistentDefaultGateway; skipped)\n"; }
    Arena::SetNodeValue<bool>(nm, "GevCurrentIPConfigurationPersistentIP", true);
    Arena::SetNodeValue<bool>(nm, "GevCurrentIPConfigurationDHCP", false);
    std::cout << "Persistent IP set: "
              << ip_str(Arena::GetNodeValue<int64_t>(nm, "GevPersistentIPAddress")) << "/"
              << ip_str(Arena::GetNodeValue<int64_t>(nm, "GevPersistentSubnetMask"))
              << "  persistent=" << Arena::GetNodeValue<bool>(nm, "GevCurrentIPConfigurationPersistentIP")
              << "  dhcp=" << Arena::GetNodeValue<bool>(nm, "GevCurrentIPConfigurationDHCP") << "\n";
    sys->DestroyDevice(dev);
    dev = nullptr;

    // 3. Verify by re-discovery
    bool ok = false;
    for (int t = 0; t < 5 && !ok; t++) {
      sys->UpdateDevices(1000);
      for (auto& d : sys->GetDevices())
        if (std::string(d.SerialNumber().c_str()) == sn) {
          std::cout << "Verified: " << d.ModelName() << " " << sn << " at " << d.IpAddressStr() << "/" << d.SubnetMaskStr() << "\n";
          ok = d.IpAddress() == ip;
        }
    }
    if (!ok) { std::cerr << "Verification failed.\n"; rc = 4; }
  } catch (GenICam::GenericException& e) {
    std::cerr << "Camera error: " << e.what() << "\n";
    rc = 5;
  }
  try { if (dev) sys->DestroyDevice(dev); } catch (...) {}
  try { if (sys) Arena::CloseSystem(sys); } catch (...) {}
  return rc;
}
