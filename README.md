# Powershell Scripts for Forcepoint VPN Clients (Windows)

This powershell scripts are useful to deploy VPN authentication by certificate, for Forcepoint VPN Client.  
Use case : VPN Client is installed on user computer and authentication is made with username/password  


PFX will be stored on Windows Certificate Store  
CRT will be stored on Forcepoint AppData path  

## Installation

Make sur that openssl is installed on your computer and accessible through PATH  
```bash
openssl
```
openssl is needed to create CSRs, private keys and PFXs.  
It is not needed to import certificate on user computer.

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
Script must be run under user session.  
To do so, either make the user manually launch script  
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
[MIT](https://choosealicense.com/licenses/mit/)