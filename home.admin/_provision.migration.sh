#!/bin/bash

# check if started with sudo
if [ "$EUID" -ne 0 ]; then 
  echo "error='run as root'"
  exit 1
fi

# LOGFILE - store debug logs of bootstrap
logFile="/home/admin/raspiblitz.provision-migration.log"

# INFOFILE - state data from bootstrap
infoFile="/home/admin/raspiblitz.info"
source ${infoFile}

# SETUPFILE - data from setup process
source /var/cache/raspiblitz/temp/raspiblitz.setup

# log header
echo "" > ${logFile}
sudo chmod 640 ${logFile}
echo "###################################" >> ${logFile}
echo "# _provision.migration.sh" >> ${logFile}
echo "###################################" >> ${logFile}
/home/admin/_cache.sh set message "Provision Migration"

source <(/home/admin/config.scripts/blitz.datadrive.sh status)

if [ "${hddGotMigrationData}" == "" ]; then
  /home/admin/config.scripts/blitz.error.sh _provision.migration.sh "missing-hostnamemigrationdata" "missing hddGotMigrationData" "" ${logFile}
  exit 2
fi

err=""
nodenameUpperCase=$(echo "${hddGotMigrationData}" | tr "[a-z]" "[A-Z]")
echo "**************************************************" >> ${logFile}
echo "MIGRATION FROM ${nodenameUpperCase} TO RASPIBLITZ" >> ${logFile}
echo "**************************************************" >> ${logFile}
echo "- started ..." >> ${logFile}
source <(sudo /home/admin/config.scripts/blitz.migration.sh migration-${hddGotMigrationData})
if [ "${err}" != "" ]; then
    /home/admin/config.scripts/blitz.error.sh _provision.migration.sh "migration-failed" "${err}" "Recover funds with fresh sd card using seed words + static channel backup." ${logFile}
    exit 3
fi

# make sure for the rest of the seup info is set correctly
/home/admin/config.scripts/blitz.conf.sh set network "bitcoin"
/home/admin/config.scripts/blitz.conf.sh set chain "main"

# set Password B
echo "## SETTING PASSWORD B" >> ${logFile}
if [ "${setPasswordB}" == "1" ]; then
 if [ "${passwordB}" != "" ]; then
    # set password B as RPC password
    echo "# setting PASSWORD B" >> ${logFile}
    /home/admin/config.scripts/blitz.setpassword.sh b "${passwordB}" >> ${logFile}
 else
    /home/admin/config.scripts/blitz.error.sh _provision.migration.sh "missing-passwordb" "FAIL: Password B should be set but was empty! Running with default." "" ${logFile}
    exit 4
 fi
else
  /home/admin/config.scripts/blitz.error.sh _provision.migration.sh "missing-setpasswordb" "setPasswordB!=1 this not normal on migration! Running with default." "" ${logFile}
  exit 5
fi

# if free space is lower than 100GB (100000000) delete backup files
if [ "${hddDataFreeKB}" != "" ] && [ ${hddDataFreeKB} -lt 407051412 ]; then
    echo "- free space of data disk is low ... deleting 'backup_migration'" >> ${logFile}
    rm -R /mnt/hdd/backup_migration
else
    echo "- old data of ${nodenameUpperCase} can be found in '/mnt/hdd/backup_migration'" >> ${logFile}
fi
echo "OK MIGRATION" >> ${logFile}
echo "END Migration"  >> ${logFile}
exit 0