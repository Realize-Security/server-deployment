#!/usr/bin/python3

import requests
import json
import os
import argparse

BASE_URL = "https://api.digitalocean.com/v2"
AUTH_TOKEN = os.getenv("DIGITAL_OCEAN_API")


def auth_headers():
    return { "Authorization": "Bearer " + AUTH_TOKEN }


def create_ssh_key(args):
    if args.keyname and args.pubkey:
        json = {
            "public_key": read_file(args.pubkey),
            "name": f"{args.keyname}"
        }
        send_post("/account/keys", json)
    else:
        print("[!] Missing arguments, keyname and pubkey file")
        exit()


def read_file(name):
    try:
        file = open(name, "r")
        content = file.read()
        if content is not None and len(content) > 0:
            return content
        else:
            print("[!] File content either null or empty")
            exit()
    except Exception as e:
        print("[!] Exception occurred reading pubkey file: \n\n" + str(e))
        exit()


def send_post(endpoint, data):
    try:
        res = requests.post(BASE_URL + endpoint, json=data, headers=auth_headers())
        return json.loads(res.text) if res.status_code == 201 else False
    except Exception as e:
        print("[!] Exception in POST request: \n\n" + str(e))
        exit()


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--keyname", "-kn", type=str, help="Name for new SSH Pub Key")
    parser.add_argument("--pubkey", "-p", type=str, help="Location of pubkey file")
    return parser.parse_args()


if __name__ == "__main__":
    args = get_args()
    key = create_ssh_key(args)
    if key:
        print(key)
