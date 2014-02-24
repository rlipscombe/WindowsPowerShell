WindowsPowerShell
=================

My powershell folder.

Installation
------------

    # Fix execution policy (must be run elevated):
    Set-ExecutionPolicy -Force RemoteSigned

    # Install it
    mkdir (Split-Path $PROFILE)
    cd (Split-Path $PROFILE)
    git clone git://github.com/rlipscombe/WindowsPowerShell.git .

Other modules
-------------

    * PsGet
    * Posh-Git
    * pscx
