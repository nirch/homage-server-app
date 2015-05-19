#!/usr/bin/python
# -*- coding: utf-8 -*-
"""This script is used for creation of zip files containing all current resources
required for packages of the emu app.

The script:

    1) Gets info from emuapi about all packages.
    2) Checks for each package if a zip file is available and up to date.
    3) If a zip file is missing or not up to date on s3 the script will:
        a) Download all required resources.
        b) Validate that all required resources exist (halts on missing resource).
        c) Zip all resources.
        d) Upload the zip file to S3.
"""
import os
import sys
import json
import requests
from boto.s3.connection import S3Connection
import shutil
import copy
import codecs


API_PATH = None
API_PACKAGES_PATH = "packages/full"
API_PACKAGES_URL = None
ONLY_THIS_PACKAGE = None
USE_SCRATCHPAD = True

HOME_PATH = None
TEMP_FILES_PATH = None

BUCKET_NAME = None
s3 = None
bucket = None
aws_access_key = "AKIAIQKZZYTHOJ6NOYDA"
aws_secret_key = "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"


# region - Configuration and setup
def setup_configuration(args):
    global API_PATH, API_PACKAGES_PATH, API_PACKAGES_URL
    global HOME_PATH, TEMP_FILES_PATH
    global s3, bucket, BUCKET_NAME
    global ONLY_THIS_PACKAGE
    global USE_SCRATCHPAD

    if len(args) < 2:
        return False

    env = args[1]

    if env == "dev":
        API_PATH = "http://localhost:9292/emuapi/"
        USE_SCRATCHPAD = True
    elif env == "test":
        API_PATH = "http://app.emu.im/emuapi/"
        USE_SCRATCHPAD = True
    elif env == "prod":
        API_PATH = "http://app.emu.im/emuapi/"
        USE_SCRATCHPAD = False
    else:
        print "env parameter missing (must be test or prod)."
        return False

    try:
        ONLY_THIS_PACKAGE = args[2]
    except:
        ONLY_THIS_PACKAGE = None

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
    if USE_SCRATCHPAD:
        resp = requests.get(url=API_PACKAGES_URL, headers={"SCRATCHPAD":"true"})
    else:
        resp = requests.get(url=API_PACKAGES_URL)
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
        
        if ONLY_THIS_PACKAGE != None:
            if ONLY_THIS_PACKAGE != package_info["name"]:
                continue

        package_name = package_info["name"]
        print "-" * 40
        print "Checking package %s... " % package_name
        if "dev_only" in package_info:
            print "Skipping... dev only"
            continue
        if is_package_up_to_date(package_info):
            print "OK"
        else:
            print "Missing"
            create_and_upload_zipped_package(package_info)
# endregion


# region - Zip, Uploads & Downloads
def create_and_upload_zipped_package(pkg):
    print "Downloading resources..."
    emuticons = pkg["emuticons"]
    package_name = pkg["name"]

    folder = download_temp_folder(package_name)
    recreate_folder(folder)

    # download resources for the package
    i = 0
    for emu in emuticons:
        i += 1
        name = emu["name"]
        print "%d / %d - %s" %(i, len(emuticons), name)
        download_emuticon_files(emu, package_name, folder)

    # zip resources of the package
    zip_name = package_current_zip_name(pkg, False)
    zip_path = os.path.join(TEMP_FILES_PATH, zip_name)
    print "Zipping to %s.zip" % zip_name,
    zip_output = shutil.make_archive(zip_path, 'zip', folder)
    print

    # upload the zipped file to s3
    print "Uploading...",
    key_name = package_current_zip_key(pkg)
    k = bucket.new_key(key_name)
    k.set_contents_from_filename(zip_output)
    k.set_acl('public-read')
    print "!"


def download_emuticon_files(emu, package_name, folder):
    download(package_name, emu.get("source_back_layer"), folder)
    download(package_name, emu.get("source_front_layer"), folder)
    download(package_name, emu.get("source_user_layer_mask"), folder)


def download(package_name, file_name, folder):
    if file_name is None:
        return

    key_name = "packages/%s/%s" %(package_name, file_name)
    k_s3 = bucket.get_key(key_name)
    if k_s3 is None:
        print "Missing resource: %s" % key_name
        print "aborting..."
        exit(1)

    print key_name, "downloading...",
    k_s3.get_contents_to_filename(os.path.join(folder, file_name))
    print "!"
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
        return False
    else:
        return True
# endregion


# region - Help info
def show_help_info():
    info = """

,------.                  ,-------.,--.
|  .---',--,--,--.,--.,--.`--.   / `--' ,---.  ,---.  ,---. ,--.--.
|  `--, |        ||  ||  |  /   /  ,--.| .-. || .-. || .-. :|  .--'
|  `---.|  |  |  |'  ''  ' /   `--.|  || '-' '| '-' '\   --.|  |
`------'`--`--`--' `----' `-------'`--'|  |-' |  |-'  `----'`--'
                                       `--'   `--'

Usage: python emuzipper.py <env> <specific package name>

-----------
Parameters:
-----------
<env>
    test or prod for test environment or production environment

<specific package name>
    (optional param) Indicate a specific package to check and update.
    By default (if optional parameter not provided) iterates all packages.


----------------
What does it do:
----------------

    1) Gets info from emuapi about all packages.
    2) Checks for each package if a zip file is available and up to date.
    3) If a zip file is missing or not up to date on s3 the script will:
        a) Download all required resources.
        b) Validate that all required resources exist (halts on missing resource).
        c) Zip all resources.
        d) Upload the zip file to S3.
"""
    print info
# endregion



def create_mixed_screen_resources(info):
    print "Recreating onboarding emus"
    ms = info["mixed_screen"]
    
    # Build a dictionary of emus to include
    included_emus_by_oid = {}
    for emu in ms["emus"]:
        included_emus_by_oid[emu["oid"]] = True

    # now build the packages info including the required emus
    packages_info = []
    for package in info["packages"]:
        p = copy.deepcopy(package)
        emus = []
        for emu in p["emuticons"]:
            if emu["_id"]["$oid"] in included_emus_by_oid:
                emus.append(emu)
        if len(emus) > 0:
            p["emuticons"] = emus
            packages_info.append(p)
    
    json_result = copy.deepcopy(info)
    json_result["config_type"] = "bundled local in app resources" 
    json_result["packages"] = packages_info 
    json_result["packages_count"] = len(packages_info) 

    for k in json_result.keys():
        if k.startswith("cms_"):
            del json_result[k]

    del json_result["tweaks"]
    del json_result["upload_user_content"]

    fname = os.path.join(TEMP_FILES_PATH,"onboarding_packages_test.json")
    file = codecs.open(fname, "w", "utf-8")
    file.write(json.dumps(json_result, indent=4, sort_keys=True))
    file.close()
    print "saved json to:", fname

    # download all required resources
    for pkg in json_result["packages"]:
        download_resources_for_package(pkg)

def download_resources_for_package(pkg):
    print "Downloading resources: ", pkg["name"]

    emuticons = pkg["emuticons"]
    package_name = pkg["name"]

    folder = download_temp_folder(package_name)
    recreate_folder(folder)

    # download resources for the package
    i = 0
    for emu in emuticons:
        i += 1
        name = emu["name"]
        print "%d / %d - %s" %(i, len(emuticons), name)
        download_emuticon_files(emu, package_name, folder)





if __name__ == "__main__":

    if setup_configuration(sys.argv):
        ensure_temp_folder_exists()
        info = fetch_packages_info()
        connect_to_s3()
        #check_packages_with_info(info)
        create_mixed_screen_resources(info)
        print "Done"
    else:
        show_help_info()