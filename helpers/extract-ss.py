#!/usr/bin/env python3

import re
import sys
from pathlib import Path
import csv

run_dir = Path(sys.argv[1])

ss_log_path = run_dir / "tcp" / "ss_tcp.log"
start_time_path = run_dir / "iperf3" / "iperf_start_time.txt"
output_path = run_dir / "analysis" / "ss_timeseries.csv"

start_epoch = float(start_time_path.read_text().strip())


timestamp_pattern = re.compile(r"timestamp_epoch=(\d+\.\d+)")
bytes_sent_pattern = re.compile(r"(?:^|\s)bytes_sent:(\d+)")
mss_pattern = re.compile(r"(?:^|\s)mss:(\d+)")
cwnd_pattern = re.compile(r"(?:^|\s)cwnd:(\d+)")
ssthresh_pattern = re.compile(r"(?:^|\s)ssthresh:(\d+)")

rows = []

current_timestamp = None
best_connection = None


with ss_log_path.open() as ss_log:
    for line in ss_log:
        timestamp_match = timestamp_pattern.search(line)

        if timestamp_match:
            if best_connection is not None:
                rows.append(
                    {
                        "time_s": current_timestamp - start_epoch,
                        "cwnd_kib": best_connection["cwnd_kib"],
                        "ssthresh_kib": best_connection["ssthresh_kib"],
                    }
                )

            current_timestamp = float(timestamp_match.group(1))
            best_connection = None
            continue

        bytes_sent_match = bytes_sent_pattern.search(line)
        mss_match = mss_pattern.search(line)
        cwnd_match = cwnd_pattern.search(line)

        if not bytes_sent_match or not mss_match or not cwnd_match:
            continue

        bytes_sent = int(bytes_sent_match.group(1))
        mss_bytes = int(mss_match.group(1))
        cwnd_segments = int(cwnd_match.group(1))

        ssthresh_match = ssthresh_pattern.search(line)
        ssthresh_kib = None

        if ssthresh_match:
            ssthresh_segments = int(ssthresh_match.group(1))
            ssthresh_kib = ssthresh_segments * mss_bytes / 1024

        connection = {
            "bytes_sent": bytes_sent,
            "cwnd_kib": cwnd_segments * mss_bytes / 1024,
            "ssthresh_kib": ssthresh_kib,
        }

        if (
            best_connection is None
            or bytes_sent > best_connection["bytes_sent"]
        ):
            best_connection = connection

if best_connection is not None:
    rows.append(
        {
            "time_s": current_timestamp - start_epoch,
            "cwnd_kib": best_connection["cwnd_kib"],
            "ssthresh_kib": best_connection["ssthresh_kib"],
        }
    )

output_path.parent.mkdir(parents=True, exist_ok=True)

fieldnames = [
    "time_s",
    "cwnd_kib",
    "ssthresh_kib",
]

with output_path.open("w", newline="") as csv_file:
    writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
    writer.writeheader()
    writer.writerows(rows)

print(f"Created: {output_path}")
print(f"Samples written: {len(rows)}")