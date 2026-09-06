#!/usr/bin/env python3

import csv
import json
import sys
from pathlib import Path

import matplotlib.pyplot as plt


run_dir = Path(sys.argv[1])

csv_path = run_dir / "analysis" / "ss_timeseries.csv"
summary_path = run_dir / "analysis" / "iperf_summary.json"
plot_path = run_dir / "analysis" / "ss_cwnd_ssthresh.png"


summary = json.loads(summary_path.read_text())
duration_s = float(summary["duration_s"])


time_s = []
cwnd_kib = []

ssthresh_time_s = []
ssthresh_kib = []


with csv_path.open() as csv_file:
    reader = csv.DictReader(csv_file)

    for row in reader:
        sample_time = float(row["time_s"])

        if sample_time < 0 or sample_time > duration_s:
            continue

        time_s.append(sample_time)
        cwnd_kib.append(float(row["cwnd_kib"]))

        if row["ssthresh_kib"]:
            ssthresh_time_s.append(sample_time)
            ssthresh_kib.append(float(row["ssthresh_kib"]))


plt.figure(figsize=(10, 4))

plt.plot(
    time_s,
    cwnd_kib,
    label="cwnd",
    color="tab:blue",
)

plt.plot(
    ssthresh_time_s,
    ssthresh_kib,
    label="ssthresh",
    color="tab:orange",
)

plt.xlabel("Time since iperf3 started (seconds)")
plt.ylabel("TCP window (KiB)")
plt.title("TCP cwnd and ssthresh Reported by ss")
plt.grid()
plt.legend()

plt.savefig(plot_path, dpi=150, bbox_inches="tight")
plt.close()

print(f"Created: {plot_path}")