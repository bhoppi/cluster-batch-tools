#!/bin/bash
# scripted by Bhoppi Chaw

mod_name=`basename $0`
mod_desc="Distributed exec for all cluster's nodes."

nodelistfile="./nodelist"
argpass=false
asyncmode=false
filemode=false
user=$USER

function showHelp()
{
    echo
    echo "Usage:"
    echo " $mod_name [options] <command>"
    echo
    echo "Options:"
    echo " -f            The <command> is a filename, which will copy to & execute on remote node"
    echo " -h            Show help"
    echo " -i            Continuously exec cmd, no wait for return, ignore errors"
    echo " -l <file>     Specify nodelist file"
    echo " -p <pass>     Give passphrase"
    echo " -u <user>     Exec <command> under user of <user> (defaut: this user)"
    echo
    echo "Example:"
    echo " cl-exec.sh -u root -l nodelist 'date'"
    echo
}

function showErr()
{
    echo
    echo "Error: $1" > /dev/stderr
}

if [ $# -lt 1 ]; then
    showHelp > /dev/stderr
    exit -1
fi
while getopts fhil:p::u:: opt; do
    case $opt in
    f)
        filemode=true;;
    h)
        echo $mod_desc
        showHelp
        exit;;
    i)
        asyncmode=true;;
    l)
        nodelistfile="$OPTARG";;
    p)
        argpass=true
        passwd=$OPTARG;;
    u)
        user=$OPTARG;;
    *)
        showHelp > /dev/stderr
        exit -1
    esac
done
shift $((OPTIND-1))
string=$1

if [ $argpass == false ]; then
    echo -n "Password/KeyPassphrase of $user: "
    read -s passwd
    echo
fi

for node in `cat $nodelistfile`; do
    echo "======== Enter node $node ========"
    
    if [ $filemode == false ]; then
        if [ $asyncmode == false ]; then
            expect run-eachnode.exp "$node" "$user" "$passwd" "$string"
        else
            expect run-eachnode-async.exp "$node" "$user" "$passwd" "$string"
        fi
        
        if [ $? != 0 ]; then
            showErr "Execute command on '$user@$node' failed."
            exit 1
        fi
    else
        filename=`basename $string`
        expect cp-eachnode.exp "$node" "$user" "$passwd" "$string" ""
        if [ $? != 0 ]; then
            showErr "Copy script to '$user@$node' failed."
            exit 2
        fi
        
        if [ $asyncmode == false ]; then
            expect run-eachnode.exp "$node" "$user" "$passwd" "sh '$filename'"
            rv=$?
            
            expect run-eachnode.exp "$node" "$user" "$passwd" "rm -f '$filename'"
        else
            expect run-eachnode-async.exp "$node" "$user" "$passwd" "sh '$filename'; rm -f '$filename'"
            rv=$?
        fi
        
        if [ $rv != 0 ]; then
            showErr "Execute script on '$user@$node' failed."
            exit 3
        fi
    fi
    
    echo "======== Leave node $node ========"
done
