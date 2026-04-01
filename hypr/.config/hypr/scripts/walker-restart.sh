#!/usr/bin/env bash
# Restart Walker service to pick up new CSS
pkill walker 2>/dev/null
sleep 0.3
uwsm app -- walker --gapplication-service &
