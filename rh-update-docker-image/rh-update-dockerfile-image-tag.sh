#!/bin/bash

#set -x

CURRENT_DIR="$(pwd)"
PROJECTS_FILE="$CURRENT_DIR/projects"
BRANCH=$1
#BRANCH=${1:-origin/cnv-2.2-rhel-8}
DOWNSTREAM_USER=$2

REPLACE_IN=":8-released"
REPLACE_OUT=":8-ondeck"

if [ -z "$BRANCH" ]; then
   echo "No branch specified!"
   exit 1
fi


LOCAL_BRANCH=containertabbranch

TMP_DIR=$(mktemp -d)
cd $TMP_DIR
echo "TMPDIR: $TMP_DIR "

PREPARED_REPOS=()
REPOS_WITH_DOCKERFILES=()
PUSHED=()
NO_DOCKERFILES=()

function prepare_repo() {
    PROJECT=$1
    echo "Cloning $PROJECT"
    git clone ssh://$DOWNSTREAM_USER@code.engineering.redhat.com/$PROJECT
    cd $PROJECT
    git checkout -b $LOCAL_BRANCH $BRANCH
    find . -name "Dockerfile*" | egrep '.*'
    RES=$?
    if [ $RES == 0 ]; then
        REPOS_WITH_DOCKERFILES+=("$PROJECT")
    else
        echo "----- NO CHANGES IN:   $PROJECT  ------------"
        NO_DOCKERFILES+=("$PROJECT")
    fi
}



function update_dockerfiles() {
    PROJECT=$1
    echo "---------------  $PROJECT  ----------------"
    cd $PROJECT/distgit

    DOCKER_FILES=()
    while IFS=  read -r -d $'\0'; do
        DOCKERFILE=$REPLY
        DOCKER_FILES+=("DOCKERFILE")
        sed -i  's/'$REPLACE_IN'/'$REPLACE_OUT'/g' $DOCKERFILE
        git add $DOCKERFILE
    done < <(find . -name "Dockerfile*" -print0)
}

function commit_changes() {
    PROJECT=$1
    cd $PROJECT
    git commit -m "Update base image tag from :8-released to :8-ondeck"
    PUSH_BRANCH=$(echo $BRANCH | awk -F '/' '{print $2}')
    echo "Pushing changes for $PROJECT: git push ssh://$DOWNSTREAM_USER@code.engineering.redhat.com/$PROJECT HEAD:refs/for/$PUSH_BRANCH"
    git push ssh://$DOWNSTREAM_USER@code.engineering.redhat.com/$PROJECT HEAD:refs/for/$PUSH_BRANCH
    echo "Pushed changes for $PROJECT"
    PUSHED+=("$PROJECT")
}


function print_results() {

    echo "################"
    echo "REPOS_WITH_DOCKERFILES:"
    for i in "${REPOS_WITH_DOCKERFILES[@]}"
    do
        echo "   $i"
    done
    echo "################"

    echo "NO DOCKER FILES:"
    for i in "${NO_DOCKERFILES[@]}"
    do
        echo "   $i"
    done
    echo "################"
}

echo "============== PREPARING REPOS ================"
while read LINE
do
    if [[ -z "$LINE" ]]; then
        continue
    fi
    cd $TMP_DIR
    PROJECT=$(echo $LINE | awk -F ' ' '{print $1}')
    prepare_repo $PROJECT $US_REPO
done < <(cat $PROJECTS_FILE)


echo "============== UPDATING REPOS ================"

for i in "${REPOS_WITH_DOCKERFILES[@]}"
do
    cd $TMP_DIR
    update_dockerfiles $i
done

echo "============== COMMITING CHANGES ================"


for i in "${REPOS_WITH_DOCKERFILES[@]}"
do
    cd $TMP_DIR
    commit_changes $i
done

    cd $TMP_DIR

print_results

echo "Deleting tempdir: $TMP_DIR"
#rm -rf $TMP_DIR