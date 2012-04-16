#!/bin/bash
# scripted by Bhoppi Chaw
# last modify: 2012-04-16

mod_name=`basename $0`
mod_desc="Distributed cp for all cluster's nodes."

nodelistfile="./nodelist"
user=$USER

function showHelp()
{
    echo
    echo "Usage:"
    echo " $mod_name [options] <file path> <dest path>"
    echo
    echo "Options:"
    echo " -u <user>     cp file using user of <user> (defaut: this user)"
    echo " -h            Show help"
    echo
    echo "<file path>:"
    echo " The file path you want cp from. The path is local."
    echo
    echo "<Dest path>:"
    echo " The destination path on each node you want cp to."
    echo
}

function showErr()
{
    echo "Error: $1" > /dev/stderr
}

while getopts hu:: opt; do
    case $opt in
    h)
        echo $mod_desc
        showHelp
        exit 0;;
    u)
        user=$OPTARG;;
    *)
        showHelp > /dev/stderr
        exit -1
    esac
done
shift $((OPTIND-1))
filepath=$1
destpath=$2

echo -n "password of $user: "
read -s passwd
echo

for node in `cat $nodelistfile`; do
    echo
    echo "Start to cp to node $node..."
    
    expect cp-eachnode.exp $node $user $passwd $filepath $destpath
    if [ $? != 0 ]; then
        showErr "Copy file to $user@$node failed."
        exit 1
    fi
    
    echo "Bye, node $node."
done
