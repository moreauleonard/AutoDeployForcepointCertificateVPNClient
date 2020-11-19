# Powershell Scripts for Forcepoint VPN Clients

This powershell scripts are useful to deploy VPN authentication by certificate, for Forcepoint VPN Client.

## Installation

Make sur that openssl is installed on your computer and accessible through PATH  
```bash
openssl
```

## Usage
### Create CSR and private key
Creating CSR and associated private key is the first step.  
CSR will be send to the SMC for signing and private key will be used to later authenticate user  
```powershell
.\Create-Csr-And-Privkey.ps1
```
### Sign certificate with Forcepoint SMC
TODO screenshots

### (Optional) Create PFX
If you want to use pfx and not plaintext crt and privatekey, run
```powershell
.\Create-Multiple-Pfx.ps1
```

### Deploy VPN on user computer
Script must be run with user session.  
To do so, either make the user launch deploy script manually  
or, create a scheduled task that will launch script impersonating user, on user computer.  
#### PFX
```powershell
.\Deploy-VPN-Pfx.ps1
```
#### Separate certificate and private key
```powershell
.\Deploy-VPN-Crt.ps1
```
## Contributing
Pull requests are welcome.

## License
To be defined