---
title: Android Audit with Ghost
categories: [Post-Exploitation]
tags: [android]
author: enty8080
image:
  path: https://user-images.githubusercontent.com/54115104/116760735-6da1e780-aa1e-11eb-8c6f-530386487671.png
---

The EntySec Ghost Framework offers a powerful suite of commands and functions specifically tailored for Android penetration testing, making it a valuable tool for security professionals and ethical hackers focused on Android device security. Here’s a detailed look at some of its core commands and functions, and how they can be applied in security assessments:

## Key Commands and Functions

* Connection Management Commands
    * **connect** - Connects to a target Android device's IP address via the Android Debug Bridge (ADB) if the ADB service is enabled on the device.
    * **disconnect** - Disconnects from the connected device, allowing testers to terminate the connection quickly. 
    * **devices** - Lists all devices currently connected to Ghost Framework, displaying information such as IP addresses and connection statuses.

```entysec
(ghost)> connect 192.168.2.101
[*] Connecting to 192.168.1.101...
[+] Connected to 192.168.1.101!

[i] Type devices to list all connected devices.
[i] Type interact 0 to interact this device.
(ghost)> devices

Connected Devices:

    ID    Host             Port
    0     192.168.1.101    5555
```

These commands form the core of the framework, enabling testers to establish and terminate connections to Android devices.

* Device Information Retrieval Commands
    * **battery** - Shows the battery status of the connected device, which can be useful in determining device activity.
    * **network** - Displays network-related information, such as IP addresses, MAC addresses, and network type (Wi-Fi, cellular, etc.), giving insights into the device's connectivity.

```entysec
(ghost)> interact 0
[*] Interacting with device 0...
[+] Interactive connection spawned!

[*] Loading device modules...
[i] Modules loaded: 13
(ghost: 192.168.1.101)> help

Core Commands:

    Command    Description
    clear      Clear terminal window.
    exit       Exit console.
    help       Show all available commands.
    quit       Exit console.
    source     Execute specific file as source.


Manage Commands:

    Command       Description
    download      Download file from device.
    keyboard      Interact with device keyboard.
    list          List directory contents.
    network       Retrieve network informations.
    openurl       Open URL on device.
    press         Press device button by keycode.
    screenshot    Take device screenshot.
    shell         Execute shell command on device.
    sleep         Put device into sleep mode.
    upload        Upload file to device.

Press Enter for more, 'a' for all, 'q' to quit:
```

These commands help testers understand the target device's setup and network environment, providing a foundational overview before further testing.

* File System Access and Management Commands
    * **list** - Lists files and directories in the specified path on the Android device.
    * **cd** - Changes the current working directory on the target device, allowing testers to navigate through the file system.
    * **download** - Pulls files from the target Android device to the local system.
    * **upload** - Uploads files from the local system to the target Android device.

```entysec
(ghost: 192.168.1.101)> list /

Directory /:

    Name                           Mode     Size       Modification Time
    .                              16877    4096       1970-01-01 01:00:19
    ..                             16877    4096       1970-01-01 01:00:19
    Reserve0                       16877    16384      1970-01-01 01:00:00
    acct                           16749    0          1970-01-01 01:00:06
    bin                            41380    11         2008-12-31 16:00:00
    bugreports                     41380    50         2008-12-31 16:00:00
    cache                          16888    4096       2008-12-31 16:03:01
    charger                        41380    13         2008-12-31 16:00:00
    config                         16877    0          1970-01-01 01:00:01
    d                              41380    17         2008-12-31 16:00:00
    data                           16889    4096       2008-12-31 16:03:03
    default.prop                   41344    23         2008-12-31 16:00:00
    dev                            16877    1560       1970-01-01 01:00:11
    etc                            41380    11         2008-12-31 16:00:00
    file_contexts.bin              33188    763704     2008-12-31 16:00:00
    init                           33256    1711440    2008-12-31 16:00:00
    init.environ.rc                33256    1139       2008-12-31 16:00:00
    init.rc                        33256    29580      2008-12-31 16:00:00
    init.recovery.sun50iw6p1.rc    33256    328        2008-12-31 16:00:00
    init.usb.configfs.rc           33256    7690       2008-12-31 16:00:00
    init.usb.rc                    33256    5646       2008-12-31 16:00:00
Press Enter for more, 'a' for all, 'q' to quit:
```

These commands are essential for file exploration, providing access to data stored on the device, which can be critical when assessing sensitive information exposure.

## Practical Applications in Security Testing

* Network Security Testing: Ghost Framework can test the security of the ADB protocol, especially if the device is inadvertently exposed to public networks.
* Application Security Assessment: By listing installed applications and their versions, testers can identify outdated or potentially vulnerable apps, which could be exploited.
* Forensic Analysis: Ghost Framework’s remote access capabilities enable real-time forensic analysis of an Android device’s file system and active applications, which can be 
  useful for incident response. 

## Ethical and Legal Implications
It’s essential to remember that while Ghost Framework is a powerful tool, it is meant strictly for authorized testing. Unauthorized access to Android devices is illegal and unethical. Always obtain explicit consent before performing any penetration testing, and ensure compliance with relevant laws and regulations.

## Final Notes
Ghost Framework offers deep, hands-on interaction with Android devices, providing security professionals a robust toolkit for analyzing Android security. The framework’s capabilities underscore the importance of securing Android devices, especially by disabling the ADB service on devices that don’t require it and by applying security patches regularly to close known vulnerabilities.
