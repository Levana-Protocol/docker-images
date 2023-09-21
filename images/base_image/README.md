# How to test

1. For "no log for 2 mins", first, run the tool as `logging.sh $CMD $ANY_PARAMETERS`. This requires writing to /tmp. And if you want to test the log rotating, you may want to reduce the `100000` to a smaller number to get to rotate sooner. Then run `health_check.sh $HEALTHZ_TARGET` frequently. It watches the log files and remove old ones (for disk capacity). If no log for 2 mins, it exits 1. `HEALTHZ_TARGET` is explained in next section. The script does not support omiting it.

2. For "healthz" and "continous errors in status for 5 mins", directly run `health_check.sh $HEALTHZ_TARGET` frequently. `HEALTHZ_TARGET` here is in form of "http://localhost:3000/healthz" or "http://localhost:3000/status". It only checks errors when the name is "status". If connection time out (like tool freezing), health check fails.

3. The status parsing simply grabs `ERROR` without "no alert". And current error list is compared with the latest error list (at least 5 mins ago). If there are same items, health check fails.
