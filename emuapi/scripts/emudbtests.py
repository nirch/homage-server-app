#!/usr/bin/python
# -*- coding: utf-8 -*-
"""This script is used for testing correctness of emu's databases
"""
import os
import sys
import json
import requests
from boto.s3.connection import S3Connection
import shutil


API_PATH = None
API_PACKAGES_PATH = "packages/full"
API_PACKAGES_URL = None

HOME_PATH = None
TEMP_FILES_PATH = None

BUCKET_NAME = None
s3 = None
bucket = None
aws_access_key = "AKIAIQKZZYTHOJ6NOYDA"
aws_secret_key = "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"

unique_oids = {}


# region - Configuration and setup
def setup_configuration(args):
    global API_PATH, API_PACKAGES_PATH, API_PACKAGES_URL
    global HOME_PATH, TEMP_FILES_PATH
    global s3, bucket, BUCKET_NAME

    if len(args) < 2:
        return False

    env = args[1]

    if env == "dev":
        API_PATH = "http://localhost:9292/emuapi/"
    elif env == "test":
        API_PATH = "http://app-test.emu.im/emuapi/"
    elif env == "prod":
        API_PATH = "http://app.emu.im/emuapi/"
    else:
        print "env parameter missing (must be test or prod)."
        return False

    API_PACKAGES_URL = API_PATH + API_PACKAGES_PATH
    print "Fetching info from %s" % API_PACKAGES_URL

    HOME_PATH = os.path.expanduser("~")
    TEMP_FILES_PATH = os.path.join(HOME_PATH, "Temp")
    return True


def connect_to_s3():
    global bucket
    print "Connecting to bucket: %s" % BUCKET_NAME
    s3 = S3Connection(aws_access_key, aws_secret_key)
    bucket = s3.get_bucket(bucket_name=BUCKET_NAME)


def ensure_temp_folder_exists():
    if not os.path.exists(TEMP_FILES_PATH):
        os.makedirs(TEMP_FILES_PATH)
# endregion


# region - REST API
def fetch_packages_info():
    global BUCKET_NAME
    resp = requests.get(url=API_PACKAGES_URL, headers={"SCRATCHPAD":"true"})
    parsed_info = json.loads(resp.text)
    BUCKET_NAME = parsed_info["bucket_name"]
    return parsed_info
# endregion


# region - Folders and files
def download_temp_folder(package_name):
    path = os.path.join(TEMP_FILES_PATH, package_name)
    return path


def recreate_folder(folder):
    if os.path.exists(folder):
        shutil.rmtree(folder)
    os.makedirs(folder)
    print folder


def package_current_zip_name(pkg, include_extenstion = True):
    name = pkg["name"]
    update = date_string(pkg["last_update"])
    zip_name = "package_%(name)s_%(update)s" % locals()
    if include_extenstion:
        zip_name += ".zip"
    return zip_name


def package_current_zip_key(pkg):
    zip_name = package_current_zip_name(pkg)
    key_name = "zipped_packages/" + zip_name
    return key_name
# endregion


# region - Checking packages
def check_packages_with_info(info):
    for package_info in info["packages"]:
        package_name = package_info["name"]
        package_oid = package_info["_id"]["$oid"]
        print "-" * 40
        print "Checking package %s %s... " % (package_name, package_oid)
        if "dev_only" in package_info and package_info["dev_only"] is True:
            print "Skipping package (dev only)"
            continue

        if is_package_up_to_date(package_info):
            print "OK"
        else:
            print "Missing"

        # Check oid of the package
        validate_oid(package_oid, package_name)

        for emu_info in package_info["emuticons"]:
            check_emu(emu_info)

def check_emu(emu_info):
    oid = emu_info["_id"]["$oid"]
    name = emu_info["name"]
    print "Checking emu: %(name)s" % locals()
    validate_oid(oid, name)

def validate_oid(oid, name):
    global unique_oids
    if oid in unique_oids:
        raise Exception("Duplicate key found %s in %s it is the same as %s" % (oid, name, unique_oids[oid]))
    unique_oids[oid] = name
# endregion


# def download_emuticon_files(emu, package_name, folder):
#     download(package_name, emu.get("source_back_layer"), folder)
#     download(package_name, emu.get("source_front_layer"), folder)
#     download(package_name, emu.get("source_user_layer_mask"), folder)


# def download(package_name, file_name, folder):
#     if file_name is None:
#         return

#     key_name = "packages/%s/%s" %(package_name, file_name)
#     k_s3 = bucket.get_key(key_name)
#     if k_s3 is None:
#         print "Missing resource: %s" % key_name
#         print "aborting..."
#         exit(1)

#     print key_name, "downloading...",
#     k_s3.get_contents_to_filename(os.path.join(folder, file_name))
#     print "!"
# endregion


# region - Helper methods
def date_string(date):
    date = str(date)[:19]
    date = date.replace(" ", "_").replace("-", "").replace(":", "").replace("T","_")
    return date



def is_package_up_to_date(pkg):
    key_name = package_current_zip_key(pkg)
    print key_name,
    k = bucket.get_key(key_name)
    if k is None:
        raise Exception("Package zip file not up to date: %s" % key_name)
        return False
    else:
        return True
# endregion


# region - Help info
def show_help_info():
    info = """

Usage: python emudbtests.py <env>

-----------
Parameters:
-----------
<env>
    test or prod for test environment or production environment

----------------
What does it do:
----------------
    1) Gets info from emuapi about all packages.
    2) Checks for each package if a zip file is available and up to date.
    3) Checks if all objects' ids are unique.
"""
    print info
# endregion

if __name__ == "__main__":
    if setup_configuration(sys.argv):
        info = fetch_packages_info()
        connect_to_s3()
        check_packages_with_info(info)
        print "Done"
    else:
        show_help_info()