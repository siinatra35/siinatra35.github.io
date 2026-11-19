---
title: "Hello, World: Rebooting the Blog"
description: "Turning an old resume page into a place for malware research, HTB writeups, and security notes."
categories: [notes]
tags: [meta]
---

This site used to be my resume. Now it's a blog where I'll post what I'm learning in security.

## What's coming

- **Malware analysis**: taking real samples apart, step by step.
- **Hack The Box writeups**: retired machines only.
- **Research notes**: tools and techniques worth writing down.

## A quick formatting test

Inline code looks like `nmap -sC -sV`, and code blocks look like this:

```bash
nmap -p- --min-rate 5000 -oN scans/all-ports.txt 10.10.10.10
```

```python
import hashlib

def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()
```

> Only test systems you own or have explicit permission to test.
