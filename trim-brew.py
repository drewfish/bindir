#!/usr/bin/env python3
#
#   FANCY UX IDEA
#       table of all installed and required packages
#       [name] [installed-version] [query-status] [actions]
#       query-status:  pending, looking, done
#       actions:  upgrade [version], extra
#
#

from typing import Any, List
import json
import os
import queue
import subprocess
import sys


KEEP_FILE = os.path.expanduser("~/.config/homebrew/keep.txt")


def get_path(obj, path, default_):
    """returns value at path in object
    path is either an array of keys or a dot-separated string of keys
    the keys are used to look recursively into the object
    if value is not found at the path, default is returned
    """
    if isinstance(path, str):
        path = path.split(".")
    for key in path:
        try:
            if isinstance(obj, list):
                obj = obj[int(key)]
            else:
                obj = obj[key]
        except KeyError:
            return default_
    return obj


def run_cmd(cmd: List[str], **opts) -> Any:
    """
    sugar for shelling out to another command
    """
    opts["check"] = opts.get("check", True)
    opts["text"] = opts.get("text", True)
    opts["stdout"] = subprocess.PIPE
    opts["stderr"] = subprocess.PIPE
    parse_json = opts.pop("json", False)
    print('$', " ".join(cmd))
    res = None
    try:
        # pylint: disable=subprocess-run-check
        res = subprocess.run(cmd, **opts)
    except subprocess.CalledProcessError as exc:
        # don't swallow output since it likely has important details
        # FUTURE -- figure out how to print the two streams interleaved in the order
        # that they're generated
        if parse_json and exc.stdout:
            print(exc.stdout, file=sys.stdout)
        if exc.stderr:
            print(exc.stderr, file=sys.stderr)
        raise exc
    if res and parse_json:
        if res.stdout:
            return json.loads(res.stdout)
        return None
    return res


def brew_deps(formula):
    cmd = ["brew", "deps", formula]
    raw = run_cmd(cmd)
    deps = {}
    for line in raw.stdout.splitlines():
        deps[line.strip()] = True
    return list(sorted(deps.keys()))


def brew_list():
    cmd = ["brew", "list", "--formula"]
    raw = run_cmd(cmd)
    return raw.stdout.splitlines()


def main():
    if not os.path.exists(KEEP_FILE):
        print("No keep file found at", KEEP_FILE)
        sys.exit(1)

    work = queue.SimpleQueue()
    with open(KEEP_FILE, "rt", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            work.put(line)
    keep = {}
    done = {}
    while not work.empty():
        formula = work.get()
        if done.get(formula, False):
            continue
        keep[formula] = True
        for dep in brew_deps(formula):
            work.put(dep)
        done[formula] = True
    print("======= KEEP")
    print(" ".join(list(sorted(keep.keys()))))

    extra = {}
    for formula in brew_list():
        if not keep.get(formula, False):
            extra[formula] = True
    print("======= EXTRA")
    if extra:
        print("--nothing--")
    else:
        print(" ".join(list(sorted(extra.keys()))))


if __name__ == '__main__':
    main()
