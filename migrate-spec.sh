#!/usr/bin/env bash
BASEDIR=$(dirname "$0")

function fenceBanner() {
    echo ''
    echo "+----------------------------------------------------------------------+"
    printf "| %-68s |\n" "`date`"
    echo "|                                                                      |"
    printf "|`tput bold` %-68s `tput sgr0`|\n" "$@"
    echo "+----------------------------------------------------------------------+"
    echo ''
}

function prepend() {
    local PREPEND=$1
    local LIST=$(echo ${@:2} | tr " " "\n")

    while IFS= read -r line; do
        echo "${PREPEND}${line}";
    done <<< "$LIST"
}


function specChanged () {
    local COMMIT=$1
    local WORKING='.'
    local BASE="$WORKING/spec-migrate-temp"
    local REPO='specifications'
    local REPOPATH="$BASE/$REPO"
    local REPOURL="git@github.com:mongodb/$REPO.git"

    function clone () {
        rm -rf $REPOPATH
        git -C $BASE clone $REPOURL
        git -C $REPOPATH checkout $COMMIT
    }

    function changed () {
        git -C $REPOPATH show \
            --pretty="format:" \
            --name-only $COMMIT \
        | grep source/ \
        | grep -v .rst \
        | sed -e 's/source\///' \
        | sed -e 's/\/tests.*$//' \
        | uniq
    }

    clone &>/dev/null
    CHANGES=$(changed)
    echo ${CHANGES}
}

function specMigrate () {
    local COMMIT=$1
    local WORKING='.'
    local BASE="$WORKING/spec-migrate-temp"
    local REPO='specifications'
    local REPOPATH="$BASE/$REPO"
    local REPOURL="git@github.com:mongodb/$REPO.git"

    # fully replaces driver spec folder with changes
    function migrateSpec () {
        local SPEC=$1
        local SOURCE="$REPOPATH/source/$SPEC/tests/"
        local DEST="$WORKING/test/spec/$SPEC/"
        mkdir -p $DEST
        rsync -av --delete $SOURCE $DEST &> /dev/null
    }

    # updates all changed specs
    function migrateChanges () {
        for line in "$@"
        do
            migrateSpec $line
        done
    }

    mkdir -p $BASE
    CHANGES=`specChanged $COMMIT`
    fenceBanner "migrating changes"
    migrateChanges $CHANGES
    rm -rf $BASE
}

specMigrate $1
