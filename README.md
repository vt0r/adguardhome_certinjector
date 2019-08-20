# AdGuardHome Certificate Injector
---
It's a simple ruby script that automates AdGuardHome certificate injection

Usually, you'd run this after your `certbot` renewal as part of your `--post-hook`, allowing you to automatically inject the new key and cert chain into AdGuardHome's YAML config file (example below).

### Usage
```
Usage: ./adguardhome_certinjector.rb [options]
    -c, --config CONFIGFILE          Path to the AdGuardHome config file
    -d, --domain yoursite.com        Domain name for cert/key - LetsEncrypt (certbot) mode only
    -p, --privatekey privkey.pem     Path to your private key - Manual mode
    -i, --certchain fullchain.pem    Path to your public certificate chain - Manual mode
```

### Examples

#### Use with a `certbot` post hook (LetsEncrypt mode)
Ideally, the chained commands would end up in a script to be passed as the single `--post-hook` 'command' to be run, but I've chained all three here to demonstrate the usual renewal workflow:
``` bash
certbot renew --post-hook '/path/to/AdGuardHome -s stop ; /path/to/adguardhome_certinjector.rb -c /path/to/AdGuardHome.yaml -d yoursite.com ; /path/to/AdGuardHome -s start'
```

#### Use with a certificate chain and key (Manual mode)
``` bash
/path/to/AdGuardHome -s stop
/path/to/adguardhome_certinjector.rb -c /path/to/AdGuardHome.yaml -p /path/to/privkey.pem -i /path/to/fullchain.pem
/path/to/AdGuardHome -s start
```
