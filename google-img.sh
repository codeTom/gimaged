#!/bin/bash

# TODO:
# No idea
# 
###############################################################################
### Begining/Initialisation ###
VERSION="0.12"  # Program version

SEARCH=-1
EXTENSION=""
COLOR=""
OFFSET=0
SAFE=0
NUMBER=-1
TIMEOUT=-1
LINKS=""
LARGE=0
KEEP=0
cmd=""
declare -a LINKS
declare -a files

#removes duplicate files
function rd {
rm *.? &>/dev/null
rm *.?? &>/dev/null
rm *.html.? &>/dev/null
rm *.html.?? &>/dev/null
}

#change filenames from aa.bbb?.* to aa.bbb, if aa(1|2..).bbb exist use aa(1|2|3..).bbb
function clean {
files=`ls`
for file in files
do
if [ `echo $file | grep "?"` ]; then
fi=`echo $file | sed -e 's/?.*//g'` ]]
f=$fi
i=1
while [[ -e $f ]]; do
i=$(( $i + 1 ))
f=`echo $fi | sed -e "s/\./$i./"`
done
mv $file $fi
fi
done
}

#gets page with offset as $1, stores picture links in LINKS
function getLINKS {
	cmd="wget -U firefox -O - http://images.google.com/images?q=${SEARCH}\&imgcolor=${COLOR}\&start=$1\&as_filetype=${EXTENSION}"
	if [[ $SAFE == 1 ]]; then
	cmd="${cmd}\&safe=off"
	fi
	if [[ $LARGE == 1 ]]; then
	cmd="${cmd}\&tbs=isz:l"
	fi	
	cmd="${cmd} | tr \"?&\" \"\\n\""
	cmd="${cmd} | grep imgurl"
	cmd="${cmd} | tr \"=\" \"\\n\""
	cmd="${cmd} | grep http" #cmd now returns LINKS
	#echo $cmd
	#eval $cmd > tmp.txt 
	#LINKS=(`cat tmp.txt`)
	#rm tmp.txt	
	LINKS=(`eval $cmd`)
}

#displays help message
function dispHelp {
echo "Google Image Downloader version $VERSION"
echo "Usage:  gimaged [options]"
echo "  -s : keywords"
echo "  -e : file extension filter (gif, jpg, png, ...)"
echo "  -c : dominant color: red,orange,yellow,green,teal,blue,purple,pink,white,grey,black,brown"
echo "  -p : starting page"
echo "  -d : turn off safe search"
echo "  -n : number of results, default 20"
echo "  -l : only large images"
echo "  -t : connection timeout,  default 10"
echo "  -k : keep the existing files(do not clean working directory)"
echo "  -h : print usage information"
}

#print information and quit
function end {
echo "SEARCH=${SEARCH}"
echo "COLOR=${COLOR}"
echo "OFFSET=${OFFSET}"
echo "EXTENSION=${EXTENSION}"
echo "NUMBER=${NUMBER}"
exit 0
}


### Input option parsing ###
while getopts ":s:e:ldc:p:hn:t:k" opt; do
case $opt in
s)
SEARCH=${OPTARG}
;;
e)
EXTENSION=${OPTARG}
;;
c)
COLOR=${OPTARG}
;;
d)
SAFE=1 #whether safe=off should be appended
;;
l)
LARGE=1
;;
n)
NUMBER=${OPTARG}
;;
q)
echo "${OPTARG}"
;;
t)
TIMEOUT=${OPTARG}
;;
k)
KEEP=1
;;
p)
OFFSET=`echo ${OPTARG}*20 | bc`
OFFSET=`echo ${OFFSET}-20 | bc` #when page=1 offset=0
;;
h|help)
if [ $# = 3 ]
then
echo "Too many arguments with -h option: use -h for help" 
exit -1
fi
dispHelp
exit 0
;;
\?)
echo "Invalid option: -${OPTARG}" >&2
;;
esac
done


#defaults
if [ ${NUMBER} -eq -1 ]
then
NUMBER=20
fi
if [ ${TIMEOUT} -eq -1 ]
then
TIMEOUT=10
fi
if [ ${SEARCH} -eq -1 ]; then
dispHelp
exit 1
fi
#create,enter and clean result directory
mkdir "${SEARCH}"
cd "${SEARCH}"
if [ ${KEEP} -eq 0 ]; then
rm ./*
fi

#replace {SPACE} with + in $SEARCH
SEARCH=`echo "${SEARCH}" | sed -e 's/ /+/g'`

#acquire initial results
getLINKS ${OFFSET};

offse=${OFFSET}
count=0

#download pictures
while [ $count -lt ${NUMBER} ] ; do
offse=`echo "$offse+20" | bc`
for link in "${LINKS[@]}"; do
	echo "Downloading $link"
	(`wget -U firefox --connect-timeout ${TIMEOUT} --tries 1 $link &> /dev/null`) #download image, one try
	count=`echo "$count+1" | bc`
	if [ $count -eq $NUMBER ]; then
		rd
		count=`ls -1 | wc -l`
		if [ $count -eq $NUMBER ]; then
			echo 'done'
			end				
		fi
		
	fi
done #ends for
echo "Not enough results, getting next page"
getLINKS $offse

rd
done
clean
end



