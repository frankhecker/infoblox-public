"""Export DNS records in format compatible with CSV Global Export Wizard.

This script provides an example of Python code to export DNS records
in a CSV format compatible with that produced by the Global Export
Wizard in NIOS 7.1 and later.

The code as written supports export of A records, but can be extended
to support other record types. At present the code does not support
export of extensible attributes or the full set of fields that can be
associated with A records.

To use this script change the 'url' variable to contain the domain
name or IP address of the grid master, and change the 'id' variable to
contain a userid with WAPI access to the grid master. (The script will
prompt for the corresponding password when run.)

If your grid master uses a TLS/SSL certificate from a commercial CA
then set the variable 'valid_cert' to True. If your grid contains more
than 5,000 records of the type you want to return then set the
variable 'max_results' to the (negative of the) number of records to
return.

This script should work for NIOS 6.12 and later (WAPI 1.7 and later).

"""


# Import the required Python modules.
import requests
import json
import csv
import getpass
import sys


# Fields for each record type.
a_record_fields = [
    'comment',
    'disable',
    'dns_name',
    'ipv4addr',
    'name',
    'ttl',
    'view',
    'zone',
    ]


# Do the actual work.
def wapi_init(url, id, pw, valid_cert):
    """Initialize WAPI connection, return access object."""

    # Attempt to read the grid object.
    r = requests.get(url + 'grid',
                 auth=(id, pw),
                 verify=valid_cert)
    if r.status_code != requests.codes.ok:
        print r.text
        exit_msg = 'Error {} connecting via WAPI: {}'
        sys.exit(exit_msg.format(r.status_code, r.reason))

    # Construct an access object for future WAPI calls.
    wapi_token = {}
    wapi_token['url'] = url
    wapi_token['valid_cert'] = valid_cert
    wapi_token['auth_cookie'] = r.cookies['ibapauth']
    wapi_token['max_results'] = -20000
    return wapi_token


def wapi_get_a_records(wapi_token):
    """Return all A records."""

    req_params = {
                  '_return_fields': ','.join(a_record_fields), 
                  '_max_results': str(wapi_token['max_results']),
                  }
    print req_params

    r = requests.get(wapi_token['url'] + 'record:a',
                     params=req_params,
                     cookies={'ibapauth': wapi_token['auth_cookie']},
                     verify=wapi_token['valid_cert'])

    if r.status_code != requests.codes.ok:
        print r.text
        exit_msg = 'Error {} getting A records: {}'
        sys.exit(exit_msg.format(r.status_code, r.reason))

    a_records = r.json()
    return a_records


def csv_export_a_records(csv_out, a_records):
    """Export A records to a CSV output file."""

    csv_headers = {
        'comment': 'comment',
        'disabled': 'disable',
        'address': 'ipv4addr',
        'name',
        'ttl',
        'view',
        'zone',
    }

    # 
        header_row = ['Address', 'Names', 'Type']
        out_csv.writerow(header_row)



def main():
    """Download DNS records as requested and export them."""

    # Set parameters to access the NIOS WAPI.
    url = 'https://gm.example.com/wapi/v1.7/'  # 1.7 = NIOS 6.12
    id = 'api'  # Userid with WAPI access
    valid_cert = False  # True if GM uses certificate from commercial CA

    # If running on Windows avoid error due to a self-signed cert.
    if sys.platform.startswith('win') and not valid_cert:
        requests.packages.urllib3.disable_warnings()

    # Prompt for the API user password.
    pw = getpass.getpass('Password for user ' + id + ': ')

    # Initialize the WAPI.
    wapi_token = wapi_init(url, id, pw, valid_cert)

    # Get all A records.
    a_records = wapi_get_a_records(wapi_token)
    print a_records

    with open('export-a-records.csv', 'wb') as out_file:
        out_csv = csv.writer(out_file,
                             delimiter=',',
                             quotechar='"',
                             quoting=csv.QUOTE_MINIMAL)
        csv_export_a_records(out_csv, a_records)


if __name__ == '__main__':
    main()
