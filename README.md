# Quickadcs
Moving beyond password to passwordless

# Overview

Nowadays MFA is not enough to protect you agaisnt phishing attacks.                                                                 Now, All security frameworks pushing all organizations to use phishing-resistant multi-facteur authentification (MFA).              And for good reason, As phishing attacks continue to grow, finding a MFA solution that is unphishable is growing in importance.

It can be hard to keep up with what factors are phishable and which are not.                                                        keep in mind, anything that is stored outside the device (a password) or ever is in transit (like a text message) can be phished, whereas things that never leave the device (cryptographic keys) or your body (biometrics) can not.

# MFA Factors : Phishable and Unphishable

|         phishable factors       |       Unphishable factors      |
| ------------------------------- | ------------------------------ |
| `Time-based one-time passwords` | `Biometrics`                   |
| `SMS text messages`             | `Cryptographic security keys`  |
| `Push notifications`            | `Device-level security checks` |
| `Magic links`                   | `Hardware security keys`       |
| `Passwords`                     |                                |
| `Security questions`            |                                |

# Quickadcs : How to use it

Before smartcard login certificates can be requested and loaded to YubiKeys, several steps need to be completed, including creating smartcard login templates and publishing the templates in the certification authority.                                              

That's why I wrote Quickadcs, it's a PowerShell script, it helps you to deploy a Public Key Infrastructure, PKI and provisioning a Smartcard certificate template. The idea behind Quickadcs is to simplify implementation of Active Directory Passwordless Authentication with Yubikey.

# Requirements :  Tools and Environments

For the hardware constraint, I used Proxmox VE to complete this test.                                                               You'll find attached a PDF file named additional Yubikey Passwordless to know more about tools I used. Some requirements must be met.

- Domain Controller
- YubiKey 5C NFC
- YubiKey mini-drivers
- YubiKey Manager
- Spice Guest tool
- Virt-viewer

# Notice that : 

- On the virtual machines these tools must be installed Yubikey minidriver and Spice Guest tool.
- On the management machine the tools must be installed Yubikey manager-yt and Virt-viewer.
- You'll find these tools in Tools folder.

# References

- https://github.com/GoateePFE/ADCSTemplate
- https://www.yubico.com/
- https://support.yubico.com/s/article/Setting-up-Windows-Server-for-YubiKey-PIV-authentication
- https://www.corbado.com/blog/passkeys-passwordless-phishing-resistant-mfa
