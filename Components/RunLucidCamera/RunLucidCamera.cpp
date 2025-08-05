// ======================================================================
// \title  RunLucidCamera.cpp
// \author scalesagx
// \brief  cpp file for RunLucidCamera component implementation class
// ======================================================================

#include "Components/RunLucidCamera/RunLucidCamera.hpp"
#include <Svc/FileDownlink/FileDownlink.hpp>
#include <Fw/Types/ExternalString.hpp>
#include "FpConfig.hpp"
#include "ArenaApi.h"
#include <stdio.h>
#include "SaveApi.h"
#include <string>
#include <sstream>
#include <iomanip>
#include <iostream>



#define TAB1 "  "

// =-=-=-=-=-=-=-=-=-
// =-=- SETTINGS =-=-
// =-=-=-=-=-=-=-=-=-

// pixel format
#define PIXEL_FORMAT BGR8

#define EXPOSURE_TIME 5000.0

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

void SaveImage(Arena::IImage* pImage, const char* filename)
  {

    // convert image
    std::cout << TAB1 << "Convert image to " << GetPixelFormatName(PIXEL_FORMAT) << "\n";

    auto pConverted = Arena::ImageFactory::Convert(
      pImage,
      PIXEL_FORMAT);

    // prepare image parameters
    std::cout << TAB1 << "Prepare image parameters\n";

    Save::ImageParams params(
      pConverted->GetWidth(),
      pConverted->GetHeight(),
      pConverted->GetBitsPerPixel());

    // prepare image writer
    std::cout << TAB1 << "Prepare image writer\n";

    Save::ImageWriter writer(
      params,
      filename);

    // Set image writer to PNG
    //   Set the output file format of the image writer to PNG.
    //   The writer saves the image file as PNG file even without
    //	 the extension in the file name. Aside from this setting, 
    //   compression level can be set between 0 to 9 and the image
    //   can be created using interlacing by changing the parameters. 

    std::cout << TAB1 << "Set image writer to PNG\n";

    writer.SetPng(".png", 0, false);

    // save image
    std::cout << TAB1 << "Save image\n";

    writer << pConverted->GetData();

    // destroy converted image
    Arena::ImageFactory::Destroy(pConverted);
  }

  Arena::DeviceInfo SelectDevice(std::vector<Arena::DeviceInfo>& deviceInfos)
  {
    if (deviceInfos.size() == 1)
    {
      std::cout << "\n"
            << TAB1 << "Only one device detected: " << deviceInfos[0].ModelName() << TAB1 << deviceInfos[0].SerialNumber() << TAB1 << deviceInfos[0].IpAddressStr() << ".\n";
      std::cout << TAB1 << "Automatically selecting this device.\n";
      return deviceInfos[0];
    }

    std::cout << "\nSelect device:\n";
    for (size_t i = 0; i < deviceInfos.size(); i++)
    {
      std::cout << TAB1 << i + 1 << ". " << deviceInfos[i].ModelName() << TAB1 << deviceInfos[i].SerialNumber() << TAB1 << deviceInfos[i].IpAddressStr() << "\n";
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

Arena::ISystem* pSystem;
Arena::IDevice* pDevice;

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
    pSystem->DestroyDevice(pDevice);
    Arena::CloseSystem(pSystem);
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

    std::cout << "Cpp_Save_Png";
    // this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
    try
    {
      

      pDevice->StartStream();
      Arena::IImage* pImage = pDevice->GetImage(2000);

      std::cout << "Commence example\n\n";
      //SaveImage(pImage, FILE_NAME);
      std::string filename = generatefileName();
      SaveImage(pImage, filename.c_str());
      printf("Saved Image to: %s\n",filename.c_str());

      std::string imageDisp = "<img src={% static %}{{"+filename+"}}/>";
      const char* imageDispchar = imageDisp.c_str();

      this->log_ACTIVITY_HI_DebugLogEvent(Fw::LogStringArg(imageDispchar));

      const char* filepathchar = filename.c_str();
      this->m_filename=filepathchar;
      Fw::FileNameString destination("./image.png");
      
      Svc::SendFileResponse resp = this->sendFile_out(0, this->m_filename, destination, 0, 0);
            if (resp.getstatus() != Svc::SendFileStatus::STATUS_OK) {
                // warn, but keep going since it may be an issue with this file but others could
                // make it
                this->log_WARNING_HI_FileSendError(this->m_filename,resp.getstatus());
            }

      std::cout << "\nExample complete\n";

      // clean up example
      pDevice->RequeueBuffer(pImage);
      pDevice->StopStream();
      
    }
    catch (GenICam::GenericException& ge)
    {
      std::cout << "\nGenICam exception thrown: " << ge.what() << "\n";
      exceptionThrown = true;
    }
    catch (std::exception& ex)
    {
      std::cout << "\nStandard exception thrown: " << ex.what() << "\n";
      exceptionThrown = true;
    }
    catch (...)
    {
      std::cout << "\nUnexpected exception thrown\n";
      exceptionThrown = true;
    }

    // std::cout << "Press enter to complete\n";
    // std::cin.ignore();
    // std::getchar();

    if (exceptionThrown) {
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
    // TODO
    // prepare example
    pSystem = Arena::OpenSystem();
    pSystem->UpdateDevices(100);
    std::vector<Arena::DeviceInfo> devices = pSystem->GetDevices();
    //works here
    this->log_ACTIVITY_HI_DebugLogEvent(Fw::LogStringArg("Working"));
    if (devices.size() == 0)
    {
      std::cout << "\nNo camera connected\nPress enter to complete\n";
      // std::getchar();
      // return 0;
      this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::EXECUTION_ERROR);
      return;
    }
    Arena::DeviceInfo selectedDevice = SelectDevice(devices);
    // this->log_ACTIVITY_HI_DebugLogEvent(Fw::LogStringArg("Working 1"));
    pDevice = pSystem->CreateDevice(selectedDevice);
    this->log_ACTIVITY_HI_DebugLogEvent(Fw::LogStringArg("Working 2"));
    // enable stream auto negotiate packet size
    Arena::SetNodeValue<bool>(pDevice->GetTLStreamNodeMap(), "StreamAutoNegotiatePacketSize", true);

    // enable stream packet resend
    Arena::SetNodeValue<bool>(pDevice->GetTLStreamNodeMap(), "StreamPacketResendEnable", true);

    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
  }

  void Components::RunLucidCamera ::
    SET_EXPOSURE_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq,
        F64 param_name
    )
  {
    // TODO
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

    // std::string message = "Set Exposure Time" << exposureTime;
    // F64 fswExposureTime = exposureTime;

    // this->log_ACTIVITY_HI_DebugLogEvent(this->exposureTime);


    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
  }

  void Components::RunLucidCamera ::
    SET_GAIN_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq,
        F64 param_name
    )
  {

    Arena::SetNodeValue<GenICam::gcstring>(
      pDevice->GetNodeMap(),
      "GainAuto",
      "Off");

    Arena::SetNodeValue<GenICam::gcstring>(pDevice->GetNodeMap(), "ConversionGain", "High");

    this->log_ACTIVITY_HI_DebugLogEvent(Fw::LogStringArg("Set Gain To High"));
  
  }

