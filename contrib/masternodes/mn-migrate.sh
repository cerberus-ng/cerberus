#!/bin/bash
echo "This is an attempt to migrate your existing CBS masternode to the new NG " 
echo "version. if you have any issues please refer to the project's FAQ "
echo "https://github.com/cerberus-ng/cerberus/wiki/FAQ "
echo "This script works only on Linux systems."
echo "and don't forget to join our server on Discord https://discord.gg/mzzRhqW "
echo "Copyright (C) 2018 The Cerberus New Generation Project"
echo ""
timestamp() {
    date +"%Y-%m-%d_%H-%M-%S"
}

result=0
cerberus_cli_command_name="cerberus-cli"
cerberusd_command_name="cerberusd"
openssl_command_name="openssl"
cerberus_cli_loc=`type -p "$cerberus_cli_command_name"` 
cerberusd_loc=`type -p "$cerberusd_command_name"`
cerberusd_dir=`dirname "$cerberusd_loc"`
cerberus_cli_dir=`dirname "$cerberus_cli_loc"`
mn_log="mn-migrate."`timestamp`".log"
echo "This is the beginning of MN migration log file " > $mn_log
echo "cerberus_cli_command_name = "$cerberus_cli_command_name >> $mn_log
echo "cerberusd_command_name = "$cerberusd_command_name >> $mn_log
echo "cerberusd_loc = " $cerberusd_loc >> $mn_log
echo "cerberus_cli_loc = " $cerberus_cli_loc >> $mn_log
echo "cerberusd_dir = " $cerberusd_dir >> $mn_log
echo "cerberus_cli_dir = " $cerberus_cli_dir >> $mn_log

echo "Checking for superuser privileges... "
if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit 1
fi

echo "Checking for Cerberus NG client (cerberus-cli)... "
if [[ -z $cerberus_cli_loc ]]; then
    echo "Cerberus NG client (cerberus-cli) not found, aborting"
    result=1
fi

echo "Checking for Cerberus NG daemon (cerberusd)... "
if [[ -z $cerberusd_loc ]]; then
    echo "Cerberus NG daemon (cerberusd) not found, aborting"
    result=1
fi

if [[ $result -ne 0 ]]; then
    echo "Failed to upgrade MN"
    exit 1
fi

kernel_conf=`getconf LONG_BIT`
if [[ $kernel_conf = "64" ]]; then
    compressed_file="cerberuscore-0.12.2-linux64.tar.gz"
    compressed_md5="8d48e463e9bdf03355bd7d30f649d1a0"
else if  [[ $kernel_conf = "32" ]]; then
    compressed_file="cerberuscore-0.12.2-linux32.tar.gz"
    compressed_md5="60100ca8901f97e305a204d7466568d5"
    fi
fi

compressed_url="https://github.com/cerberus-ng/cerberus/releases/download/0.12.2.0/"$compressed_file

wget $compressed_url

md5_hash=`openssl md5 -r $compressed_file | cut -d' ' -f1`
echo "md5_hash = "$md5_hash >> $mn_log

if [[ $md5_hash = $compressed_md5 ]]; then
    echo "md5 checksum ok"
else
    echo "md5 checksum error"
    exit 1
fi

tar zxvf $compressed_file
cd cerberuscore-0.12.2/bin

cerberus-cli stop

mv $cerberusd_loc $cerberusd_loc.old
mv $cerberus_cli_loc $cerberus_cli_loc.old

cp cerberus-cli $cerberus_cli_dir
cp cerberusd $cerberusd_dir

cerberusd -daemon

cbs_version=`cerberus-cli getinfo | grep \"version\" | cut -c14-19`

if [[ $cbs_version = "120200" ]]; then
    echo "MN upgraded successfully"
else
    echo "MN upgrade error, please see log file " $mn_log
fi
