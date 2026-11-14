// ======================================================================
// \title  RunLucidCamera.cpp
// \author scalesagx
// \brief  cpp file for RunLucidCamera component implementation class
// ======================================================================

#include "Components/RunLucidCamera/RunLucidCamera.hpp"
#include <Svc/FileDownlink/FileDownlink.hpp>
#include <Fw/Types/ExternalString.hpp>
#include "Fw/FPrimeBasicTypes.hpp"
#include "ArenaApi.h"
#include <stdio.h>
#include "SaveApi.h"
#include <string>
#include <sstream>
#include <iomanip>
#include <iostream>
#include <cstdlib>
#include <sys/wait.h>



#define TAB1 "  "

// =-=-=-=-=-=-=-=-=-
// =-=- SETTINGS =-=-
// =-=-=-=-=-=-=-=-=-

// pixel format
#define PIXEL_FORMAT BGR8

#define EXPOSURE_TIME 5000.0

// Image-quality defaults applied by SETUP_CAMERA. Chosen on the testbench
// PHX032S-C (BayerRG8) so frames look like the ordinary sRGB photos ResNet-18
// was trained on: gamma 1.0 (the camera default) gives dark, linear images;
// gamma 0.5 with auto-exposure target 50 gave mean ~123/255 with <0.2% clipping.
#define DEFAULT_GAMMA "0.5"
#define DEFAULT_TARGET_BRIGHTNESS "50"

// SAVE_PNG retries until it gets a frame with no lost GigE packets.
#define CAPTURE_TIMEOUT_MS 3000
#define CAPTURE_MAX_ATTEMPTS 30

// Set a GenICam node from a string, if this camera model has it and it is
// writable. Returns false (never throws) so one missing node doesn't abort setup.
static bool trySetNode(GenApi::INodeMap* nodeMap, const char* name, const char* value)
{
  try {
    GenApi::CNodePtr node = nodeMap->GetNode(name);
    if (!node || !GenApi::IsWritable(node)) {
      return false;
    }
    GenApi::CValuePtr(node)->FromString(value);
    return true;
  } catch (GenICam::GenericException&) {
    return false;
  }
}

const std::string IMX_IP_ADDRESS = "10.3.2.10";
const std::string jetson_base_path = "/home/scales/fprime-scales-ref/build-artifacts/python/";
// file name
//#define FILE_NAME "Images/image.png" //make parameter later
//also change to make a new image each time and not just replace the previous one


// CREATE COUNTER FOR FILENAME
static int imageCounter = 0;
// function to gneerate fileName
std::string generatefileName(){
  std::ostringstream oss;
  oss << "Images/image_" << std::setw(4) << std::setfill('0') << imageCounter++ << ".png";
  return oss.str();
}

// Helper function to copy image to IMX via scp
int copyImageToImx(const std::string& imagePath){
  const std::string fullLocalPath = jetson_base_path + imagePath;
  const std::string remotePath = "root@" + IMX_IP_ADDRESS + ":/root/image.png";


  std::ostringstream cmd;

  cmd
    << "scp "
    << "-o BatchMode=yes "
    << "-o ConnectTimeout=5 "
    << "-o StrictHostKeyChecking=no "
    << "'" << fullLocalPath << "' "
    << remotePath;

  // std::cout << "Running SCP command: " << cmd.str() << std::endl;

  int ret = std::system(cmd.str().c_str());

  if (ret == -1) {
    // std::cout << "SCP failed: system() call failed\n";
    return -1;
  }

  if (WIFEXITED(ret)) {
    return WEXITSTATUS(ret);
  }

  return -1;
}

void SaveImage(Arena::IImage* pImage, const char* filename)
  {

    // convert image
    // std::cout << TAB1 << "Convert image to " << GetPixelFormatName(PIXEL_FORMAT) << "\n";

    auto pConverted = Arena::ImageFactory::Convert(
      pImage,
      PIXEL_FORMAT);

    // prepare image parameters
    // std::cout << TAB1 << "Prepare image parameters\n";

    Save::ImageParams params(
      pConverted->GetWidth(),
      pConverted->GetHeight(),
      pConverted->GetBitsPerPixel());

    // prepare image writer
    // std::cout << TAB1 << "Prepare image writer\n";

    Save::ImageWriter writer(
      params,
      filename);

    // Set image writer to PNG
    //   Set the output file format of the image writer to PNG.
    //   The writer saves the image file as PNG file even without
    //	 the extension in the file name. Aside from this setting, 
    //   compression level can be set between 0 to 9 and the image
    //   can be created using interlacing by changing the parameters. 

    // std::cout << TAB1 << "Set image writer to PNG\n";

    writer.SetPng(".png", 0, false);

    // save image
    // std::cout << TAB1 << "Save image\n";

    writer << pConverted->GetData();

    // destroy converted image
    Arena::ImageFactory::Destroy(pConverted);
  }

  Arena::DeviceInfo SelectDevice(std::vector<Arena::DeviceInfo>& deviceInfos)
  {
    if (deviceInfos.size() == 1)
    {
      // std::cout << "\n"
      //       << TAB1 << "Only one device detected: " << deviceInfos[0].ModelName() << TAB1 << deviceInfos[0].SerialNumber() << TAB1 << deviceInfos[0].IpAddressStr() << ".\n";
      // std::cout << TAB1 << "Automatically selecting this device.\n";
      return deviceInfos[0];
    }

    // std::cout << "\nSelect device:\n";
    for (size_t i = 0; i < deviceInfos.size(); i++)
    {
      // std::cout << TAB1 << i + 1 << ". " << deviceInfos[i].ModelName() << TAB1 << deviceInfos[i].SerialNumber() << TAB1 << deviceInfos[i].IpAddressStr() << "\n";
    }
    size_t selection = 0;

    // do
    // {
    //   // std::cout << TAB1 << "Make selection (1-" << deviceInfos.size() << "): ";
    //   // std::cin >> selection;

    //   // if (std::cin.fail())
    //   // {
    //   //   std::cin.clear();
    //   //   while (std::cin.get() != '\n')
    //   //     ;
    //   //   std::cout << TAB1 << "Invalid input. Please enter a number.\n";
    //   // }
    //   // else if (selection <= 0 || selection > deviceInfos.size())
    //   // {
    //   //   std::cout << TAB1 << "Invalid device selected. Please select a device in the range (1-" << deviceInfos.size() << ").\n";
    //   // }

    // } while (selection <= 0 || selection > deviceInfos.size());

    return deviceInfos[0];
  }

Arena::ISystem* pSystem = nullptr;
Arena::IDevice* pDevice = nullptr;

// namespace Components {

  // ----------------------------------------------------------------------
  // Component construction and destruction
  // ----------------------------------------------------------------------

  Components::RunLucidCamera ::
    RunLucidCamera(const char* const compName) :
      RunLucidCameraComponentBase(compName)
  {
    
  }

  Components::RunLucidCamera ::
    ~RunLucidCamera()

  {
    if (pSystem != nullptr) {
      if (pDevice != nullptr) {
        pSystem->DestroyDevice(pDevice);
      }
      Arena::CloseSystem(pSystem);
    }
  }

  // ----------------------------------------------------------------------
  // Handler implementations for commands
  // ----------------------------------------------------------------------

  void Components::RunLucidCamera ::
    SAVE_PNG_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq
    )

  {
    // TODO
    // flag to track when an exception has been thrown
    bool exceptionThrown = false;

    if (pDevice == nullptr) {
      this->log_WARNING_HI_CameraError(Fw::LogStringArg("Camera not set up: send SETUP_CAMERA first"));
      this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::EXECUTION_ERROR);
      return;
    }

    try
    {
      pDevice->StartStream();

      // The first buffer after StartStream can be stale, and on a lossy GigE
      // link (e.g. the bench switch strapped to 100 Mb/s, which forces peers
      // to half duplex) frames arrive with missing packets, which show up as
      // horizontal streaks of garbage rows. Discard the first frame, then keep
      // the first complete one.
      pDevice->RequeueBuffer(pDevice->GetImage(CAPTURE_TIMEOUT_MS));
      Arena::IImage* pImage = nullptr;
      int incomplete = 0;
      for (int attempt = 0; attempt < CAPTURE_MAX_ATTEMPTS; attempt++) {
        pImage = pDevice->GetImage(CAPTURE_TIMEOUT_MS);
        if (!pImage->IsIncomplete()) {
          break;
        }
        incomplete++;
        if (attempt + 1 < CAPTURE_MAX_ATTEMPTS) {
          pDevice->RequeueBuffer(pImage);
          pImage = nullptr;
        }
      }
      if (incomplete >= CAPTURE_MAX_ATTEMPTS) {
        this->log_WARNING_HI_CameraError(Fw::LogStringArg(
          "No complete frame in 30 tries (packet loss); saved an INCOMPLETE frame"));
      } else if (incomplete > 0) {
        std::string msg = "Dropped " + std::to_string(incomplete) + " incomplete frame(s) before capture";
        this->log_ACTIVITY_HI_DebugLogEvent(Fw::LogStringArg(msg.c_str()));
      }

      // std::cout << "Commence example\n\n";
      //SaveImage(pImage, FILE_NAME);
      std::string filename = generatefileName();
      SaveImage(pImage, filename.c_str());
      // printf("Saved Image to: %s\n",filename.c_str());
      this->log_ACTIVITY_HI_ImageSaved(Fw::LogStringArg(filename.c_str()));

      std::string imageDisp = "<img src={% static %}{{"+filename+"}}/>";
      const char* imageDispchar = imageDisp.c_str();

      this->log_ACTIVITY_HI_DebugLogEvent(Fw::LogStringArg(imageDispchar));

      const char* filepathchar = filename.c_str();
      this->m_filename=filepathchar;
      Fw::FileNameString destination("./image.png");
      
      Svc::SendFileResponse resp = this->sendFile_out(0, this->m_filename, destination, 0, 0);
            if (resp.get_status() != Svc::SendFileStatus::STATUS_OK) {
                // warn, but keep going since it may be an issue with this file but others could
                // make it
                this->log_WARNING_HI_FileSendError(this->m_filename,resp.get_status());
            }

      // if (copyImageToImx(filename) == 0) {
      //   std::cout << "Image copied to IMX successfully.\n";
      // } else {
      //   std::cout << "Failed to copy image to IMX.\n";
      // }

      // std::cout << "\nExample complete\n";

      // clean up example
      pDevice->RequeueBuffer(pImage);
      pDevice->StopStream();
      
    }
    catch (GenICam::GenericException& ge)
    {
      // std::cout << "\nGenICam exception thrown: " << ge.what() << "\n";
      this->log_WARNING_HI_CameraError(Fw::LogStringArg(ge.what()));
      exceptionThrown = true;
    }
    catch (std::exception& ex)
    {
      // std::cout << "\nStandard exception thrown: " << ex.what() << "\n";
      this->log_WARNING_HI_CameraError(Fw::LogStringArg(ex.what()));
      exceptionThrown = true;
    }
    catch (...)
    {
      // std::cout << "\nUnexpected exception thrown\n";
      this->log_WARNING_HI_CameraError(Fw::LogStringArg("Unexpected exception thrown"));
      exceptionThrown = true;
    }

    // std::cout << "Press enter to complete\n";
    // std::cin.ignore();
    // std::getchar();

    if (exceptionThrown) {
      // Leave the device idle so the next SAVE_PNG can StartStream again
      try { pDevice->StopStream(); } catch (...) {}
      this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::EXECUTION_ERROR);
      return;
    }
    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
    return;



  }

  void Components::RunLucidCamera ::
    SETUP_CAMERA_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq
    )
  {
    if (pDevice != nullptr) {
      // Arena allows one open system per process; re-sending is harmless
      this->log_ACTIVITY_HI_DebugLogEvent(Fw::LogStringArg("Camera already set up"));
      this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
      return;
    }
    try
    {
      if (pSystem == nullptr) {
        pSystem = Arena::OpenSystem();
      }
      // A camera that was just released can take a moment to re-enumerate
      std::vector<Arena::DeviceInfo> devices;
      for (int attempt = 0; attempt < 5 && devices.empty(); attempt++) {
        pSystem->UpdateDevices(1000);
        devices = pSystem->GetDevices();
      }
      if (devices.size() == 0)
      {
        this->log_WARNING_HI_CameraError(Fw::LogStringArg("No camera connected"));
        this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::EXECUTION_ERROR);
        return;
      }
      Arena::DeviceInfo selectedDevice = SelectDevice(devices);
      pDevice = pSystem->CreateDevice(selectedDevice);
      std::string found = "Camera " + std::string(selectedDevice.ModelName().c_str()) + " " +
                          std::string(selectedDevice.SerialNumber().c_str()) + " at " +
                          std::string(selectedDevice.IpAddressStr().c_str());
      this->log_ACTIVITY_HI_DebugLogEvent(Fw::LogStringArg(found.c_str()));

      // Transport: negotiate the largest packet size, re-request lost packets,
      // and hand SAVE_PNG the newest frame instead of a stale queued one.
      GenApi::INodeMap* stream = pDevice->GetTLStreamNodeMap();
      Arena::SetNodeValue<bool>(stream, "StreamAutoNegotiatePacketSize", true);
      Arena::SetNodeValue<bool>(stream, "StreamPacketResendEnable", true);
      trySetNode(stream, "StreamBufferHandlingMode", "NewestOnly");

      // Image quality for ML: auto exposure + auto white balance, sRGB-like
      // gamma. Nodes missing on other camera models are skipped.
      GenApi::INodeMap* nm = pDevice->GetNodeMap();
      int applied = 0;
      applied += trySetNode(nm, "ExposureAuto", "Continuous");
      applied += trySetNode(nm, "BalanceWhiteEnable", "1");
      applied += trySetNode(nm, "BalanceWhiteAuto", "Continuous");
      applied += trySetNode(nm, "GammaEnable", "1");
      applied += trySetNode(nm, "Gamma", DEFAULT_GAMMA);
      applied += trySetNode(nm, "TargetBrightness", DEFAULT_TARGET_BRIGHTNESS);
      std::string msg = "Image defaults applied: " + std::to_string(applied) + "/6 (gamma " DEFAULT_GAMMA
                        ", target " DEFAULT_TARGET_BRIGHTNESS ")";
      this->log_ACTIVITY_HI_DebugLogEvent(Fw::LogStringArg(msg.c_str()));
    }
    catch (GenICam::GenericException& ge)
    {
      this->log_WARNING_HI_CameraError(Fw::LogStringArg(ge.what()));
      this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::EXECUTION_ERROR);
      return;
    }
    catch (std::exception& ex)
    {
      this->log_WARNING_HI_CameraError(Fw::LogStringArg(ex.what()));
      this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::EXECUTION_ERROR);
      return;
    }

    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
  }

  void Components::RunLucidCamera ::
    SET_EXPOSURE_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq,
        F64 param_name
    )
  {
    if (pDevice == nullptr) {
      this->log_WARNING_HI_CameraError(Fw::LogStringArg("Camera not set up: send SETUP_CAMERA first"));
      this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::EXECUTION_ERROR);
      return;
    }
    try
    {
      Arena::SetNodeValue<GenICam::gcstring>(
        pDevice->GetNodeMap(),
        "ExposureAuto",
        "Off");

      double exposureTime = param_name;

      GenApi::CFloatPtr pExposureTime = pDevice->GetNodeMap()->GetNode("ExposureTime");

      if (exposureTime < pExposureTime->GetMin())
      {
        exposureTime = pExposureTime->GetMin();
      }

      if (exposureTime > pExposureTime->GetMax())
      {
        exposureTime = pExposureTime->GetMax();
      }

      pExposureTime->SetValue(exposureTime);
    }
    catch (GenICam::GenericException& ge)
    {
      this->log_WARNING_HI_CameraError(Fw::LogStringArg(ge.what()));
      this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::EXECUTION_ERROR);
      return;
    }

    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
  }

  void Components::RunLucidCamera ::
    SET_GAIN_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq,
        F64 param_name
    )
  {
    if (pDevice == nullptr) {
      this->log_WARNING_HI_CameraError(Fw::LogStringArg("Camera not set up: send SETUP_CAMERA first"));
      this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::EXECUTION_ERROR);
      return;
    }
    try
    {
      Arena::SetNodeValue<GenICam::gcstring>(
        pDevice->GetNodeMap(),
        "GainAuto",
        "Off");

      Arena::SetNodeValue<GenICam::gcstring>(pDevice->GetNodeMap(), "ConversionGain", "High");
    }
    catch (GenICam::GenericException& ge)
    {
      this->log_WARNING_HI_CameraError(Fw::LogStringArg(ge.what()));
      this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::EXECUTION_ERROR);
      return;
    }

    this->log_ACTIVITY_HI_DebugLogEvent(Fw::LogStringArg("Set Gain To High"));
    // Previously missing: without a response the command (and any sequence
    // containing it) waited until timeout.
    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
  }
