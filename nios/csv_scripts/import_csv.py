"""Create Infoblox ranges by importing them from a CSV file.

The script obtains Infoblox WAPI credentials and related information
from an Infoblox configuration file in INI format as follows:

  [DEFAULT]
  url = https://gm.example.com/wapi/v2.10/
  valid_cert = False

  [alice]
  userid = alice
  password = jabberwocky

(The valid_cert parameter specifies whether the grid master has a
valid TLS/SSL certificate as opposed to a self-signed certificate.
The other parameters should be self-explanatory.)

On Linux/Unix/MacOS by default the script will look for the file
~/.infoblox.  On Microsoft Windows by default it will look for the
file infoblox.ini in the user's home directory.  You can also specify
the location of the Infoblox configuration file using the --ib-config
option.

The Infoblox configuration file can contain sections for WAPI
connections to different grids and/or using different credentials.
These other connections can be specified using the --ib-profile option
to identify the name of the section of the file to be used.  The file
can also include a special section named "DEFAULT" (as illustrated
above) to provide default values for the other sections.

This script was written for and tested with NIOS 8.5 (WAPI 2.11), but
should work with earlier releases.
"""

# Import the required Python modules.
import argparse
import configparser
import tempfile
import json
import os
import sys
import time
import urllib3
import requests  # NOTE: Must disable pylint E1101 error when checking codes


# Define generic helper functions.
def is_nonblank_string(maybe_string):
    """Return True if maybe_string is a nonblank string."""
    if not isinstance(maybe_string, str):  # not a string at all
        return False
    if not maybe_string:  # an empty string
        return False
    if maybe_string.isspace():  # a string with only whitespace
        return False
    return True


def error_exit(msg, err=None):
    """Print information about an error and exit."""
    if err is not None:
        print(err, file=sys.stderr)
    sys.exit(msg)


def sanitized_filename(pathname):
    """Return sanitized filename without path information."""

    # Get the base filename without the directory path, convert dashes
    # to underscores, and get rid of other special characters.
    filename = ''
    for char in os.path.basename(pathname):
        if char == '-':
            char = '_'
        if char.isalnum() or char == '_' or char == '.':
            filename += char
    return filename


def get_cmd_args():
    """Get arguments from command line or user input and return them."""
    parser = argparse.ArgumentParser(
        description='Convert scopes/reservations to ranges/fixed addresses',
    )

    # Add an option to print the version of the script.
    parser.add_argument(
        '-v',
        '--version',
        action='version',
        version='%(prog)s 0.9',
    )

    # Add options for specifying the location of the configuration file
    # and the user profile to be used within the configuration file.
    parser.add_argument(
        '--ib-config',
        action='store',
        dest='ib_config',
        # No default, value of None means look for the file.
        help='file with Infoblox credentials and WAPI info',
    )
    parser.add_argument(
        '--ib-profile',
        action='store',
        dest='ib_profile',
        # No default, value of None means use first section
        # (other than the DEFAULT section, if present).
        help='profile in Infoblox configuration file',
    )

    # Add positional argument for specifying the CSV import file.
    parser.add_argument(
        action='store',
        dest='csv_path',
        default='',
        help='Pathname of CSV import file',
    )

    # Parse the command line according to the definitions above.
    args = parser.parse_args()

    # Return argument values as a dictionary.
    cmd_args = {}
    cmd_args['ib_config'] = args.ib_config
    cmd_args['ib_profile'] = args.ib_profile
    cmd_args['csv_path'] = args.csv_path
    return cmd_args


# Define Infoblox WAPI-related functions.
def ib_api_error_msg(rsp):
    """Return error message string based on Infoblox WAPI response."""
    try:
        api_err = rsp.json()['text']  # Some responses are JSON ...
    except ValueError:
        api_err = rsp.text  # ... and some are not
    return api_err


def ib_error_print(rsp):
    """Print information about an Infoblox WAPI error."""
    print(
        'HTTP error {} ({})'.format(rsp.status_code, rsp.reason),
        file=sys.stderr,
    )
    print(ib_api_error_msg(rsp), file=sys.stderr)


def ib_error_exit(msg, rsp):
    """Print information about an Infoblox WAPI error and exit."""
    ib_error_print(rsp)
    sys.exit(msg)


def ib_error_continue(msg, rsp):
    """Print information about an Infoblox WAPI error and exit."""
    ib_error_print(rsp)
    print(msg, file=sys.stderr)


def ib_get_config_location(ib_config):
    """Return the location to look for Infoblox configuration info."""
    if is_nonblank_string(ib_config):
        return ib_config
    if 'INFOBLOX_CONFIG_FILE' in os.environ:
        return os.path.expanduser(os.environ['INFOBLOX_CONFIG_FILE'])
    if sys.platform.startswith('win32'):
        return os.path.expanduser('~\\infoblox.ini')
    return os.path.expanduser('~/.infoblox')


def ib_get_config_info(config_file, ib_profile):
    """Get Infoblox WAPI info and return it as a dictionary."""

    # Try to open Infoblox configuration file and read its parameters.
    # NOTE: The config.read() method does not raise an exception if a
    # file is not found or not readable, so instead we explicitly open
    # the file and use the config.read_file() method.
    try:
        config_f = open(config_file, 'r')
    except IOError as err:
        msg = ('Could not open Infoblox configuration'
               ' file "{}"').format(config_file)
        error_exit(msg, err)
    config = configparser.ConfigParser()
    try:
        config.read_file(config_f, config_file)
    except configparser.Error as err:
        msg = ('Could not read Infoblox configuration'
               ' file "{}"').format(config_file)
        error_exit(msg, err)
    config_f.close()

    # Now look for the section of the configuration file containing
    # the desired WAPI profile.  If no profile was specified on the
    # command line, use the first non-DEFAULT section of the
    # configuration file.
    if ib_profile is None:
        if config.sections():
            profile = config.sections()[0]
        else:
            msg = ('No non-DEFAULT section in Infoblox configuration'
                   ' file "{}"').format(config_file)
            error_exit(msg)
    elif ib_profile not in config.sections():
        msg = ('No profile section "{}" in Infoblox configuration'
               ' file "{}"').format(ib_profile, config_file)
        error_exit(msg)
    else:
        profile = ib_profile

    # Look for WAPI access info, supply defaults if needed.
    profile_values = config[profile]
    grid = {}
    grid['url'] = profile_values.get(
        'url',
        'https://gm.example.com/wapi/v1.1/',
    )
    grid['valid_cert'] = profile_values.getboolean('valid_cert', False)
    grid['userid'] = profile_values.get('userid', 'admin')
    grid['password'] = profile_values.get('password', 'infoblox')
    return grid


def ib_authenticate(grid):
    """Access grid, return auth cookie and reference for later use."""
    if not grid['valid_cert']:
        urllib3.disable_warnings()
    try:
        rsp = requests.get(
            grid['url'] + 'grid',
            auth=(grid['userid'], grid['password']),
            verify=grid['valid_cert'],
        )
    except requests.exceptions.RequestException as err:
        error_exit(
            'Error connecting to grid at "{}"'.format(grid['url']),
            err,
        )
    if rsp.status_code != requests.codes.ok:  # pylint: disable=E1101
        ib_error_exit(
            'Cannot connect to grid at "{}"'.format(grid['url']),
            rsp,
        )
    return rsp.cookies['ibapauth'], rsp.json()[0]['_ref']


def ib_init(ib_config, ib_profile):
    """Make first WAPI call, return grid object for future use."""
    config_file = ib_get_config_location(ib_config)
    grid = ib_get_config_info(config_file, ib_profile)
    (grid['auth_cookie'], grid['ref']) = ib_authenticate(grid)
    return grid


def ib_csv_import(grid, csv_path):
    """Import contents of csv_path into grid, return name of error log."""

    # Open the CSV import file and make sure it exists.
    try:
        csv_in = open(csv_path, 'rb')
    except OSError as err:
        error_exit(
            'Error opening CSV file {}'.format(csv_path),
            err,
        )

    # Authentication info for the grid.
    req_cookies = {'ibapauth': grid['auth_cookie']}

    # Initiate a file upload operation, providing a filename (with
    # alphanumeric, underscore, or periods only) for use by the CSV
    # job manager.
    req_params = {
        '_function': 'uploadinit',
        'filename': sanitized_filename(csv_path),
        }
    try:
        rsp = requests.post(
            grid['url'] + 'fileop',
            params=req_params,
            cookies=req_cookies,
            verify=grid['valid_cert'],
        )
    except requests.exceptions.RequestException as err:
        error_exit(
            'Error initiating upload of CSV file {}'.format(csv_path),
            err,
        )
    if rsp.status_code != requests.codes.ok:  # pylint: disable=E1101
        ib_error_exit(
            'Cannot initiate upload of CSV file {}'.format(csv_path),
            rsp,
        )

    # Save the returned URL and token for subsequent requests.
    # NOTE: This WAPI call returns a single dictionary.
    result = rsp.json()
    upload_url = result['url']
    upload_token = result['token']

    # Specify a file handle for the file data to be uploaded.
    req_files = {'filedata': csv_in}

    # Specify the name of the file (not used?).
    req_params = {'name': sanitized_filename(csv_path)}

    # Perform the actual upload.
    # NOTE: This WAPI call does NOT return a JSON result.
    try:
        rsp = requests.post(
            upload_url,
            params=req_params,
            files=req_files,
            cookies=req_cookies,
            verify=grid['valid_cert'],
        )
    except requests.exceptions.RequestException as err:
        error_exit(
            'Error uploading CSV file {}'.format(csv_path),
            err,
        )
    if rsp.status_code != requests.codes.ok:  # pylint: disable=E1101
        ib_error_exit(
            'Cannot upload CSV file {}'.format(csv_path),
            rsp,
        )

    # Initiate the actual import task. Attempt to add the records in
    # the CSV file, and do not terminate on errors.
    req_params = {
        'token': upload_token,
        'doimport': True,
        'on_error': 'CONTINUE',
        'operation': 'INSERT',
        'update_method': 'OVERRIDE'
    }
    try:
        rsp = requests.post(
            grid['url'] + 'fileop?_function=csv_import',
            params=req_params,
            cookies=req_cookies,
            verify=grid['valid_cert']
        )
    except requests.exceptions.RequestException as err:
        error_exit(
            'Error importing CSV file {}'.format(csv_path),
            err,
        )
    if rsp.status_code != requests.codes.ok:  # pylint: disable=E1101
        ib_error_exit(
            'Cannot import CSV file {}'.format(csv_path),
            rsp,
        )

    # Record cvsimporttask object reference and import ID for later use.
    # NOTE: This WAPI call returns a single dictionary.
    result = rsp.json()
    import_ref = result['csv_import_task']['_ref']
    import_id = result['csv_import_task']['import_id']

    # Display ongoing status of CSV import.
    (failed, _) = ib_display_import_progress(grid, import_ref)

    # Return pathname of CSV error log if any errors occurred.
    if failed <= 0:
        return ''
    return ib_get_csv_error_log(grid, import_id)


def ib_display_import_progress(grid, import_ref):
    """Display import_ref progress, return # lines that succeeded, failed."""

    # Authentication info for the grid.
    req_cookies = {'ibapauth': grid['auth_cookie']}

    # Loop checking up to 30 minutes to see if CSV import is complete.
    timeout = 1800
    time_so_far = 0
    while time_so_far < timeout:
        try:
            rsp = requests.get(
                grid['url'] + import_ref,
                cookies=req_cookies,
                verify=grid['valid_cert']
            )
        except requests.exceptions.RequestException as err:
            error_exit(
                'Error checking CSV task {}'.format(import_ref),
                err,
            )
        if rsp.status_code != requests.codes.ok:  # pylint: disable=E1101
            ib_error_continue(
                'Cannot check status of CSV task {}'.format(import_ref),
                rsp,
            )

        # Check to see if import has been completed (end time is set).
        # NOTE: This WAPI call returns a single dictionary.
        result = rsp.json()
        if 'end_time' in result:
            print(('Imported {} lines '
                   '({} failed)').format(
                       result['lines_processed'],
                       result['lines_failed'],
                       )
                 )
            break
        print(
            ('Import {}, processed: {}, '
               'failed: {}').format(
                   result['status'],
                   result['lines_processed'],
                   result['lines_failed'],
               )
        )
        time_so_far = time_so_far + 30
        time.sleep(30)
    return (result['lines_processed'], result['lines_failed'])


def ib_get_csv_error_log(grid, import_id):
    """Download CSV error log for import_id and return pathname."""

    # Authentication info for the grid.
    req_cookies = {'ibapauth': grid['auth_cookie']}

    # Request download of the CSV error log.
    req_params = {'_function': 'csv_error_log'}
    req_data = {
        'import_id': import_id,
    }
    try:
        rsp = requests.post(
            grid['url'] + 'fileop',
            params=req_params,
            data=json.dumps(req_data),
            cookies=req_cookies,
            verify=grid['valid_cert'],
            )
    except requests.exceptions.RequestException as err:
        error_exit(
            'Error requesting error log for CSV import {}'.format(import_id),
            err,
        )
    if rsp.status_code == requests.codes.not_found:  # pylint: disable=E1101
        return ''  # No error log was produced
    if rsp.status_code != requests.codes.ok:  # pylint: disable=E1101
        ib_error_exit(
            'Cannot request error log for CSV import {}'.format(import_id),
            rsp,
        )
    # NOTE: This WAPI call returns a single dictionary.
    result = rsp.json()
    csv_url = result['url']
    csv_token = result['token']

    # Download the error log contents using the provided URL.
    req_headers = {'Content-type': 'application/force-download'}
    try:
        rsp = requests.get(
            csv_url,
            headers=req_headers,
            cookies=req_cookies,
            verify=grid['valid_cert'],
            )
    except requests.exceptions.RequestException as err:
        error_exit(
            'Error downloading error log for CSV import {}'.format(import_id),
            err,
        )
    if rsp.status_code != requests.codes.ok:  # pylint: disable=E1101
        ib_error_exit(
            'Cannot download error log for CSV import {}'.format(import_id),
            rsp,
        )

    # Create unique temporary filename for CSV output, write it out.
    csv_fn = tempfile.mktemp('.csv')
    with open(csv_fn, 'wb') as csv_output:
        csv_output.write(rsp.content)

    # Tell Infoblox system the download is complete.
    req_params = {'_function': 'downloadcomplete'}
    req_data = {'token': csv_token}
    try:
        rsp = requests.post(
            grid['url'] + 'fileop',
            params=req_params,
            data=json.dumps(req_data),
            cookies=req_cookies,
            verify=grid['valid_cert'],
            )
    except requests.exceptions.RequestException as err:
        error_exit(
            ('Error completing error log download for '
             'CSV import {}').format(import_id),
            err,
        )
    if rsp.status_code != requests.codes.ok:  # pylint: disable=E1101
        ib_error_exit(
            ('Cannot complete error log download for '
             'CSV import {}').format(import_id),
            rsp,
        )
    return csv_fn


def main():
    """Main program."""

    # Get arguments from command line.
    cmd_args = get_cmd_args()
    csv_path = cmd_args['csv_path']

    # Initialize WAPI connections for read/write access.
    grid = ib_init(cmd_args['ib_config'], cmd_args['ib_profile'])

    # Attempt to import the CSV file.
    error_log = ib_csv_import(grid, csv_path)
    if is_nonblank_string(error_log):
        print('See {} for CSV import errors'.format(error_log))


# Execute the following when this is run as a script.
if __name__ == '__main__':
    main()
