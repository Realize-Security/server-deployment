#!/usr/bin/python3

import requests
import json
import os
import argparse

BASE_URL = "https://api.digitalocean.com/v2"
AUTH_TOKEN = os.getenv("DIGITAL_OCEAN_API")
BASH_SCRIPT="https://raw.githubusercontent.com/Realize-Security/server-deployment/main/root-setup.sh"


def auth_headers():
    return { "Authorization": "Bearer " + AUTH_TOKEN }


def create_ssh_key(args):
    if args.keyname and args.pubkey:
        json_data = {
            "public_key": read_pubkey_file(args.pubkey),
            "name": f"{args.keyname}"
        }
        res = send_post("/account/keys", json_data)
        return json.loads(res.text) if res.status_code == 201 else False
    else:
        print("[!] Missing arguments, keyname and pubkey file")
        exit()


def create_droplet(ssh_key):
    json_data = {
        "name": "realizesec2-dot-com-ubuntu-s-1vcpu-2gb-amd-lon1-01",
        "region": "lon1",
        "size": "s-1vcpu-2gb",
        "image": "ubuntu-20-04-x64",
        "ssh_keys": [
            ssh_key["id"],
            ssh_key["fingerprint"]
        ],
        "backups": "false",
        "ipv6": "false",
        "monitoring": "true",
        "tags": [
            "env:prod",
            "web"
        ],
        "user_data": f"apt-get update && apt-get upgrade -y ; wget {BASH_SCRIPT}",
    }
    res = send_post("/droplets", json_data)
    return json.loads(res.text) if res.status_code == 202 else False


def read_pubkey_file(name):
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
        return requests.post(BASE_URL + endpoint, json=data, headers=auth_headers())
    except Exception as e:
        print("[!] Exception in POST request: \n\n" + str(e))
        exit()


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--keyname", "-kname", type=str, help="Name for new SSH Pub Key")
    parser.add_argument("--pubkey", "-p", type=str, help="Location of pubkey file")
    return parser.parse_args()


if __name__ == "__main__":
    args = get_args()
    key = create_ssh_key(args)
    if key:
        create_droplet(key["ssh_key"])
