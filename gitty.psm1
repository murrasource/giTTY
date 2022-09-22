function gitty {
    param (
        # Parameter help description
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Command,

        [Parameter(Position=1, Mandatory=$false, ValueFromRemainingArguments=$true)]
        [string]$Argument
    )

    function settings {
        param (
            [Parameter(Position=0, Mandatory=$false)]
            [ValidateSet("show", "config", "")]
            [string]$Verb
        )

        switch ($Verb) {
            "config"    {
                function ConfigMenu {
                    param(
                        [string]$Title = "Git Settings"
                    )
                    Clear-Host
                    Write-Host "================= $Title ================="

                    Write-Host "1) Username"
                    Write-Host "2) Email"
                    Write-Host "3) Add SSH Key"
                    Write-Host "q) Press 'q' to quit."

                    $Selection = Read-Host "Please make a selection"

                    switch ($Selection) {
                        "1"     {   $Username = Read-Host -Prompt "Please enter your username:  "; git config --global user.name $Username                                  }
                        "2"     {   $Email = Read-Host -Prompt "Please enter your email:  "; git config --global user.email $Email                                          }
                        "3"     {   ssh-keygen -b 2048 -t rsa -f "$HOME/.ssh/gitty" -q -N '""';
                                    Start-Process ssh-agent;
                                    Get-Content "$HOME/.ssh/gitty.pub" | Set-Clipboard;
                                    Write-Host "The public RSA key has been copied to your clipboard. Please paste this in your remote repository's SSH Public Keys area."; }
                        "q"     {   }
                        Default {   ConfigMenu  }
                    }
                }

                ConfigMenu
            }
            Default {
                $Setting = New-Object System.Collections.ArrayList

                $Username = git config --get user.name
                $temp = New-Object System.Object
                $temp | Add-Member -MemberType NoteProperty -Name "Setting" -Value "Username"
                $temp | Add-Member -MemberType NoteProperty -Name "Value" -Value "$Username"
                $Settings.Add($temp) | Out-Null

                $Email = git config --get user.email
                $temp = New-Object System.Object
                $temp | Add-Member -MemberType NoteProperty -Name "Setting" -Value "Email"
                $temp | Add-Member -MemberType NoteProperty -Name "Value" -Value "$Email"
                $Settings.Add($temp) | Out-Null

                $Settings | Format-Table
            }
        }
    }

    function current {
        $BRANCH = git branch --show-current
        $HASH = git rev-parse --short HEAD
        Write-Host "${BRANCH}: ${HASH}"
    }

    function remote {
        $BRANCH = git branch --show-current
        git branch -r | Select-String "(?m)^[\s]*\S*\/+$BRANCH$"
    }

    function connect {
        function ConnectMenu {
            param (
                [string]$Title = "Connect to Remote"
            )
            Clear-Host
            Write-Host "================= $Title ================="

            $LocalBranch = Read-Host "Local branch name (e.g. 'develop')"
            $RemoteOptions = git branch -r | Select-String "(?m)^[\s]*\S*\/+$LocalBranch$"
            $i = 0

            foreach ($Option in $RemoteOptions) {
                Write-Host "$($i + 1)) $Option"
                $i++
            }

            $Selection = Read-Host "Please make a selection"
            $SelectedRemote = $RemoteOptions[$Selection - 1].ToString().Trim()
            git branch --set-upstream-to=$SelectedRemote $LocalBranch
        }
    }

    function trail {
        param (
            [Parameter(Position=0, Mandatory=$false)]
            [string]$ParamString
        )

        $Arguments = $ParamString.Split(" ")
        $Commits = $Arguments[0]

        switch -Regex ($Commits) {
            "\d+"   {   $Number = "-n $Commits" }
            Default {   $Number = "--all"       }
        }

        git log --graph --abbrev-commit --decorate --format=format:'%C(bold red)%h%C(reset) - %C(bold green)(%cr)%C(reset) %C(bold white)- %an%C(reset)%C(bold yellow)%d%C(reset)' $Number
    }

    function new {
        param (
            [Parameter(Position=0, Mandatory=$true)]
            [string]$ParamString
        )

        $Arguments = $ParamString.Split(" ")
        $Branch = $Arguments[0]
        $Source = $Arguments[1]

        if (!$Source) {
            $Source = master
        }

        git checkout $Source
        git fetch
        git pull
        git checkout -b $Branch $Source
    }

    function update {
        git fetch
        git pull
    }

    function destroy {
        param (
            [Parameter(Position=0, Mandatory=$true)]
            [string]$Branch
        )

        function DestroyMenu {
            param(
                [string]$Title = "Destroy $Branch"
            )
            Clear-Host
            Write-Host "================= $Title ================="

            Write-Host "1) Destroy only the local copy of $Branch"
            Write-Host "2) Destroy both remote & local copy of $Branch"
            Write-Host "q) Press 'q' to quit."

            $Selection = Read-Host "Please make a selection"

            switch ($Selection) {
                "1"     {   git checkout master; git branch -d $Branch  }
                "2"     {   git chekcout master; git branch -D $Branch  }
                "q"     {   }
                Default {   DestroyMenu  }
            }
        }

        DestroyMenu

    }

    function cut {
        git stash
    }

    function paste {
        git stash pop
    }

    function undo {
        param(
            [Parameter(Position=0, Mandatory=$true)]
            [string]$CommitHash
        )

        function UndoMenu {
            
            $Title = "Undo Changes from Commit $CommitHash"

            Clear-Host
            Write-Host "================= $Title ================="

            git show --format=%B $CommitHash

            Write-Host "Do you want to:"
            Write-Host "1) Make a commit with these undo changes"
            Write-Host "2) Undo the changes, but don't commit yet"
            Write-Host "q) Press 'q' to quit."

            $Selection = Read-Host "Please make a selection"

            switch ($Selection) {
                "1"     {   git revert --edit $CommitHash       }
                "2"     {   git revert --no-edit $CommitHash    }
                "q"     {   }
                Default {   UndoMenu  }
            }
        }

        $CommitExists = git show -s --format=%B $CommitHash
        if ($CommitExists) {    UndoMenu    }
        else {   }
    }

    function backpedal {
        
        function BackpedalMenu {
            
            $CommitHash = git rev-parse --short HEAD
            $Title = "Delete Commit $CommitHash"
            Clear-Host
            Write-Host "================= $Title ================="

            git log -1

            Write-Host "Do you want to:"
            Write-Host "1) Delete commit, but keep track of changes"
            Write-Host "2) Delete commit, do not track, but keep changes"
            Write-Host "3) Delete commit, do not track, and delete all changes"
            Write-Host "q) Press 'q' to quit."

            $Selection = Read-Host "Please make a selection"
            switch ($Selection) {
                "1"     {   git reset --soft HEAD~1     }
                "2"     {   git reset --mixed HEAD~1    }
                "3"     {   git reset --hard HEAD~1     }
                "q"     {   }
                Default {   BackpedalMenu  }
            }
        }

        BackpedalMenu
    }

##########################################################

    switch -Regex ($Command) {
        "settings"  {   settings     $Argument              }
        "current"   {   current      $Argument              }
        "remote"    {   remote       $Argument              }
        "connect"   {   connect      $Argument              }
        "trail"     {   trail        $Argument              }
        "new"       {   new          $Argument              }
        "update"    {   update       $Argument              }
        "destroy"   {   destroy      $Argument              }
        "cut"       {   cut          $Argument              }
        "paste"     {   paste        $Argument              }
        "undo"      {   undo         $Argument              }
        "backpedal" {   backpedal    $Argument              }
        "=.*"       {   git checkout $Command.substring(1)  }
        Default     {
            if ($Argument)  {   git $Command $Argument  }
            else            {   git $Command            }
        }
    }
    
}

Export-ModuleMember -Function gitty