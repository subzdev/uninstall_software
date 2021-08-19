With this script you can uninstall almost any kind of software installed on your Windows system.

INPUTS
  -list Will list all installed 32-bit and 64-bit software installed on the target machine.
  -list "<software name>" will find a particular application installed giving you the uninstall string and quiet uninstall string if it exists
  -list "<software name>" -u "<uninstall string>" will allow you to uninstall the software from the Windows machine silently
  -list "<software name>" -u "<quiet uninstall string>" will allow you to uninstall the software from the Windows machine silently

EXAMPLE 1
  Follow the steps below via script arguments to find and then uninstall VLC Media Player.
  Step 1: -list "vlc"
  Step 1 result:
    1 results 
    ********** 
    Name: VLC media player
    Version: 3.0.12
    Uninstall String: "C:\Program Files\VideoLAN\VLC\uninstall.exe"
    **********
  Step 2: -list "vlc" -u "C:\Program Files\VideoLAN\VLC\uninstall.exe"
  Step 3: Will get result back stating if the application has been uninstalled or not.
EXAMPLE 2
  For a more complex uninstall of for example the Bentley CONNECTION Client with extra arguments.
  Step 1: -list "CONNECTION Client"
  Step 1 result:
    2 results 
    **********
    Name: CONNECTION Client
    Version: 11.0.3.14
    Silent Uninstall String: "C:\ProgramData\Package Cache\{54c12e19-d8a1-4c26-80cd-6af08f602d4f}\Setup_CONNECTIONClientx64_11.00.03.14.exe" /uninstall /quiet
    **********
    Name: CONNECTION Client
    Version: 11.00.03.14
    Uninstall String: MsiExec.exe /X{BF2011BD-2485-4CBA-BBFB-93205438C75B}
    **********
  Step 2: -list "CONNECTION Client" -u "C:\ProgramData\Package Cache\{54c12e19-d8a1-4c26-80cd-6af08f602d4f}\Setup_CONNECTIONClientx64_11.00.03.14.exe" -args "/uninstall /quiet"
  Step 3: Will get result back stating if the application has been uninstalled or not.
