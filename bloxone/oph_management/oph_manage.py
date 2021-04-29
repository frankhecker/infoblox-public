#!/usr/bin/python3
"""oph_manage: Manage a BloxOne on-prem host."""


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


def b1_enable_app(app_type, b1_handle, ip_address='', name=''):
    """Enable an application on an on-prem host."""

    # Must be for a supported application type.
    if app_type not in B1_SUPPORTED_APP_TYPES:
        sys.exit('b1_enable_app: unsupported application type')

    # Look for the on-prem host.
    oph = b1_find_oph(b1_handle, ip_address, name)
    if oph == {}:
        return False

    # If the on-prem host already has the application enabled, there's
    # no need to do anything.
    for app in oph.get('applications', {}):
        if app['application_type'] == app_type:
            if app['disabled'] == '0':
                print('{}{}: app already enabled'.format(name, ip_address))
                return True

    # Update on-prem host to enable application (but not start it).
    # NOTE: The display name must be supplied even if not changing.
    oph_id = oph['id']
    oph_body = {
        'display_name': oph['display_name'],
        'applications': [
            {
                'application_type': app_type,
                'disabled': '0',
                'state': {
                    'desired_state': '0',
                }
            }
        ],
    }
    resp = b1_handle.update(
        '/on_prem_hosts',
        id=oph_id,
        body=json.dumps(oph_body),
    )
    if resp.status_code != 201:
        b1_error_exit('b1_enable_app: error enabling app', resp)
    return True


def b1_disable_app(app_type, b1_handle, ip_address='', name=''):
    """Disable an application on an on-prem host."""

    # Must be for a supported application type.
    if app_type not in B1_SUPPORTED_APP_TYPES:
        sys.exit('b1_disable_app: unsupported application type')

    # Look for the on-prem host.
    oph = b1_find_oph(b1_handle, ip_address, name)
    if oph == {}:
        return False

    # If the on-prem host does not have the application, or already
    # has the application disabled, there's no need to do anything.
    app_is_present = False
    for app in oph.get('applications', {}):
        if app['application_type'] == app_type:
            app_is_present = True
            if app['disabled'] == '1':
                print('{}{}: app already disabled'.format(name, ip_address))
                return True
    if not app_is_present:
        print('{}{}: app not present'.format(name, ip_address))
        return True

    # Update on-prem host to stop the application and disable it.
    # NOTE: The display name must be supplied even if not changing.
    oph_id = oph['id']
    oph_body = {
        'display_name': oph['display_name'],
        'applications': [
            {
                'application_type': app_type,
                'disabled': '1',
                'state': {
                    'desired_state': '0',
                }
            }
        ],
    }
    resp = b1_handle.update(
        '/on_prem_hosts',
        id=oph_id,
        body=json.dumps(oph_body),
    )
    if resp.status_code != 201:
        b1_error_exit('b1_disable_app: error disabling app', resp)
    return True


def b1_start_app(app_type, b1_handle, ip_address='', name=''):
    """Start an (already-enabled) application on an on-prem host."""

    # Must be for a supported application type.
    if app_type not in B1_SUPPORTED_APP_TYPES:
        sys.exit('b1_enable_app: unsupported application type')

    # Look for the on-prem host.
    oph = b1_find_oph(b1_handle, ip_address, name)
    if oph == {}:
        return False

    # The on-prem host must already have the application enabled.
    # No need to do anything if the application is already started.
    app_enabled = False
    for app in oph.get('applications', {}):
        if app['application_type'] == app_type:
            if app['disabled'] == '0':
                app_enabled = True
                if app['state']['current_state'] == '1':
                    print('{}{}: app already started'.format(name, ip_address))
                    return True
    if not app_enabled:
        print('{}{}: app not enabled'.format(name, ip_address))
        return False

    # Update the on-prem host to start the application.
    # NOTE: The display name must be supplied even if not changing.
    oph_id = oph['id']
    oph_body = {
        'display_name': oph['display_name'],
        'applications': [
            {
                'application_type': app_type,
                'disabled': '0',
                'state': {
                    'desired_state': '1',
                }
            }
        ],
    }
    resp = b1_handle.update(
        '/on_prem_hosts',
        id=oph_id,
        body=json.dumps(oph_body),
    )
    if resp.status_code != 201:
        b1_error_exit('b1_start_app: error starting app', resp)
    return True


def b1_stop_app(app_type, b1_handle, ip_address='', name=''):
    """Stop (but not disable) an application on an on-prem host."""

    # Must be for a supported application type.
    if app_type not in B1_SUPPORTED_APP_TYPES:
        sys.exit('b1_enable_app: unsupported application type')

    # Look for the on-prem host.
    oph = b1_find_oph(b1_handle, ip_address, name)
    if oph == {}:
        return False

    # No need to do anything if the application is not enabled/started.
    app_present = False
    for app in oph.get('applications', {}):
        if app['application_type'] == app_type:
            app_present = True
            if app['disabled'] == '1':
                print('{}{}: app not enabled'.format(name, ip_address))
                return True
            if app['state']['current_state'] == '0':
                print('{}{}: app already stopped'.format(name, ip_address))
                return True
    if not app_present:
        print('{}{}: app not present'.format(name, ip_address))
        return True

    # Update the on-prem host to stop the application.
    # NOTE: The display name must be supplied even if not changing.
    oph_id = oph['id']
    oph_body = {
        'display_name': oph['display_name'],
        'applications': [
            {
                'application_type': app_type,
                'disabled': '0',
                'state': {
                    'desired_state': '0',
                }
            }
        ],
    }
    resp = b1_handle.update(
        '/on_prem_hosts',
        id=oph_id,
        body=json.dumps(oph_body),
    )
    if resp.status_code != 201:
        b1_error_exit('b1_stop_app: error stopping app', resp)
    return True


def get_args():
    """Get arguments from command line or user input and return them."""

    # Prepare to parse the command line options (if present).
    parser = argparse.ArgumentParser(
        description='Enable/disable/start/stop app on a BloxOne on-prem host',
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

    # Add positional options for action, app, and host.
    parser.add_argument(
        'action',
        action='store',
        help='Action to take (enable, disable, start, stop)',
    )
    parser.add_argument(
        'app',
        action='store',
        help='BloxOne application (DFP, CDC, DHCP, DNS)',
    )
    parser.add_argument(
        'host',
        action='store',
        help='display name or IP address of the on-prem host',
    )

    # Parse the command line according to the definitions above.
    args = parser.parse_args()

    # Check to make sure a valid action was specified.
    action = args.action.lower()
    if action not in ['enable', 'disable', 'start', 'stop']:
        print('Unknown action {}'.format(action))
        parser.print_usage()
        sys.exit(1)

    # Check to make sure a valid application was specified.
    app = args.app.lower()
    if app not in ['cdc', 'dfp', 'dhcp', 'dns']:
        print('Unknown application {}'.format(app))
        parser.print_usage()
        sys.exit(1)

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
    return (config_file, action, app, name, ip_address)


# Main program.
def main():
    """Enable/disable a BloxOne app on an on-prem host"""
    (config_file, action, app, name, ip_address) = get_args()
    b1_handle = bloxone.b1oph(cfg_file=config_file)
    if action == 'enable':
        success = b1_enable_app(
            B1_APP_NAME_TO_TYPE[app],
            b1_handle,
            name=name,
            ip_address=ip_address,
        )
        if success:
            print('{}{}: {} enabled'.format(name, ip_address, app))
        else:
            print('{}{}: could not enable {}'.format(name, ip_address, app))
    elif action == 'disable':
        success = b1_disable_app(
            B1_APP_NAME_TO_TYPE[app],
            b1_handle,
            name=name,
            ip_address=ip_address,
        )
        if success:
            print('{}{}: {} disabled'.format(name, ip_address, app))
        else:
            print('{}{}: could not disable {}'.format(name, ip_address, app))
    elif action == 'start':
        success = b1_start_app(
            B1_APP_NAME_TO_TYPE[app],
            b1_handle,
            name=name,
            ip_address=ip_address,
        )
        if success:
            print('{}{}: {} started'.format(name, ip_address, app))
        else:
            print('{}{}: could not start {}'.format(name, ip_address, app))
    elif action == 'stop':
        success = b1_stop_app(
            B1_APP_NAME_TO_TYPE[app],
            b1_handle,
            name=name,
            ip_address=ip_address,
        )
        if success:
            print('{}{}: {} stopped'.format(name, ip_address, app))
        else:
            print('{}{}: could not stop {}'.format(name, ip_address, app))


# Execute the following when this is run as a script.
if __name__ == '__main__':
    main()
