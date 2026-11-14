// lucid_live_view: live view of the LUCID GigE camera for focusing / framing.
//
//   ./lucid_live_view                   read-only view (changes no camera settings)
//   ./lucid_live_view --flight-settings apply the same image settings F' SETUP_CAMERA
//                                       uses (auto exposure/WB, gamma 0.5, target 50)
//
// Never touches IP configuration. Only one program can control the camera:
// close this before sending jetson_lucidCamera.SETUP_CAMERA from the GDS.
//
// Keys: q / Esc quit   s save snapshot (~/lucid-snapshots)   h toggle overlay
//       c toggle the ResNet-18 crop box
#include "ArenaApi.h"

#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>

#include <chrono>
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <iostream>
#include <string>
#include <sys/stat.h>

static volatile std::sig_atomic_t g_stop = 0;
static void on_signal(int) { g_stop = 1; }

static std::string node(GenApi::INodeMap* nm, const char* name) {
  try {
    GenApi::CNodePtr n = nm->GetNode(name);
    if (!n || !GenApi::IsReadable(n)) return "-";
    return std::string(GenApi::CValuePtr(n)->ToString().c_str());
  } catch (...) { return "-"; }
}

static bool trySet(GenApi::INodeMap* nm, const char* name, const char* value) {
  try {
    GenApi::CNodePtr n = nm->GetNode(name);
    if (!n || !GenApi::IsWritable(n)) return false;
    GenApi::CValuePtr(n)->FromString(value);
    return true;
  } catch (...) { return false; }
}

// Variance of the Laplacian on the central region: higher = sharper.
static double sharpness(const cv::Mat& bgr) {
  cv::Mat small, gray, lap;
  int s = std::min(bgr.cols, bgr.rows);
  cv::Rect c((bgr.cols - s) / 2, (bgr.rows - s) / 2, s, s);
  cv::resize(bgr(c), small, cv::Size(512, 512), 0, 0, cv::INTER_AREA);
  cv::cvtColor(small, gray, cv::COLOR_BGR2GRAY);
  cv::Laplacian(gray, lap, CV_64F);
  cv::Scalar mean, stddev;
  cv::meanStdDev(lap, mean, stddev);
  return stddev[0] * stddev[0];
}

static void text(cv::Mat& img, const std::string& s, int line, double scale) {
  cv::Point p(12, static_cast<int>((line + 1) * 34 * scale));
  cv::putText(img, s, p, cv::FONT_HERSHEY_SIMPLEX, scale, cv::Scalar(0, 0, 0), static_cast<int>(5 * scale), cv::LINE_AA);
  cv::putText(img, s, p, cv::FONT_HERSHEY_SIMPLEX, scale, cv::Scalar(255, 255, 255), static_cast<int>(2 * scale), cv::LINE_AA);
}

int main(int argc, char** argv) {
  std::cout << std::unitbuf;  // show messages immediately, also when logged to a file
  bool flight = false;
  for (int i = 1; i < argc; i++) {
    if (!std::strcmp(argv[i], "--flight-settings")) {
      flight = true;
    } else {
      bool help = !std::strcmp(argv[i], "-h") || !std::strcmp(argv[i], "--help");
      (help ? std::cout : std::cerr)
          << "usage: " << argv[0] << " [--flight-settings]\n"
          << "  (no option)        read-only view; changes no camera settings\n"
          << "  --flight-settings  apply F' SETUP_CAMERA image settings first (auto exposure/WB,\n"
          << "                     gamma 0.5, target brightness 50); never touches IP settings\n"
          << "keys: q/Esc quit, s snapshot (~/lucid-snapshots), h overlay, c ResNet crop box\n";
      return help ? 0 : 1;
    }
  }
  std::signal(SIGINT, on_signal);
  std::signal(SIGTERM, on_signal);

  Arena::ISystem* sys = nullptr;
  Arena::IDevice* dev = nullptr;
  int rc = 0;
  try {
    sys = Arena::OpenSystem();
    std::vector<Arena::DeviceInfo> devs;
    for (int t = 0; t < 5 && devs.empty(); t++) { sys->UpdateDevices(1000); devs = sys->GetDevices(); }
    if (devs.empty()) {
      std::cerr << "No LUCID camera found on the network.\n";
      Arena::CloseSystem(sys);
      return 2;
    }
    Arena::DeviceInfo info = devs[0];  // SDK getters are non-const
    std::string title = std::string("LUCID ") + info.ModelName().c_str() + " " + info.SerialNumber().c_str() +
                        " @ " + info.IpAddressStr().c_str();
    std::cout << "Found " << title << "\n";
    try {
      dev = sys->CreateDevice(info);
    } catch (GenICam::GenericException& e) {
      std::cerr << "Could not open the camera: " << e.what() << "\n";
      if (std::string(info.IpAddressStr().c_str()).rfind("169.254.", 0) == 0) {
        std::cerr << "The camera fell back to a link-local address (" << info.IpAddressStr()
                  << "), so 10.3.2.x machines can't reach it.\n"
                  << "Restore its persistent IP from the repo root:  make camera-set-ip ip=10.3.2.4\n";
      } else {
        std::cerr << "Another program (probably the Jetson flight software after SETUP_CAMERA) controls it.\n"
                  << "On the Jetson: sudo systemctl restart jetson-deployment   (don't send SETUP_CAMERA until done here)\n";
      }
      Arena::CloseSystem(sys);
      return 3;
    }

    GenApi::INodeMap* tl = dev->GetTLStreamNodeMap();
    trySet(tl, "StreamAutoNegotiatePacketSize", "1");
    trySet(tl, "StreamPacketResendEnable", "1");
    trySet(tl, "StreamBufferHandlingMode", "NewestOnly");
    GenApi::INodeMap* nm = dev->GetNodeMap();
    if (flight) {
      int n = trySet(nm, "ExposureAuto", "Continuous") + trySet(nm, "BalanceWhiteEnable", "1") +
              trySet(nm, "BalanceWhiteAuto", "Continuous") + trySet(nm, "GammaEnable", "1") +
              trySet(nm, "Gamma", "0.5") + trySet(nm, "TargetBrightness", "50");
      std::cout << "Applied flight image settings (" << n << "/6)\n";
    }

    const std::string win = title;
    cv::namedWindow(win, cv::WINDOW_NORMAL | cv::WINDOW_KEEPRATIO);
    cv::resizeWindow(win, 1280, 960);

    std::string snapdir = std::string(std::getenv("HOME") ? std::getenv("HOME") : ".") + "/lucid-snapshots";
    bool overlay = true, cropbox = true;
    long frames = 0, incomplete = 0;
    double best = 0, fps = 0;
    auto t_last = std::chrono::steady_clock::now();
    long frames_at_last = 0;
    cv::Mat shown;          // latest frame (complete or not) for display
    bool shown_complete = false;
    double sharp = 0;
    long timeouts = 0;
    auto t_status = std::chrono::steady_clock::now();

    // Put the window on screen right away. OpenCV only maps a window on the
    // first imshow(), and on a lossy link the first complete frame can take a
    // while, which looked like "nothing opens".
    auto placeholder = [&](const std::string& msg) {
      cv::Mat p(720, 960, CV_8UC3, cv::Scalar(40, 40, 40));
      text(p, title, 0, 0.75);
      text(p, msg, 2, 0.75);
      text(p, "q = quit", 4, 0.75);
      cv::imshow(win, p);
      cv::waitKey(1);
    };
    placeholder("Starting stream...");

    dev->StartStream();
    std::cout << "Streaming. Keys: q quit, s snapshot, h overlay, c crop box\n";
    while (!g_stop) {
      Arena::IImage* img = nullptr;
      try {
        img = dev->GetImage(3000);
      } catch (GenICam::TimeoutException&) {
        timeouts++;
        std::cerr << "timeout waiting for a frame (" << timeouts << ")\n";
        if (shown.empty()) placeholder("No frames yet (timeouts: " + std::to_string(timeouts) + "). Check the camera link.");
        int k = cv::waitKey(1) & 0xff;
        if (k == 'q' || k == 27) break;
        continue;
      }
      frames++;
      bool complete = !img->IsIncomplete();
      if (!complete) incomplete++;
      // Show incomplete frames too (lost packets show as streaks): still fine for
      // framing, but excluded from the sharpness score.
      try {
        Arena::IImage* bgr = Arena::ImageFactory::Convert(img, BGR8);
        cv::Mat m(static_cast<int>(bgr->GetHeight()), static_cast<int>(bgr->GetWidth()), CV_8UC3,
                  const_cast<uint8_t*>(bgr->GetData()));
        if (complete || !shown_complete || shown.empty()) {
          shown = m.clone();
          shown_complete = complete;
        }
        Arena::ImageFactory::Destroy(bgr);
      } catch (GenICam::GenericException& e) {
        std::cerr << "convert failed: " << e.what() << "\n";
      }
      dev->RequeueBuffer(img);
      if (shown.empty()) { if ((cv::waitKey(1) & 0xff) == 'q') break; continue; }

      auto now = std::chrono::steady_clock::now();
      double dt = std::chrono::duration<double>(now - t_last).count();
      if (dt >= 1.0) { fps = (frames - frames_at_last) / dt; t_last = now; frames_at_last = frames; }
      if (std::chrono::duration<double>(now - t_status).count() >= 5.0) {
        t_status = now;
        std::printf("[status] %.1f fps, %ld frames, %ld incomplete (%.0f%%), sharpness %.0f (best %.0f)\n", fps,
                    frames, incomplete, 100.0 * incomplete / frames, sharp, best);
        std::fflush(stdout);
      }

      if (complete) {
        sharp = sharpness(shown);
        best = std::max(best, sharp);
      }
      cv::Scalar mean = cv::mean(shown);
      cv::Mat view = shown.clone();
      double sc = view.cols / 1280.0;
      if (!shown_complete) {
        text(view, "INCOMPLETE FRAME (lost packets) - waiting for a complete one", 5, sc);
        cv::putText(view, "INCOMPLETE", cv::Point(12, static_cast<int>(6 * 34 * sc + 20 * sc)),
                    cv::FONT_HERSHEY_SIMPLEX, 1.6 * sc, cv::Scalar(0, 0, 255), static_cast<int>(4 * sc), cv::LINE_AA);
      }
      if (cropbox) {
        // ResNet-18 sees the central square: shorter side * 0.875 (resize 256, crop 224)
        int s = static_cast<int>(std::min(view.cols, view.rows) * 0.875);
        cv::rectangle(view, cv::Rect((view.cols - s) / 2, (view.rows - s) / 2, s, s), cv::Scalar(0, 255, 255),
                      static_cast<int>(3 * sc));
      }
      if (overlay) {
        char b[256];
        std::snprintf(b, sizeof b, "%.1f fps   frames %ld   incomplete %ld (%.0f%%)", fps, frames, incomplete,
                      100.0 * incomplete / frames);
        text(view, b, 0, sc);
        std::snprintf(b, sizeof b, "SHARPNESS %.0f   (best %.0f)  <- turn focus ring to maximize", sharp, best);
        text(view, b, 1, sc);
        std::snprintf(b, sizeof b, "brightness %.0f/255   exposure %s us   gain %s   gamma %s", (mean[0] + mean[1] + mean[2]) / 3,
                      node(nm, "ExposureTime").c_str(), node(nm, "Gain").c_str(), node(nm, "Gamma").c_str());
        text(view, b, 2, sc);
        if (cropbox) text(view, "yellow box = region ResNet-18 classifies", 3, sc);
      }
      cv::imshow(win, view);
      int k = cv::waitKey(1) & 0xff;
      if (k == 'q' || k == 27) break;
      if (k == 'h') overlay = !overlay;
      if (k == 'c') cropbox = !cropbox;
      if (k == 's') {
        mkdir(snapdir.c_str(), 0755);
        char name[64];
        std::time_t t = std::time(nullptr);
        std::strftime(name, sizeof name, "/snapshot_%Y%m%d_%H%M%S.png", std::localtime(&t));
        cv::imwrite(snapdir + name, shown);
        std::cout << "saved " << snapdir << name << "\n";
      }
      // Window closed with the X button: the property query returns -1 once the
      // window no longer exists (WND_PROP_VISIBLE isn't supported by every backend).
      try {
        if (cv::getWindowProperty(win, cv::WND_PROP_AUTOSIZE) < 0) break;
      } catch (...) { break; }
    }
    dev->StopStream();
  } catch (GenICam::GenericException& e) {
    std::cerr << "Camera error: " << e.what() << "\n";
    rc = 4;
  } catch (std::exception& e) {
    std::cerr << "Error: " << e.what() << "\n";
    rc = 4;
  }
  // Always release the camera so the flight software can take it back.
  try { if (dev) { try { dev->StopStream(); } catch (...) {} sys->DestroyDevice(dev); } } catch (...) {}
  try { if (sys) Arena::CloseSystem(sys); } catch (...) {}
  cv::destroyAllWindows();
  std::cout << "Camera released.\n";
  return rc;
}
