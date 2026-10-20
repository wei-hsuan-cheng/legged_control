#!/bin/sh
# Keep the container alive; work happens via `docker exec`.
exec tail -f /dev/null
