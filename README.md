# glesys-dns

Tool to update a single A-domain record using GleSYS API. Example:

	$ export GLESYS_USER=my_account_name
	$ export GLESYS_TOKEN=ZENK7k2MoPUy6PTekqKyWbgM751wBT2oxQ8EabrJ
	$ glesys-dns.sh my.domain.com 127.0.0.1

Optionally, the IPv4 address can be left out and the script will try to detect
your public IPv4.

	$ glesys-dns.sh my.domain.com

This script is loosely based on https://github.com/jakeru/dyndns_glesys

## GleSYS token

The GleSYS token is setup via the GleSYS dashboard (https://cloud.glesys.com/).

The token must be allowed following functions:
* Domain "listrecords"
* Domain "updaterecord"

Every other function should be set to Denied.

# Troubleshooting

If any GleSYS API calls fail, the raw API JSON response is printed. Pay
particular attention to the "text" field.

Common problems:
* Bad token permissions.
* Host is not permitted.
* Domain does not exist.