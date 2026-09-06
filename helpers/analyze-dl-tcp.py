#!/usr/bin/env python3

import csv
import json
import statistics
import sys
from pathlib import Path


def percentile(values, fraction):
    if not values:
        return None

    ordered = sorted(values)
    index = int(fraction * (len(ordered) - 1))
    return ordered[index]


def main():
    if len(sys.argv) != 2:
        print(
            f"Usage: {sys.argv[0]} <experiment-directory>",
            file=sys.stderr,
        )
        return 2

    run_dir = Path(sys.argv[1]).resolve()

    iperf_dir = run_dir / "iperf3"
    client_json_path = iperf_dir / "iperf3_client.json"
    start_time_path = iperf_dir / "iperf_start_time.txt"

    if not client_json_path.is_file():
        print(
            f"ERROR: iperf3 client JSON not found: {client_json_path}",
            file=sys.stderr,
        )
        return 1

    try:
        data = json.loads(client_json_path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        print(
            f"ERROR: could not read iperf3 JSON: {error}",
            file=sys.stderr,
        )
        return 1

    if data.get("error"):
        print(
            f"ERROR: iperf3 reported: {data['error']}",
            file=sys.stderr,
        )
        return 1

    start_epoch = None

    if start_time_path.is_file():
        try:
            start_epoch = float(start_time_path.read_text().strip())
        except ValueError:
            print(
                f"WARNING: invalid start time: {start_time_path}",
                file=sys.stderr,
            )

    rows = []

    for interval in data.get("intervals", []):
        interval_sum = interval.get("sum", {})
        streams = interval.get("streams", [])
        stream = streams[0] if streams else {}

        time_s = interval_sum.get("end")
        bits_per_second = interval_sum.get("bits_per_second")
        retransmits = interval_sum.get(
            "retransmits",
            stream.get("retransmits", 0),
        )

        rtt_us = stream.get("rtt")
        congestion_window = stream.get("snd_cwnd")

        throughput_mbps = None
        if bits_per_second is not None:
            throughput_mbps = bits_per_second / 1_000_000

        rtt_ms = None
        if rtt_us is not None:
            rtt_ms = rtt_us / 1_000

        epoch_time_s = None
        if start_epoch is not None and time_s is not None:
            epoch_time_s = start_epoch + time_s

        rows.append(
            {
                "time_s": time_s,
                "epoch_time_s": epoch_time_s,
                "throughput_mbps": throughput_mbps,
                "rtt_ms": rtt_ms,
                "retransmits": retransmits,
                "snd_cwnd_bytes": congestion_window,
            }
        )

    analysis_dir = run_dir / "analysis"
    analysis_dir.mkdir(parents=True, exist_ok=True)

    csv_path = analysis_dir / "iperf_timeseries.csv"

    fieldnames = [
        "time_s",
        "epoch_time_s",
        "throughput_mbps",
        "rtt_ms",
        "retransmits",
        "snd_cwnd_bytes",
    ]

    with csv_path.open("w", newline="") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    rtt_values = [
        row["rtt_ms"]
        for row in rows
        if row["rtt_ms"] is not None
    ]

    cwnd_values = [
        row["snd_cwnd_bytes"]
        for row in rows
        if row["snd_cwnd_bytes"] is not None
    ]

    end_sum = data.get("end", {}).get("sum_sent", {})
    average_bits_per_second = end_sum.get("bits_per_second")

    average_throughput_mbps = None
    if average_bits_per_second is not None:
        average_throughput_mbps = (
            average_bits_per_second / 1_000_000
        )

    total_retransmissions = end_sum.get("retransmits")

    if total_retransmissions is None:
        total_retransmissions = sum(
            row["retransmits"] or 0
            for row in rows
        )

    summary = {
        "source": str(client_json_path),
        "sample_count": len(rows),
        "start_epoch_s": start_epoch,
        "duration_s": end_sum.get("seconds"),
        "average_throughput_mbps": average_throughput_mbps,
        "total_retransmissions": total_retransmissions,
        "average_rtt_ms": (
            statistics.mean(rtt_values)
            if rtt_values
            else None
        ),
        "p95_rtt_ms": percentile(rtt_values, 0.95),
        "p99_rtt_ms": percentile(rtt_values, 0.99),
        "maximum_rtt_ms": max(rtt_values) if rtt_values else None,
        "minimum_cwnd_bytes": min(cwnd_values) if cwnd_values else None,
        "maximum_cwnd_bytes": max(cwnd_values) if cwnd_values else None,
    }

    summary_path = analysis_dir / "iperf_summary.json"
    summary_path.write_text(
        json.dumps(summary, indent=2) + "\n"
    )

    print(f"Created: {csv_path}")
    print(f"Created: {summary_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())