#!/bin/bash


cd /tmp/tmp.yaAlJz8PcK/sriov-cni


if [ -z "$(git diff)" ]
then 
    echo "EMPTY"

fi

if [ ! -z "$(git diff)" ]
then 
    echo "FULL"

fi


cd -
