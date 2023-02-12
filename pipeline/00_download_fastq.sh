#SBATCH -p batch --ntasks 1 --nodes 1 --mem 2G --time 8:00:00 -o download.log

if [ ! -f login_info.txt ]; then
	echo "need to create a login_info.txt, see the login_info.template.txt"
	echo "You need a JGI login and password to download even public data"
	exit
fi
source login_info.txt
mkdir -p input
URL=https://genome.jgi.doe.gov
DAT="/portal/ext-api/downloads/get_tape_file?blocking=true&url=/PhyblU21_2/download/_JAMO/5d8a8adc95f4dcd30aead7e4/pbio-2049.18218.filter.fastq.gz
/portal/ext-api/downloads/get_tape_file?blocking=true&url=/PhyblU21_2/download/_JAMO/5d8a8adb95f4dcd30aead7dd/pbio-2048.18190.filter.fastq.gz"
if [ ! -f cookies ]; then
	curl 'https://signon.jgi.doe.gov/signon/create' --data-urlencode "login=$USERNAME" --data-urlencode "password=$PASSWORD" -c cookies > /dev/null
fi


for a in $DAT
do
	FNAME=$(basename $a)
	curl -o input/$FNAME -b cookies "${URL}${a}"
done
