<#
.SYNOPSIS
    Builds and tests Octokit
.DESCRIPTION
    Janky runs this script after checking out a revision and cleaning its
    working tree.
.PARAMETER Clean
    When true, all untracked (and ignored) files will be removed from the work
    tree. Defaults to false.
#>

Param(
    [switch]
    $Clean = $false
)

Set-StrictMode -Version Latest

try {
    # Make the output width reeeeeaaaaaly wide so our output doesn't get hard-wrapped.
    # <http://stackoverflow.com/questions/978777/powershell-output-column-width>
    $Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size -ArgumentList 5000, 25
} catch {
    # Most likely we were run in a cmd.exe terminal which won't allow setting
    # the BufferSize to such a strange size.
}

$rootDirectory = Split-Path (Split-Path $MyInvocation.MyCommand.Path)

Push-Location $rootDirectory

function Die-WithOutput($exitCode, $output) {
    Write-Output $output
    Write-Output ""
    exit $exitCode
}

function Run-Command([scriptblock]$Command, [switch]$Fatal, [switch]$Quiet) {
    $output = ""
    if ($Quiet) {
        $output = & $Command 2>&1
    } else {
        & $Command
    }

    if (!$Fatal) {
        return
    }

    $exitCode = 0
    if ($LastExitCode -ne 0) {
        $exitCode = $LastExitCode
    } elseif (!$?) {
        $exitCode = 1
    } else {
        return
    }

    $error = "Error executing command ``$Command``."
    if ($output) {
        $error = "$error Output:", $output
    }
    Die-WithOutput $exitCode $error
}

if ($Clean) {
    Write-Output "Cleaning work tree..."
    Write-Output ""

    Run-Command -Quiet -Fatal { git clean -xdf }
}

Write-Output "Building Octokit..."
Write-Output ""
$output = .\Build-Solution.ps1 FullBuild Release -MSBuildVerbosity quiet 2>&1
if ($LastExitCode -ne 0) {
    $exitCode = $LastExitCode

    $errors = $output | Select-String ": error"
    if ($errors) {
        $output = "Likely errors:", $errors, "", "Full output:", $output
    }

    Die-WithOutput $exitCode $output
}

$exitCode = 0

exit $exitCode
