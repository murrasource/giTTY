#!/bin/bash

##################################################
### giTTY - Your Friendly Version of `git` CLI ###
##################################################

# Parse the command and arguments
#   > gitty $COMMAND $ARGUMENTS
COMMAND=$1;
shift
ARUGMENTS=$@;

# Get help with gitty
function gitty_help {
    WITH=$1
    printf "\n"
    printf "##################################################\n"
    printf "#### giTTY - Your Friendly Version of git CLI ####\n"
    printf "##################################################\n\n"
    if [[ $WITH == "" ]]
        then
        printf "Usage:\n"
        printf "\t-h, --help, help: Get help on gitty or any of the following commands\n"
        printf "\tsettings:         View or configure git configuration\n"
        printf "\tcurrent:          View the current branch name\n"
        printf "\tremote:           View the remote branch\n"
        printf "\tconnect:          Connect local branch to remote branch\n"
        printf "\ttrail:            See a history of commits\n"
        printf "\tnew:              Create a new branch\n"
        printf "\tupdate:           Fetch and pull latest\n"
        printf "\tdestroy:          Nuke your branch\n"
        printf "\tcut:              Cut your git changes to be applied later\n"
        printf "\tpaste:            Paste your cut git changes\n"
        printf "\tundo:             Undo a previous commit by making a new commit\n"
        printf "\tbackpedal:        Remove a commit from the history (use sparingly)\n"
    else
        printf "gitty $WITH [COMMANDS] [FLAGS]\n"
        case $WITH in
            settings)
                printf "\tCOMMANDS:\n"
                printf "\t\tshow:     Show the current settings for git\n"
                printf "\t\tconfig:   Change or configure git's settings\n"
                printf "\tFLAGS:\n"
                printf "\t\t"
                ;;
            current)
                ;;
            *)
                ;;
            esac
    fi
    printf "\n\n"
}

# Configure git
function gitty_settings {
    OPTION=$1
    if [[ $OPTION == "help" ]]
    then
        gitty_help settings
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
                    ssh-add "$HOME/.ssh/gitty"
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

# Current Branch
function gitty_current {
    git branch --show-current
    git rev-parse --short HEAD
    exit 0
}

# Remote for Current Branch
function gitty_remote {
    BRANCH=(git branch --show-current)
    git branch -r | Select-String "(?m)^[\s]*\S*\/+$BRANCH$"
    exit 0
}

# Connect local to remote branch
function gitty_connect {
    echo "================= Connect to Remote ================="
    LOCALBRANCH=`git branch --show-current`
    REMOTEOPTIONS=`git branch -r | grep "(?m)^[\s]*\S*\/+$LocalBranch$"`
    select opt in $REMOTEOPTIONS; do
        git branch --set-upstream-to=$opt $LOCALBRANCH
    done
    exit 0
}

# Commit History
function gitty_trail {
    if [[ $1 == "" ]]
    then
        NUMBER="--all"
    else
        NUMBER="-n $1"
    fi
    git log --graph --abbrev-commit --decorate --format=format:'%C(bold red)%h%C(reset) - %C(bold green)(%cr)%C(reset) %C(bold white)- %an%C(reset)%C(bold yellow)%d%C(reset)' $NUMBER
    exit 0
}

# Create New Branch
function gitty_new {
    BRANCH=$1
    SOURCE=$2
    git checkout $SOURCE
    git fetch
    git pull
    git checkout -b $BRANCH $SOURCE
    exit 0
}

# Fetch and Pull
function gitty_update {
    git fetch
    git pull
    exit 0
}

# Stash Changes
function gitty_cut {
    git stash
    exit 0
}

# Apply Stashed Changes
function gitty_paste {
    git stash pop
    exit 0
}

# Undo commit with commit
function gitty_undo {
    if [[ $1 == "" ]]
        then
        echo "  You must specify the Commit Hash: (gitty undo 96370d54)"
        exit 1
    else
        clear
        echo "================= Undo Changes from Commit $1 ================="
        select opt in "Make a commit with the undo changes" "Make the changes, but don't commit yet" Quit
        do
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

# Delete commit
function gitty_backpedal {
    clear
    echo "================= Delete Commit `git rev-parse --short HEAD` ================="
    git log -1
    select opt in "Delete commit, but keep track of changes" "Delete commit, do not track, but keep changes" "Delete commit, do not track, and delete all changes" Quit
    do
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



if [[ $COMMAND == "" || $COMMAND == "-h" || $COMMAND == "--help" || $COMMAND == "help" ]]
    then
        gitty_help $ARUGMENTS
else
    case $COMMAND in
        settings)
            gitty_settings $ARUGMENTS
            ;;
        current)
            gitty_current $ARUGMENTS
            ;;
        remote)
            gitty_remote $ARUGMENTS
            ;;
        connect)
            gitty_connect $ARUGMENTS
            ;;
        trail)
            gitty_trail $ARUGMENTS
            ;;
        new)
            gitty_new $ARUGMENTS
            ;;
        update)
            gitty_update $ARUGMENTS
            ;;
        destroy)
            gitty_destroy $ARUGMENTS
            ;;
        cut)
            gitty_cut $ARUGMENTS
            ;;
        paste)
            gitty_paste $ARUGMENTS
            ;;
        undo)
            gitty_undo $ARUGMENTS
            ;;
        backpedal)
            gitty_backpedal $ARUGMENTS
            ;;
        -*)
            git checkout "${COMMAND:1}"
            ;;
        *)
            git $COMMAND $ARUGMENTS
            ;;
    esac
fi

exit 0



# function gitty_destroy {
#     if [[ $1 == "" ]]
#     then
#         echo "  You must specify the branch: (gitty destroy develop)"
#         exit 1
#     else
#         clear
#         echo "================= Destroy $1 ================="
#         select opt in "Destroy only the local copy of $1" "Destroy both 
# remote & local copies of $1" Quit; do
#             case $opt in
#                 "Destroy only the local copy of $1")
#                     git checkout master
#                     git branch -d $1
#                     ;;
#                 "Destroy both remote & local copies of $1")
#                     git checkout master
#                     git branch -D $1
#                     ;;
#                 Quit)
#                     exit 0
#                     ;;
#             esac
#         done
#         exit 0
#     fi
# }



