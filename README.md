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

* PsGet -- http://psget.net
* Posh-Git -- Install-Module Posh-Git
* pscx -- http://pscx.codeplex.com/releases -- get v3.1.0.
