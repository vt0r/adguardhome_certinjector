# AdGuardHome + LetsEncrypt Certificate Automation
---
It's a simple ruby script that automates LetsEncrypt certificate injection

Usually, you'd run this after your `certbot` renewal as part of your `--post-hook`, allowing you to automatically inject the new key and cert chain into AdGuardHome's YAML config file (example below).

### Recommended: Automatic mode (only works with certbot)
There are only two options, but both are required:
```
Usage: ./adguard_letsencrypt.rb [options]
    -c, --config CONFIGFILE          Path to the AdGuardHome config file
    -d, --domain DOMAIN              Domain name for cert/key
    
```
### Manual mode (can work with any ACMEv2 client)
The full path to the fullchain file and privatekey must be specified:
```
Usage: ./adguard_letsencrypt.rb [options]
    -c, --config CONFIGFILE          Path to the AdGuardHome config file
    -k, --privkey PATH               Path to the private key file
    -f, --fullchain PATH             Path to the fullchain file
    
```

### Example usage with a `certbot` post hook
Ideally, the chained commands would end up in a script to be passed as the single `--post-hook` 'command' to be run, but I've chained all three here to demonstrate the usual workflow:
``` bash
certbot renew --post-hook 'systemctl stop AdGuardHome ; /path/to/adguard_letsencrypt.rb -c /path/to/AdGuardHome.yaml -d yoursite.com ; systemctl start AdGuardHome'
```
