# glesys-dns

Tool to update a single A-domain record using GleSYS API. Example:

```console
	$ export GLESYS_USER=my_account_name
	$ export GLESYS_TOKEN=ZENK7k2MoPUy6PTekqKyWbgM751wBT2oxQ8EabrJ
	$ glesys-dns.sh my.domain.com 127.0.0.1
```

Requires curl and jq installed (apt-get install curl jq)

This script is loosely based on https://github.com/jakeru/dyndns_glesys

## GleSYS token

The GleSYS token is setup via the GleSYS dashboard (https://cloud.glesys.com/).

The token must be allowed following functions:
* Domain "listrecords"
* Domain "updaterecord"

Every other function should be set to Denied.

## Dynamic DNS
Optionally, the IPv4 address can be left out on the command-line and the script
will try to detect your public IPv4.

```console
	... setup GLESYS_USER and GLESYS_TOKEN ...
	$ glesys-dns.sh my.domain.com
```

Auto-detecting the IP is useful when script is used on a host with dynamic IP.
Run the script periodically using crontab or as a systemd unit.

```console
$ crontab -l
# Edit this file to introduce tasks to be run by cron.
#
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
#
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
#
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
#
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h  dom mon dow   command
GLESYS_USER=....
GLESYS_TOKEN=....

*/30  *   *   *   *  /home/magnus/glesys-dns/glesys-dns.sh my.domain.com > /home/magnus/glesys-dns/my.log 2>&1
```

## Troubleshooting
If any GleSYS API calls fail, the raw API JSON response is printed. Pay
particular attention to the "text" field.

Common problems:
* Bad token permissions.
* Host is not permitted.
* Domain does not exist.