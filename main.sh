#!/bin/bash


## copy everything from repo doing the heavy work
rsync -av --exclude '*.apk' ../msedge-apk-restrictions-extract/PlaystoreDL_MicrosoftEdge/ ./MicrosoftEdge_restrictions_history/

