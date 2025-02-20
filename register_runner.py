#!/bin/python3
import os
import re
import subprocess
import sys
from typing import Dict, List, Tuple, TypedDict
import yaml

def run_command(command: str) -> str:
    """
    Returns the stdout of a command
    """
    return os.popen(command).read()

class ProbeMCU(TypedDict):
    version: str
    serial: str
    flash_size: int
    flash_pagesize: int
    sram_size: int
    chipid: int
    dev_type: str


def parse_probe_output(output: str) -> List[ProbeMCU]:
    """
    Parses the output of the probe command.

    Returns a dictionary with a list of devices under the key "probes".
    Each device is a dict with keys: version, serial, flash (int),
    flash_pagesize (int), sram (int), chipid (int), dev_type.

    Raises ValueError if any expected field is missing or if the format is unexpected.
    """
    lines = output.strip().splitlines()
    if not lines:
        raise ValueError("Empty output")

    # First line: "Found X stlink programmers"
    found_match = re.match(r"Found\s+(\d+)\s+stlink programmers", lines[0])
    if not found_match:
        raise ValueError("Could not determine the number of stlink programmers")
    expected_count = int(found_match.group(1))

    probes: List[ProbeMCU] = []

    # Determine if the output is in multi-device format (numbered blocks)
    is_numbered = any(re.match(r"\d+\.", line.strip()) for line in lines[1:])

    # Define a function to process one block (list of lines)
    def process_block(block_lines: List[str]) -> dict:
        # field regex patterns
        patterns = {
            "version": r"version:\s*(.+)$",
            "serial": r"serial:\s*(.+)$",
            "flash_size": r"flash:\s*(\d+).*",
            "flash_pagesize": r"flash:.*\(pagesize:\s*(\d+)\)",
            "sram_size": r"sram:\s*(\d+)",
            "chipid": r"chipid:\s*0x([0-9a-fA-F]+)",
            "dev_type": r"dev-?type:\s*(.+)$",
        }
        probe = {}
        for key, pattern in patterns.items():
            found = False
            for line in block_lines:
                match = re.search(pattern, line, re.IGNORECASE)
                if match:
                    value = match.group(1).strip()
                    if key in ("flash_size", "flash_pagesize", "sram_size"):
                        try:
                            probe[key] = int(value)
                        except ValueError:
                            raise ValueError(f"Invalid integer for {key}: {value}")
                    elif key == "chipid":
                        try:
                            probe[key] = int(value, 16)
                        except ValueError:
                            raise ValueError(f"Invalid hex value for chipid: {value}")
                    else:
                        probe[key] = value
                    found = True
                    break
            if not found:
                raise ValueError(f"Missing field '{key}' in probe output block:\n{block_lines}")
        return probe

    # Process numbered blocks or a single block
    if is_numbered:
        # Blocks should start with lines like "1." so skip the first header line
        current_block = []
        for line in lines[1:]:
            stripped = line.strip()
            if re.match(r"\d+\.", stripped):
                if current_block:
                    probes.append(process_block(current_block))
                    current_block = []
                # skip the line that only has the block number
            else:
                if stripped:  # ignore empty lines
                    current_block.append(stripped)
        if current_block:
            probes.append(process_block(current_block))
    else:
        # Single block (the rest of the lines)
        block_lines = [line.strip() for line in lines[1:] if line.strip()]
        probes.append(process_block(block_lines))

    if len(probes) != expected_count:
        raise ValueError(f"Expected {expected_count} probes, but parsed {len(probes)}.")

    return probes

class Config(TypedDict):
    # maps a serial ID to a chip name
    serial_map: Dict[str, str]
    runner_name: str

def parse_config_file(config_file: str = None) -> dict:
    if config_file is None:
        env_value = os.getenv("CHIPS_FILE_PATH")
        if env_value:
            config_file = env_value
        else:
            config_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "chips.yml")

    with open(config_file) as f:
        return yaml.safe_load(f)

    if not isinstance(config, dict):
        raise ValueError("Config file must be a dictionary")
    if "serial_map" not in config:
        raise ValueError("Config file must have a 'serial_map' key")
    if not isinstance(config["serial_map"], dict):
        raise ValueError("serial_map must be a dictionary")

    for serial, chip_name in config["serial_map"].items():
        if not isinstance(serial, str) or not isinstance(chip_name, str):
            raise ValueError("serial_map keys and values must be strings")

    if not isinstance(config["runner_name"], str):
        raise ValueError("Config file must have a 'runner_name' key with a string value")

    if len(config) != 2:
        raise ValueError("Config file must have only a 'serial_map' key")

    return config

def get_chips() -> Tuple[List[ProbeMCU], Config]:
    config = parse_config_file()
    probe_info = run_command("st-info --probe")
    if not probe_info:
        print("No output from st-info --probe")
        exit(1)
    chips = parse_probe_output(probe_info)

    if not chips:
        print("No chips found")
        exit(1)

    for i, probe in enumerate(chips):
        if probe["serial"] in config["serial_map"]:
            chips[i]["dev_type"] = config["serial_map"][probe["serial"]]

    return chips, config

def main():
    chips, config = get_chips()

    print(yaml.dump(chips))

    labels = set()
    for chip in chips:
        labels.add(chip['dev_type'].lower())

    args = ["--unattended", "--replace", "--labels", ','.join(list(labels)), "--name", config['runner_name']]
    if len(sys.argv) > 1:
        args += sys.argv[1:]

    print("Running config.sh with args ", args)
    subprocess.run(["./config.sh"] + args)

    print("Running run.sh")
    subprocess.run(["./run.sh"], check=True)

if __name__ == "__main__":
    main()

