#!/bin/bash

CURRENT_DIR="$(pwd)"
PROJECTS_FILE="$CURRENT_DIR/allprojects"


CONTAINER_FILE=container.yaml

TMP_DIR=$(mktemp -d)
cd $TMP_DIR

#UPDATED=()
#ALREADY_HAS_GO_ELEMENT=()
MISSING_CONTAINER_YAML=()
#MISSING_MANIFETST_FILE=()
#PUSHED=()
NO_EXTRA_ATTRS=()
NO_PATH=()
NO_ARCH=()
HAS_BOTH=()
NO_21=()
NO_20=()
NO_14=()
PRESENTIN_20=()
PRESENTIN_14=()
MISSINGIN_20=()
MISSINGIN_14=()
NO_FILE_IN_20=()

mkdir distgit

function update_containers_yamls() {
    PROJECT=$1
    US_REPO=$2
    echo "Cloning $PROJECT"
    git clone ssh://pkgs.devel.redhat.com/containers/$PROJECT
    if [[ $? -ne 0 ]]; then
        return
    fi
    cd $PROJECT
    git checkout -b 21 origin/cnv-2.1-rhel-8
    if [[ $? -ne 0 ]]; then
        NO_21+=("$PROJECT")
        return
    fi


    if test -f $CONTAINER_FILE; then

        CONTAINER_PATH=$(grep  "^go:" -A4 container.yaml | grep "^[ ]*[-]*[ ]*path:" | awk -F ':' '{print $2}')
        CONTAINER_ARCHIVE=$(grep  "^go:" -A4 container.yaml | grep "^[ ]*[-]*[ ]*archive:" | awk -F ':' '{print $2}')

        if [ -z "$CONTAINER_PATH" ] && [ -z "$CONTAINER_ARCHIVE" ]; then
            NO_EXTRA_ATTRS+=("$PROJECT")
            echo "SKIPPING $PROJECT"
            return
        fi

        if [ -z "CONTAINER_PATH" ] ; then
            NO_PATH+=("$PROJECT")
        fi

        if [ -z "CONTAINER_ARCHIVE" ] ; then
            NO_ARCH+=("$PROJECT")
        fi


        HAS_BOTH+=("$PROJECT")

        git checkout -b 20 origin/cnv-2.0-rhel-8

        if [ ! -f $CONTAINER_FILE ]; then
            NO_FILE_IN_20+=("$PROJECT")

        fi

        if [[ $? -ne 0 ]]; then
            NO_20+=("$PROJECT")
        else
            CONTAINER_PATH20=$(grep  "^go:" -A4 container.yaml | grep "^[ ]*[-]*[ ]*path:" | awk -F ':' '{print $2}')
            CONTAINER_ARCHIVE20=$(grep  "^go:" -A4 container.yaml | grep "^[ ]*[-]*[ ]*archive:" | awk -F ':' '{print $2}')
            if [ ! -z "$CONTAINER_PATH20" ] || [ ! -z "$CONTAINER_ARCHIVE20" ]; then
                PRESENTIN_20+=("$PROJECT")
            else
                MISSINGIN_20+=("$PROJECT")
                sed -i "/^[ ]*- module:*/a \ \ \ \ \ \ path: $CONTAINER_PATH" $CONTAINER_FILE
            fi
        fi

        git checkout -b 14 origin/cnv-1.4-rhel-7
        if [[ $? -ne 0 ]]; then
            NO_14+=("$PROJECT")
        else
            CONTAINER_PATH14=$(grep  "^go:" -A4 container.yaml | grep "^[ ]*[-]*[ ]*path:" | awk -F ':' '{print $2}')
            CONTAINER_ARCHIVE14=$(grep  "^go:" -A4 container.yaml | grep "^[ ]*[-]*[ ]*archive:" | awk -F ':' '{print $2}')
            if [ ! -z "$CONTAINER_PATH14" ] || [ ! -z "$CONTAINER_ARCHIVE14" ]; then
                PRESENTIN_14+=("$PROJECT")
            else
                MISSINGIN_14+=("$PROJECT")
                sed -i "/^[ ]*- module:*/a \ \ \ \ \ \ path: $CONTAINER_PATH" $CONTAINER_FILE
            fi
        fi


        UPDATED+=("$PROJECT")
    else
        echo "$CONTAINER_FILE for $PROJECT missing!"
        MISSING_CONTAINER_YAML+=("$PROJECT")
    fi
}


function print_results() {
    echo "################"
    echo "MISSING_CONTAINER_YAML:"
    for i in "${MISSING_CONTAINER_YAML[@]}"
    do
        echo $i
    done

    echo "################"
    echo "NO_EXTRA_ATTRS:"
    for i in "${NO_EXTRA_ATTRS[@]}"
    do
        echo $i
    done

    echo "################"
    echo "NO_PATH:"
    for i in "${NO_PATH[@]}"
    do
        echo $i
    done

    echo "################"
    echo "NO_ARCH:"
    for i in "${NO_ARCH[@]}"
    do
        echo $i
    done

    echo "################"
    echo "HAS_BOTH:"
    for i in "${HAS_BOTH[@]}"
    do
        echo $i
    done
    echo "################"
    echo "NO_21:"
    for i in "${NO_21[@]}"
    do
        echo $i
    done
    echo "################"
    echo "NO_20:"
    for i in "${NO_20[@]}"
    do
        echo $i
    done
    echo "################"
    echo "NO_14:"
    for i in "${NO_14[@]}"
    do
        echo $i
    done
    echo "################"
    echo "PRESENTIN_20:"
    for i in "${PRESENTIN_20[@]}"
    do
        echo $i
    done
    echo "################"
    echo "PRESENTIN_14:"
    for i in "${PRESENTIN_14[@]}"
    do
        echo $i
    done
    echo "################"
    echo "MISSINGIN_20:"
    for i in "${MISSINGIN_20[@]}"
    do
        echo $i
    done




    echo "################"
    echo "MISSINGIN_14:"
    for i in "${MISSINGIN_14[@]}"
    do
        echo $i
    done
    echo "################"
    echo "################"
    echo "NO_FILE_IN_20:"
    for i in "${NO_FILE_IN_20[@]}"
    do
        echo $i
    done
    echo "################"
    echo "http:"
    for i in "${MISSINGIN_20[@]}"
    do
        echo "http://pkgs.devel.redhat.com/cgit/containers/$i/tree/container.yaml?h=cnv-2.0-rhel-8"
    done
    echo "################"

    echo "DIR:"
    for i in "${MISSINGIN_20[@]}"
    do
        echo "$TMP_DIR/distgit/$i"
    done
    echo "################"

    echo "14 DIFFS:"
    for i in "${MISSINGIN_14[@]}"
    do
        #BRANCH="origin/cnv-2.1-rhel-8"
        BRANCH="origin/cnv-1.4-rhel-7"

        echo $i
        cd $TMP_DIR/distgit/$i
        git diff
        git add container.yaml
        git commit -m "Adding patch to go module"
        PUSH_BRANCH=$(echo $BRANCH | awk -F '/' '{print $2}')
        echo "@@@@@@@@  CD:  cd $TMP_DIR/distgit/$i"
        echo " $$$$$$$$    PUSH:    git push origin HEAD:$PUSH_BRANCH"
        echo "============================="
    done

}

function update_repo() {
    PROJECT=$1


    git status|grep "$CONTAINER_FILE"
    CHANGED=$?
    if [ $CHANGED -eq 0 ]
    then
        git add $CONTAINER_FILE
        git commit -m "Update in $CONTAINER_FILE"
        PUSH_BRANCH=$(echo $BRANCH | awk -F '/' '{print $2}')
        echo "Pushing changes for $PROJECT: git push origin HEAD:$PUSH_BRANCH"
        git push origin HEAD:$PUSH_BRANCH
        echo "Pushed new manifest for $PROJECT"
        PUSHED+=("$PROJECT")
    else
        echo "No changes in $PROJECT!!! "
    fi
}


while read LINE
do
    if [[ -z "$LINE" ]]; then
        continue
    fi
    cd $TMP_DIR/distgit
    PROJECT=$(echo $LINE | awk -F ' ' '{print $1}')
    US_REPO=$(echo $LINE | awk -F ' ' '{print $2}')
    update_containers_yamls $PROJECT $US_REPO

done < <(cat $PROJECTS_FILE)

#for i in "${UPDATED[@]}"
#do
#    cd $TMP_DIR/distgit/$i
#    update_repo $i
#done


print_results

echo "Deleting tempdir: $TMP_DIR"
#rm -rf $TMP_DIR