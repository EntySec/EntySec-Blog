---
layout: post
title: HatSploit breakthrough
subtitle: HatSploit Framework 5.0.0 available
gh-repo: entysec/hatsploit
gh-badge: [star, fork]
tags: [hatsploit]
comments: false
---

HatSploit is a modular penetration testing platform that enables you to write, test, and execute exploit code. It provides us a pretty good and advanced platform for developing exploits and building attack chains with specific payloads. We tried to provide the best toolkit for exploit development and penetration testing, because there is no impenetrable system in the world. We decided to merge all methods of delivering payloads, building attack chains and establishing remote connections to one advanced framework.

So, the main question is - How to start working with HatSploit? We have an answer, this guide is for learning how to use HatSploit.

## First Run

First, you need to run HatSploit, for this, open your terminal and type `hsf`. After this, you will see the terms of service message, accept it, and continue.

```
[?] Accept HatSploit Framework Terms of Service? [y/n]
```

After this, HatSploit will ask you to build base databases (for learning about databases, read [Databases Management](https://github.com/EntySec/HatSploit/wiki/Databases-Management)), this means that HatSploit will load all modules, plugins, and payloads and will save them to the base database.

```
[?] Do you want to build and connect base databases? [y/n]
```

After all these setup steps completed, the main HatSploit interface appears.

```
         █▀▀▀▀▀█ ▀▀▀█▄ ▀   █▀▀▀▀▀█
         █ ███ █  ▀▄█▄█ ▄▄ █ ███ █
         █ ▀▀▀ █  ▄▀██ █ ▄ █ ▀▀▀ █
         ▀▀▀▀▀▀▀ █▄▀ █▄▀ █ ▀▀▀▀▀▀▀
         ▀█▄▀█▄▀▄▄▀▄▄  ▀█ ▄▀▄▄▄▄▄▀
         ▀   ▀ ▀▄ ▀ ██  ▀█▄█▀▀█▄▄█
         █ ▀█ ▄▀▄█▀██  ▄▄█▄▀▀▄  ▄▀
         █▀▀▄▄█▀   ▄ ▄▀██ ▄▀▀ ▀█▀█
         ▀ ▀   ▀▀▄▄▄▀▀█  █▀▀▀█ ▀█
         █▀▀▀▀▀█  ▀▄█▀█▀▄█ ▀ █▀  █
         █ ███ █ ██ ██ █▀███▀▀█ █▄
         █ ▀▀▀ █ ▄███▄▀  ▀▄▄██ ███
         ▀▀▀▀▀▀▀ ▀▀▀     ▀▀▀  ▀  ▀
       http://hatsploit.netlify.app/

    --=( HatSploit Framework 5.0.0
--==--=( Developed by EntySec (https://entysec.netlify.app/)
    --=( 66 modules | 51 payloads | 2 plugins
 
HatSploit Tip: Run exec to execute system commands

(hsf)> 
```

## Using Commands

HatSploit has various commands for interacting with its function, you can type `help` or `?` for getting a list of these commands. After doing this, you will see a description for each of them.

```
Core Commands:
 
    Command    Description                              
    -------    -----------                              
    clear      Clear terminal window.                   
    exit       Exit HatSploit Framework.                
    help       Show available commands.                 
    search     Search payloads, modules and plugins.    
```

HatSploit Framework interface has special functions:

* `?` is used to show all loaded interface commands.

* `&` is used to execute commands in the background.

* `!` is used to execute system commands.

```
(hsf)> !whoami
[*] Executing system command: whoami

enty8080
(hsf)>
```

* `:` is used to execute commands from file ([HatSploit Script](https://github.com/EntySec/HatSploit/wiki/HatSploit-Script)).

```
(hsf)> :/home/user/script.hsf
```

* `#` is used for commenting.

```
(hsf)> # just a comment
(hsf)>
```

## Using Run Options

Run options are options that you can select on startup via command-line arguments.

```
usage: hsf [-h] [-c] [--check-modules] [--check-payloads] [--check-plugins]
           [--rest-api] [--host HOST] [--port PORT] [--username USERNAME]
           [--password PASSWORD] [-u] [-s SCRIPT] [--no-exit] [--no-startup]

Modular penetration testing platform that enables you to write, test, and
execute exploit code.

optional arguments:
  -h, --help            show this help message and exit
  -c, --check           Check base modules, payloads and plugins.
  --check-modules       Check only base modules.
  --check-payloads      Check only base payloads.
  --check-plugins       Check only base plugins.
  --rest-api            Start HatSploit REST API server.
  --host HOST           HatSploit REST API server host. [default: 127.0.0.1]
  --port PORT           HatSploit REST API server port. [default: 8008]
  --username USERNAME   HatSploit REST API server username.
  --password PASSWORD   HatSploit REST API server password.
  -u, --update          Update HatSploit Framework.
  -s SCRIPT, --script SCRIPT
                        Execute HatSploit commands from script file.
  --no-exit             Do not exit after script execution.
  --no-startup          Do not execute startup.hsf file.
```

## HatSploit Startup file

HatSploit startup file contains all commands that should be executed on startup. It is placed in the HatSploit workplace - `~/.hsf/startup.hsf` ([HatSploit Script](https://github.com/EntySec/HatSploit/wiki/HatSploit-Script)).

## HatSploit Structure

**HatSploit Modules**

HatSploit is a **modular** framework, so it has the ability to use modules, learn about them here - [HatSploit Modules](https://github.com/EntySec/HatSploit/wiki/HatSploit-Modules).

**HatSploit Payloads**

HatSploit also has payloads, they can be used with modules, learn about them here - [HatSploit Payloads](https://github.com/EntySec/HatSploit/wiki/HatSploit-Payloads).

**HatSploit Plugins**

HatSploit has the ability to customize the main interface and add new commands, for this we developed a plugins mechanism, learn about plugins here - [HatSploit Plugins](https://github.com/EntySec/HatSploit/wiki/HatSploit-Plugins)

## Conclusion

Next step is about using HatSploit modules, plugins and payloads, read about this here - [HatSploit Modules](https://github.com/EntySec/HatSploit/wiki/HatSploit-Modules), [HatSploit Payloads](https://github.com/EntySec/HatSploit/wiki/HatSploit-Payloads) and [HatSploit Plugins](https://github.com/EntySec/HatSploit/wiki/HatSploit-Plugins).
