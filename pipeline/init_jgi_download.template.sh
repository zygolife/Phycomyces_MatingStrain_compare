#!/usr/bin/bash -l
#SBATCH -p batch --ntasks 1 --nodes 1 --mem 2G --time 8:00:00 -o download.log
USERNAME=xxUSERNAMExx
PASSWORD=xxPASSWORDxx
curl 'https://signon.jgi.doe.gov/signon/create' --data-urlencode "login=$USERNAME" --data-urlencode "password=$PASSWORD" -c cookies > /dev/null
