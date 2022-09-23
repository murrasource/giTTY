#!/bin/bash

COMMAND=$1;
shift
ARUGMENTS=$@;


function settings {
    OPTION=$1
    if [[ "$OPTION" != "show" && "$OPTION" != "config" && "$OPTION" != "" ]]
    then
        echo "  OPTIONS: show, config"
        exit 1
    fi

    if [[ "$OPTION" == "" || "$OPTION" == "show" ]]
    then
        echo "  Username: `git config --get user.name`"
        echo "  Email:    `git config --get user.email`"
    fi

    if [[ "$OPTION" == "config" ]]
    then
        clear
        echo "================= Git Settings ================="
        select opt in Username Email SSHkey Quit; do
            case $opt in
                Username)
                    read -p "Enter the username:    " username
                    git config --global user.username $username
                    exit 0
                    ;;
                Email)
                    read -p "Enter the email:    " email
                    git config --global user.email $email
                    exit 0
                    ;;
                SSHkey)
                    ssh-keygen -b 2048 -t rsa -f "$HOME/.ssh/gitty" -q -N '""'
                    ssh-add
                    cat "$HOME/.ssh/gitty.pub" | pbcopy
                    echo "The public RSA key has been copied to your clipboard. Please paste this in your remote repository's SSH Public Keys area."
                    exit 0
                    ;;
                Quit)
                    exit 0
            esac
        done
    fi
}

function current {
    git branch --show-current
    git rev-parse --short HEAD
    exit 0
}

function remote {
    BRANCH=(git branch --show-current)
    git branch -r | Select-String "(?m)^[\s]*\S*\/+$BRANCH$"
    exit 0
}

function connect {
    clear
    echo "================= Connect to Remote ================="
    LOCALBRANCH=`git branch --show-current`
    REMOTEOPTIONS=`git branch -r | Select-String "(?m)^[\s]*\S*\/+$LocalBranch$"`
    select opt in $REMOTEOPTIONS; do
        git branch --set-upstream-to=$opt $LOCALBRANCH
    done
    exit 0
}

function trail {
    if [[ $1 == "" ]]
    then
        NUMBER="--all"
    else
        NUMBER="-n $1"
    fi
    git log --graph --abbrev-commit --decorate --format=format:'%C(bold red)%h%C(reset) - %C(bold green)(%cr)%C(reset) %C(bold white)- %an%C(reset)%C(bold yellow)%d%C(reset)' $NUMBER
    exit 0
}

function new {
    BRANCH=$1
    SOURCE=$2

    git checkout $SOURCE
    git fetch
    git pull
    git checkout -b $BRANCH $SOURCE
    exit 0
}

function update {
    git fetch
    git pull
    exit 0
}

function destroy {
    if [[ $1 == "" ]]
    then
        echo "  You must specify the branch: (gitty destroy develop)"
        exit 1
    else
        clear
        echo "================= Destroy $1 ================="
        select opt in "Destroy only the local copy of $1" "Destroy both remote & local copies of $1" Quit; do
            case $opt in
                "Destroy only the local copy of $1")
                    git checkout master
                    git branch -d $1
                    ;;
                "Destroy both remote & local copies of $1")
                    git checkout master
                    git branch -D $1
                    ;;
                Quit)
                    exit 0
                    ;;
            esac
        done
        exit 0
    fi
}

function cut {
    git stash
    exit 0
}

function paste {
    git stash pop
    exit 0
}

function undo {
    if [[ $1 == "" ]]
    then
        echo "  You must specify the Commit Hash: (gitty undo 96370d54)"
        exit 1
    else
        clear
        echo "================= Undo Changes from Commit $1 ================="
        select opt in "Make a commit with the undo changes" "Make the changes, but don't commit yet" Quit; do
            case $opt in
                "Make a commit with the undo changes")
                    git revert --edit $1
                    ;;
                "Make the changes, but don't commit yet")
                    git revert --no-edit $1
                    ;;
                Quit)
                    exit 0
                    ;;
            esac
        done
        exit 0
    fi
}

function backpedal {
    clear
    echo "================= Delete Commit `git rev-parse --short HEAD` ================="
    git log -1
    select opt in "Delete commit, but keep track of changes" "Delete commit, do not track, but keep changes" "Delete commit, do not track, and delete all changes" Quit; do
        case $opt in
            "Delete commit, but keep track of changes")
                git reset --soft HEAD~1
                ;;
            "Delete commit, do not track, but keep changes")
                git reset --mixed HEAD~1
                ;;
            "Delete commit, do not track, and delete all changes")
                git reset --hard HEAD~1
                ;;
            Quit)
                exit 0
                ;;
        esac
    done
    exit 0
}

############################################

case $COMMAND in
    settings)
        settings $ARUGMENTS
        ;;
    current)
        current $ARUGMENTS
        ;;
    remote)
        remote $ARUGMENTS
        ;;
    connect)
        connect $ARUGMENTS
        ;;
    trail)
        trail $ARUGMENTS
        ;;
    new)
        new $ARUGMENTS
        ;;
    update)
        update $ARUGMENTS
        ;;
    destroy)
        destroy $ARUGMENTS
        ;;
    cut)
        cut $ARUGMENTS
        ;;
    paste)
        paste $ARUGMENTS
        ;;
    undo)
        undo $ARUGMENTS
        ;;
    backpedal)
        backpedal $ARUGMENTS
        ;;
    -*)
        git checkout "${COMMAND:1}"
        ;;
    *)
        git $COMMAND $ARUGMENTS
        ;;
esac

exit 0