# MAUCacheAdmin
<b>Microsoft AutoUpdate Cache Admin</b>

Purpose: Downloads MAU collateral and packages from the Office CDN to a local web server</br>
Usage: MAUCacheAdmin --CachePath:<path> [--CheckInterval:<minutes>] [--HTTPOnly] [--NoCollateral]</br>
Example: MAUCacheAdmin --CachePath:/Volumes/web/MAU/cache --CheckInterval:60</br>

## maucache.service

A simple systemd server to launch MAUCacheAdmin at boot with a 15 minute interval and auto-restart upon a failure.

This service was written and tested on Ubuntu 16.04 using Nginx. The MAUCacheAdmin script is assumed to be located in `/usr/local/`. Update these values accordingly.

The `ExecStopPost` line has an optional mail command to notify an email address if the service stops. Remove this line if you do not wish to use this option.

To use this service write the `maucache.service` file to `/lib/systemd/system/` and run the following commands:

```
sudo systemctl enable maucache.service
sudo systemctl daemon-reload
sudo systemctl start maucache.service
sudo systemctl status maucache.service
```
