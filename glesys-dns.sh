#!/bin/bash -eu

# GleSYS account name
GLESYS_USER=${GLESYS_USER:-}
# GleSYS API token (create from GleSYS customer dashboard)
GLESYS_TOKEN=${GLESYS_TOKEN:-}

# Performs a HTTP POST to a URL using basic authentication.
# Arguments:
#   1) Data (body)
#   2) URL
#   3) Auth username
#   4) Auth password
#   5) HTTP Header (just 1)
#
# Outputs:
#   HTTP response
function http_post() {
  body="$1"
  url="$2"
  user="$3"
  passwd="$4"
  h1="$5"
  curl -s -u "$user:$passwd" -H "$h1" --data "$body" "$url"
}

# Performs a request to the GleSYS API.
# Globals:
#   GLESYS_USER - GleSYS account username
#   GLESYS_TOKEN - GleSYS API token
#
# Arguments:
#  1) GleSYS API request (JSON)
#  2) API endpoint
#
# Outputs:
#  GleSYS API response to stdout (if successful). Upon failure, error is printed
#  to stderr.
function glesys_rest() {
  body="$1"
  url="https://api.glesys.com/$2"
  h1="Content-Type: application/json"
  response=$(http_post "${body}" "${url}" "${GLESYS_USER}" "${GLESYS_TOKEN}" "${h1}")
  status_code=$(echo "${response}" | jq .response.status.code)

  if [ "${status_code}" != "200" ]; then
    echo "${response}" > /dev/stderr
  else
    echo "${response}"
  fi
}

# Finds domain record ID given domain name, subdomain and record type
# Arguments:
#  1) Domain name
#  2) Subdomain name
#  3) Record type (A, CNAME, ..)
#
# Outputs:
#  GleSYS API response to stdout (if successful). Upon failure, error is printed
#  to stderr.
function glesys_find_domain_record() {
  json="{\"domainname\": \"$1\"}"
  response=$(glesys_rest "${json}" "domain/listrecords")
  if [[ -z "${response}" ]]; then
    echo "error: api request failed" >&2
    exit 1
  fi

  query=".response.records[] | select(.host==\"$2\" and .type==\"$3\") | .recordid"
  echo "${response}" | jq "${query}"
}

# Updates domain record ID with given IPv4 address
# Arguments:
#   1) Domain record ID (as returned by glesys_find_domain_record)
#   2) IPv4 address
#
# Outputs:
#   None
function glesys_update_domain_record() {
  json="{\"recordid\":\"$1\",\"data\":\"$2\"}"
  response=$(glesys_rest "${json}" "domain/updaterecord")
}

# Uses ydns.io service to determine public IP (v4)
# Arguments:
#   None
#
# Outputs:
#   Public IPv4 address
function get_current_ipv4() {
  curl -4 --silent https://ydns.io/api/v1/ip
}


# Prints script usage information
# Arguments:
#   None
#
# Outputs:
#   Usage info
function usage() {
  cat << EOF
usage: $(basename "$0") <domain> [<ip-addr>]
Update A-record for <domain> to <ip-addr> using GleSYS API.
If <ip-addr> is not specified, public IPv4 is detected and used.

GLESYS_USER and GLESYS_TOKEN (API token) must be set to your GleSYS
credentials. Tokens can be created via the GleSYS dashboard.
EOF
}

function main() {
  full_domain=${1:-}
  ip_addr=${2:-}

  if [ -z "${full_domain}" ]; then
    usage
    exit 0
  fi

  domain="$(echo "${full_domain}" | rev | cut -d . -f 1,2 | rev)"
  subdomain="$(echo "${full_domain}" | rev | cut -d . -f 3- | rev)"

  if [ -z "${subdomain}" ]; then
    subdomain="@"
  fi

  if [ -z "$GLESYS_USER" ]; then
    echo "error: GLESYS_USER is not set" >&2
    usage
    exit 1
  fi

  if [ -z "$GLESYS_TOKEN" ]; then
    echo "error: GLESYS_TOKEN is not set" >&2
    usage
    exit 1
  fi

  if ! jq --version > /dev/null 2>&1; then
    echo "error: jq not installed" >&2
    exit 1
  fi

  if [[ -z "${ip_addr}" ]]; then
    ip_addr=$(get_current_ipv4)
    echo "No IP address specified, detected public IPv4 address ${ip_addr}"
  fi

  echo -n "Searching for A-record $subdomain in domain $domain..."
  record_id=$(glesys_find_domain_record "${domain}" "${subdomain}" "A")
  if [[ -z "${record_id}" ]]; then
    echo "FAIL"
    exit 1
  else
    echo "${record_id}"
  fi
  echo -n "Updating ${full_domain} -> ${ip_addr}..."
  glesys_update_domain_record "${record_id}" "${ip_addr}"
  echo "OK"
}

main "$@"
