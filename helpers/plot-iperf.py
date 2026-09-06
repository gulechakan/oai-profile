#!/usr/bin/env python3

import csv
import sys
from pathlib import Path

import matplotlib.pyplot as plt


run_dir = Path(sys.argv[1])
csv_path = run_dir / "analysis" / "iperf_timeseries.csv"
throughput_plot_path = run_dir / "analysis" / "throughput.png"
rtt_plot_path = run_dir / "analysis" / "rtt.png"
cwnd_plot_path = run_dir / "analysis" / "iperf_cwnd.png"

time_s = []
throughput_mbps = []
rtt_ms = []
cwnd_kib = []

with csv_path.open() as csv_file:
    reader = csv.DictReader(csv_file)

    for row in reader:
        time_s.append(float(row["time_s"]))
        throughput_mbps.append(float(row["throughput_mbps"]))
        rtt_ms.append(float(row["rtt_ms"]))
        cwnd_kib.append(float(row["snd_cwnd_bytes"]) / 1024)


plt.figure(figsize=(10, 4))
plt.plot(time_s, throughput_mbps)

plt.xlabel("Time since iperf3 started (seconds)")
plt.ylabel("Throughput (Mbit/s)")
plt.title("Downlink TCP Throughput")
plt.grid()

plt.savefig(throughput_plot_path, dpi=150, bbox_inches="tight")
plt.close()

print(f"Created: {throughput_plot_path}")

plt.figure(figsize=(10, 4))
plt.plot(time_s, rtt_ms)

plt.xlabel("Time since iperf3 started (seconds)")
plt.ylabel("RTT (milliseconds)")
plt.title("Downlink TCP RTT")
plt.grid()

plt.savefig(rtt_plot_path, dpi=150, bbox_inches="tight")
plt.close()

print(f"Created: {rtt_plot_path}")

plt.figure(figsize=(10, 4))
plt.plot(time_s, cwnd_kib)

plt.xlabel("Time since iperf3 started (seconds)")
plt.ylabel("Congestion window (KiB)")
plt.title("TCP Congestion Window Reported by iperf3")
plt.grid()

plt.savefig(cwnd_plot_path, dpi=150, bbox_inches="tight")
plt.close()

print(f"Created: {cwnd_plot_path}")