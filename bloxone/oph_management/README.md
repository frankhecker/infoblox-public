# infoblox-public/bloxone/oph-management

This directory contains useful utilities and scripts for managing
on-prem hosts for BloxOne DDI and the BloxOne Threat Defense cloud
resolver service.

These utilities and scripts have prerequisites as follows:

* Python 3 with the requests and bloxone modules installed.
* An Infoblox Cloud Services Portal (CSP) account licensed for one or
  more of BloxOne DDI, BloxOne Threat Defense Advanced, or BloxOne
  Threat Defense Business Cloud.
* A CSP user account belonging to a group with permissions to manage
  on-prem hosts.
* A valid API key for such a user, typically stored in the file
  .bloxone.ini in the user's home directory, formatted according to
  <https://python-bloxone.readthedocs.io/en/latest/usage.html>.
