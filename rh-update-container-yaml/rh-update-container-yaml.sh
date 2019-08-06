#!/bin/bash

CURRENT_DIR="$(pwd)"
PROJECTS_FILE="$CURRENT_DIR/projects"
BRANCH=$1
DOWNSTREAM_USER=$2


if [ -z "$BRANCH" ]; then
   echo "No branch specified!"
   exit 1
fi

CONTAINER_FILE=container.yaml
MANIFETST_FILE=rh-manifest.txt
LOCAL_BRANCH=containeryamlbranch

TMP_DIR=$(mktemp -d)
cd $TMP_DIR

UPDATED=()
ALREADY_HAS_GO_ELEMENT=()
MISSING_CONTAINER_YAML=()
MISSING_MANIFETST_FILE=()
PUSHED=()


mkdir distgit

function update_containers_yamls() {
    PROJECT=$1
    US_REPO=$2
    echo "Cloning $PROJECT"
    git clone ssh://pkgs.devel.redhat.com/containers/$PROJECT
    cd $PROJECT
    git checkout -b $LOCAL_BRANCH $BRANCH


    if test -f $CONTAINER_FILE; then

        grep  "^go:" container.yaml
        if [ $? -eq 0 ]; then
            echo "$CONTAINER_FILE for $PROJECT already contains the \"go:\" element"
            ALREADY_HAS_GO_ELEMENT+=("$PROJECT")
            return
        fi

        if [ -z "$US_REPO" ]; then
            echo "Looking for u/s repo in manifest file"
            if test -f $MANIFETST_FILE; then
                FIRST_LINE=$(head -1 $MANIFETST_FILE)
                US_REPO=$(echo $FIRST_LINE | awk -F ':' '{print $1}')
                echo "Using provided u/s repo from $MANIFETST_FILE: $US_REPO"
            else
                echo "$MANIFETST_FILE for $PROJECT missing"
                MISSING_MANIFETST_FILE+=("$PROJECT")
                return
            fi
        else
            echo "Using provided u/s repo: $US_REPO"
        fi


        echo "
go:
   modules:
    - module: $US_REPO
" >> $CONTAINER_FILE


        UPDATED+=("$PROJECT")
    else
        echo "$CONTAINER_FILE for $PROJECT missing!"
        MISSING_CONTAINER_YAML+=("$PROJECT")
    fi
}


function print_results() {

    echo "################"
    echo "Updated repos:"
    for i in "${UPDATED[@]}"
    do
        echo $i
    done

    echo "################"
    echo "Repos which already have the \"go\" element:"
    for i in "${ALREADY_HAS_GO_ELEMENT[@]}"
    do
        echo $i
    done

    echo "################"
    echo "Repos with missing conatiner yaml:"
    for i in "${MISSING_CONTAINER_YAML[@]}"
    do
        echo $i
    done

    echo "################"
    echo "Repos with missing manifest file and no u/s specified:"
    for i in "${MISSING_MANIFETST_FILE[@]}"
    do
        echo $i
    done
    echo "################"

    echo "Repos with submitted changes:"
    for i in "${PUSHED[@]}"
    do
        echo $i
    done
    echo "################"
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

for i in "${UPDATED[@]}"
do
    cd $TMP_DIR/distgit/$i
    update_repo $i
done


print_results

echo "Deleting tempdir: $TMP_DIR"
rm -rf $TMP_DIR