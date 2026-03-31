#!/usr/bin/env bash
# Restart Walker service — no CSS reload signal, must restart
pkill walker 2>/dev/null
sleep 0.3
uwsm app -- walker --gapplication-service &
