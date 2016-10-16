﻿# Loads all Service Fabric SDK .ps1 files in the global context.
Get-ChildItem (Split-Path $MyInvocation.MyCommand.Path) -Include *.ps1 -Exclude $MyInvocation.MyCommand.Name -Recurse | ForEach-Object { . $_.FullName }

function Get-VstsLocString($Key)
{
    return $Key    
}