#!/bin/bash

echo -e "\n"
echo "###############################################"
echo "#                                             #"
echo "# Collecting all ROOT files from combine jobs #"
echo "#                                             #"
echo "###############################################"
echo -e "\n"
echo "Plese make sure to clik the share link for the \`Combine\` folder at https://cernbox.cern.ch/files/spaces/eos/user/${USER:0:1}/${USER}/EFT?items-per-page=100"
echo -e "\n"

dirs=`find /eos/user/${USER:0:1}/${USER}/EFT/Combine/ -name "*DNN*" -type d`
message=""
for dir in $dirs
do
  message+="${dir}.root\n"
done
echo -e $message

if [[ -z $1 ]]; then
  echo "universe              = vanilla" > collect.sub
  echo "executable            = collect.sh" >> collect.sub
  echo "arguments             = \$(ProcId)" >> collect.sub
  echo "output                = collect_\$(ProcId).out" >> collect.sub
  echo "error                 = collect_\$(ProcId).err" >> collect.sub
  echo "log                   = collect_\$(ProcId).log" >> collect.sub
  echo "request_disk          = 60M" >> collect.sub
  echo "request_memory        = 3G" >> collect.sub
  echo "request_cpus          = 4" >> collect.sub
  echo "Should_Transfer_Files = NO" >> collect.sub
  echo "+JobFlavour           = \"tomorrow\"" >> collect.sub
  echo "RunAsOwner            = True" >> collect.sub
  echo "notify_user           = ${USER}@cern.ch,byates@cern.ch"  >> collect.sub
  echo "notification          = always" >> collect.sub
  echo "queue ${#dirs[@]}" >> collect.sub
  condor_submit collect.sub --batch-name "Collect DNN"
  rm collect.sub
  echo -e $message | mail -s "${USER} has started a DNN collection run" brent.yates@cern.ch,$USER@mail.cern.ch
  exit
fi

dirs=`find /eos/user/${USER:0:1}/${USER}/EFT/Combine/ -name "*DNN*" -type d`
echo $dirs

if [[ $1 -gt ${#dirs[@]} ]]; then
  exit
fi

message="You may find ${USER}'s files in"

echo "Extracting tar files: this will take some time"
for dir in $dirs
do
  if [[ ! "$dir[*]" =~ "$1" ]]; then
    echo $dir
    echo ${dirs[$1]}
    continue
  fi
  echo $dir
  cd $dir
  name=(${dir//\// })
  name="${name[${#name[@]} - 1]}.root"
  done=`find $dir -maxdepth 1 -name "$name" -type f`
  if [[ ! -z $done ]]; then
    continue
  fi
  message+="\n"
  files=`find -L . -name "*.tar" -type f`
  eval `mkdir -p tmp`
  for file in $files
  do
    tar xvf $file --skip-old-files -C tmp/
  done
  hadd -f -j $dir.root $dir/tmp/*POINTS*.root
  rm -rf tmp
  message+=`ls -lrth $dir.root`
done

echo -e "All done, sending email"
echo -e $message
#echo -e $message | mail -s "${USER} has finished a DNN run" brent.yates@cern.ch,$USER@mail.cern.ch
