# importing the module
import json
import subprocess
import re
import sys
from datetime import datetime
import os

json_file_name = 'build/dependencyUpdates/dependencies.json'
date_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
dependency_definition_file = "buildSrc/src/main/kotlin/default/dependencies.kt"
ignore_list = ["org.jetbrains.kotlin", "org.gradle.kotlin.kotlin-dsl"]


def run_checks():
    if len(sys.argv) > 1 and ("--runTask" in sys.argv or "-r" in sys.argv):
        subprocess.call(["./gradlew", "dependencyUpdates"])
    updates = list(get_available_updates())
    updates_summary = [map_dependency(dep) for dep in updates if is_major_version(dep)]
    if len(updates_summary) != 0:
        if "--no-write" not in sys.argv:
            write_findings_to_dependency_file(updates_summary)
            print(f'Found {len(updates_summary)} outdated dependencies, see {dependency_definition_file} for details')
        else:
            print(f'Found {len(updates_summary)} outdated dependencies:')
            print("\n".join(updates_summary))
            if len(ignore_list) != 0:
                print(f'\n**Ignored dependencies\n{"\n".join(ignore_list)}')
        sys.exit(len(updates_summary))
    else:
        print(f'Scan completed, no outdated dependencies found.')
        if len(ignore_list) != 0:
            print(f'-- Ignored dependencies --\n{"\n".join(ignore_list)}')
        sys.exit(0)


def get_available_updates():
    with open(json_file_name, 'r') as json_file:
        data = json.load(json_file)
        available_updates = data["outdated"]["dependencies"]
        json_file.close()
        return available_updates


def is_major_version(version):
    return bool(re.search("^[0-9.]*$", version["available"]["milestone"])) and version["group"] not in ignore_list


def map_dependency(dep):
    return f'{dep["group"]}:{dep["name"]} :  {dep["version"]} -> {dep["available"]["milestone"]}'


def write_findings_to_dependency_file(pending_updates):
    dependency_file = open(dependency_definition_file, 'a')
    print("Writing to dependency definition file")
    dependency_file_header = f'\n/*\n{date_str}: {len(pending_updates)} outdated dependencies'
    write_dependency_summary(dependency_file, dependency_file_header, pending_updates)


def write_dependency_summary(file, header, pending_updates):
    file.write(header)
    for pending in pending_updates:
        file.write(f'\n{pending}')
    if len(ignore_list) != 0:
        file.write(f'\n**Ignored dependencies\n{"\n".join(ignore_list)}')

run_checks()
