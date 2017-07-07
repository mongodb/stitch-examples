#!/bin/bash

export PRIMARY="Primary Server:27017"
export USERNAME=""
export PASSWORD=""

exists()
  {
    command -v "$1" >/dev/null 2>&1
  }

if exists mongo; then
  mongo platespaceIndexes.js --host $PRIMARY --ssl -u $USERNAME -p $PASSWORD  --authenticationDatabase admin
else
  echo 'Your system does not have the mongo shell, please go to https://www.mongodb.com/download-center#community and download the latest 3.4 package of MongoDB'
fi
