---
title: iOS Evasion Nowadays
categories: [Post-Exploitation]
tags: [seashell, jailbreak, ios, malware]
pin: true
---

Since the development of [SeaShell](https://github.com/entysec/seashell) iOS post-exploitation framework started, I was thinking about evasion techniques that can be applicable to a non-jailbroken (or jailbroken but rootless) iOS systems. So, after few days of brainstorming I came with few ideas that can be used and that I have already implemented in SeaShell.

<p align="center">
<video width="70%" autoplay controls>
  <source src="https://raw.githubusercontent.com/EntySec/SeaShell/main/seashell/data/preview/hook.mp4" type="video/mp4">
Your browser does not support the video tag.
</video>
</p>

## Persistence

Typically, we use `launchctl` to achieve persistence on iOS/macOS. However, on non-jailbroken iOS devices (and even on jailbroken ones nowadays, as they are rootless), the root directory (`/`) is not writable, which means that we cannot write to `/Library/LaunchAgents` or `/Library/LaunchDaemons`. Consequently, we are unable to install a `.plist` file that would launch the payload.

Recognizing the need for a persistence installation method, I came up with an idea: What if we inject the payload into existing user applications? Initially, I considered inserting a dynamic library (`.dylib`) into the bundle executable of an application, but this would require re-signing the binary. Then, I had another idea: we can replace the bundle executable with a custom binary that will first execute the payload and then call the original executable.

Essentially, our custom executable will use the `posix_spawn()` function to execute the payload and then use `execve()` to invoke the original executable. Since `execve()` replaces the current process image with a new one, this is the optimal approach to launch the application. Below, you can find a diagram illustrating this process using the `Calculator.app` as an example.

<p align="center">
  <img width="50%" src="https://raw.githubusercontent.com/EntySec/SeaShell/main/seashell/data/preview/hook.png">
</p>

To perform hooking we need:

* **1.** Patch `Info.plist` and add `CFBundleBase64Hash` containing base64 representation of `<host>:<port>` to connect back to.
* **2.** Move `Calculator` to `Calculator.hooked`. (`CFBundleExecutable` for other applications)
* **3.** Upload custom executable that will perform the loading and call it `Calculator` (`CFBundleExecutable` for other applications).
* **4.** Upload `mussel` payload that will call Pwny and perform connection.
* **5.** Perform `chmod` operations on both custom executable and `mussel`, otherwise `posix_spawn()` will die with `error 13` which is `Permission denied`.

I am concerned that persistence can be called an evasion technique due to the fact that we are injecting our payload into another application infecting it.
