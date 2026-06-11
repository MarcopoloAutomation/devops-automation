#!/usr/bin/env python3
"""Poll an HTTP endpoint on an interval, log status + latency to a file.

Examples:
  ./health_check.py                                  # poll local /health forever, 5s
  ./health_check.py --url http://api/health --count 10 --interval 2
  ./health_check.py --logfile /var/log/hc.log
"""
import argparse
import logging
import time
import requests


def setup_logger(path):
    logging.basicConfig(
        filename=path,
        level=logging.INFO,
        force=True,  
        format="%(asctime)s %(levelname)s %(message)s",
    )
    return logging.getLogger("healthcheck")


def check(url, timeout):
    """Hit the URL once. Returns (ok, status_or_error, latency_ms)."""
    start = time.monotonic()
    try:
        r = requests.get(url, timeout=timeout)
        latency = (time.monotonic() - start) * 1000
        return r.ok, r.status_code, latency
    except requests.RequestException as e:
        latency = (time.monotonic() - start) * 1000
        return False, str(e), latency


def main():
    ap = argparse.ArgumentParser(description="poll an endpoint and log up/down to a file")
    ap.add_argument("--url", default="http://localhost:8000/health")
    ap.add_argument("--interval", type=float, default=5.0, help="seconds between polls")
    ap.add_argument("--count", type=int, default=0, help="number of polls, 0 = forever")
    ap.add_argument("--timeout", type=float, default=3.0, help="request timeout (s)")
    ap.add_argument("--logfile", default="health_check.log")
    args = ap.parse_args()

    log = setup_logger(args.logfile)
    print(f"polling {args.url} -> {args.logfile} (Ctrl-C to stop)")

    n = 0
    while args.count == 0 or n < args.count:
        ok, info, latency = check(args.url, args.timeout)
        
        status_str = "UP" if ok else "DOWN"
        msg = f"{args.url} {status_str} {info} {latency:.1f}ms"
        
        if ok:
            log.info(msg)
        else:
            log.warning(msg)

        n += 1
        if args.count and n >= args.count:
            break
        time.sleep(args.interval)


if __name__ == "__main__":
    main()