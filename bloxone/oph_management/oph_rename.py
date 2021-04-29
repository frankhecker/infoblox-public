#!/usr/bin/python3
"""oph_rename: rename a BloxOne on-prem host."""


# Import the required Python modules.
import argparse
import sys
import os
import json
import bloxone


# BloxOne constants.
B1_OVA_HOST_TYPE = '3'
B1_CONTAINER_HOST_TYPE = '5'

B1_SUPPORTED_HOST_TYPES = [
    B1_OVA_HOST_TYPE,
    B1_CONTAINER_HOST_TYPE,
]

B1_DFP_APP_TYPE = '1'
B1_DNS_APP_TYPE = '2'
B1_DHCP_APP_TYPE = '3'
B1_CDC_APP_TYPE = '7'

B1_SUPPORTED_APP_TYPES = [
    B1_DNS_APP_TYPE,
    B1_DHCP_APP_TYPE,
    B1_DFP_APP_TYPE,
    B1_CDC_APP_TYPE,
]

B1_APP_NAME_TO_TYPE = {
    'cdc': B1_CDC_APP_TYPE,
    'dfp': B1_DFP_APP_TYPE,
    'dhcp': B1_DHCP_APP_TYPE,
    'dns': B1_DNS_APP_TYPE,
}


# Helper functions for BloxOne API error reporting.
def is_ipv4_address(addr):
    """Return True if addr is a valid IPv4 address, False otherwise."""
    if (not isinstance(addr, str)) or (not addr) or addr.isspace():
        return False
    octets = addr.split('.')
    if len(octets) != 4:
        return False
    for octet in octets:
        if not octet.isdigit():
            return False
        octet_value = int(octet)
        if octet_value < 0 or octet_value > 255:
            return False
    return True


def b1_error_msg(resp):
    """Return error message string based on BloxOne API response."""

    try:
        response = resp.json()  # Responses should be in JSON ...
        if not isinstance(response, dict) or 'text' not in response:
            api_err = resp.text
        else:
            api_err = response['text']
    except ValueError:
        api_err = resp.text  # ... but if they're not
    return api_err


def b1_error_print(resp):
    """Print information about an BloxOne API error."""
    print(
        'HTTP error {} ({})'.format(resp.status_code, resp.reason),
        file=sys.stderr,
    )
    print(b1_error_msg(resp), file=sys.stderr)


def b1_error_exit(msg, resp):
    """Print information about a BloxOne API error and exit."""
    b1_error_print(resp)
    sys.exit(msg)


def b1_error_continue(msg, resp):
    """Print information about a BloxOne API error and continue."""
    b1_error_print(resp)
    print(msg, file=sys.stderr)


# Functions to manage on-prem hosts.
def b1_find_oph(b1_handle, ip_address='', name=''):
    """Find an on-prem host by (display) name or IP address."""

    # Must have a valid BloxOne handle and either IP address or name.
    if not isinstance(b1_handle, bloxone.b1oph):
        sys.exit('b1_find_oph: First argument must be bloxone handle')
    if ip_address == '' and name == '':
        sys.exit('b1_find_oph: Must provide IP address or name of OPH')

    # Look for on-prem host using a suitable filter.
    if ip_address == '':
        get_filter = 'display_name=="{}"'.format(name)
    else:
        get_filter = 'ip_address=="{}"'.format(ip_address)
    resp = b1_handle.get('/on_prem_hosts', _filter=get_filter)

    # Check to see if we found an on-prem host.
    oph = {}
    if resp.status_code != 200:
        b1_error_exit('b1_find_oph: error finding on-prem host(s)', resp)
    elif resp.text == '{}':
        print('b1_find_oph: no on-prem hosts match filter', file=sys.stderr)
    else:
        ophs = resp.json()['result']
        if len(ophs) > 1:
            print('b1_find_oph: multiple hosts match filter', file=sys.stderr)
        else:
            oph = ophs[0]
    return oph


def b1_rename_oph(b1_handle, ip_address='', name='', newname=''):
    """Enable an application on an on-prem host."""

    # Must supply a new name.
    if (not isinstance(newname, str)) or (not newname) or newname.isspace():
        sys.exit('b1_rename_oph: new name must be nonblank string')

    # Look for the on-prem host.
    oph = b1_find_oph(b1_handle, ip_address, name)
    if oph == {}:
        return False

    # Update on-prem host to use the new name.
    oph_id = oph['id']
    oph_body = {
        'display_name': newname,
    }
    resp = b1_handle.update(
        '/on_prem_hosts',
        id=oph_id,
        body=json.dumps(oph_body),
    )
    if resp.status_code != 201:
        b1_error_exit('b1_rename_oph: error renaming host', resp)
    return True


def get_args():
    """Get arguments from command line or user input and return them."""

    # Prepare to parse the command line options (if present).
    parser = argparse.ArgumentParser(
        description='Rename a BloxOne on-prem host',
    )

    # Add an option to print the version of the script.
    parser.add_argument(
        '-v',
        '--version',
        action='version',
        version='%(prog)s 0.1',
    )

    # Add an option for specifying the location of the configuration file.
    parser.add_argument(
        '-c',
        '--config',
        action='store',
        dest='config',
        help='file with BloxOne API credentials, related information',
    )

    # Add positional options for host IP address/old name and new name.
    parser.add_argument(
        'host',
        action='store',
        help='display name or IP address of the on-prem host',
    )
    parser.add_argument(
        'newname',
        action='store',
        help='new name for the on-prem host',
    )

    # Parse the command line according to the definitions above.
    args = parser.parse_args()

    # If none specified, look for a default configuration file.
    if args.config:
        config_file = args.config
    elif sys.platform.startswith('win32'):
        config_file = os.path.expanduser('bloxone.ini')
    else:
        config_file = os.path.expanduser('~/.bloxone.ini')

    # Figure out whether the host was specified as name or IP address.
    if is_ipv4_address(args.host):
        ip_address = args.host
        name = ''
    else:
        ip_address = ''
        name = args.host

    # Get the new name.
    newname = args.newname

    return (config_file, name, ip_address, newname)


# Main program.
def main():
    """Rename an on-prem host"""
    (config_file, name, ip_address, newname) = get_args()
    b1_handle = bloxone.b1oph(cfg_file=config_file)
    success = b1_rename_oph(
            b1_handle,
            name=name,
            ip_address=ip_address,
            newname=newname,
    )
    if success:
        print('{}{}: renamed to {}'.format(name, ip_address, newname))
    else:
        print('{}{}: could not rename to {}'.format(name, ip_address, newname))


# Execute the following when this is run as a script.
if __name__ == '__main__':
    main()
