#
# install-7zip.ps1
#
#
# Purpose: This script installs 7zip.
# 
# Prerequisites:
#  -- None.
#

########################### VARIABLES ###############################

# Get the CONS3RT environment variables
$global:ASSET_DIR = $null

# Installer File name part
$installerFileNamePart = "7z"

# exit code
$exitCode = 0

# Configure the log file
$LOGTAG = "7zip"
$TIMESTAMP = Get-Date -f yyyy-MM-dd-HHmm
$LOGFILE = "C:\log\cons3rt-install-$LOGTAG-$TIMESTAMP.log"

######################### END VARIABLES #############################

######################## HELPER FUNCTIONS ############################

# Set up logging functions
function logger($level, $logstring) {
   $stamp = get-date -f yyyyMMdd-HHmmss
   $logmsg = "$stamp - $LOGTAG - [$level] - $logstring"
   write-output $logmsg
}
function logErr($logstring) { logger "ERROR" $logstring }
function logWarn($logstring) { logger "WARNING" $logstring }
function logInfo($logstring) { logger "INFO" $logstring }

function get_asset_dir() {
    if ($env:ASSET_DIR) {
        $global:ASSET_DIR = $env:ASSET_DIR
        return
    }
    else {
        logWarn "ASSET_DIR environment variable not set, attempting to determine..."
        if (!$PSScriptRoot) {
            logInfo "Determining script directory using the pre-Powershell v3 method..."
            $Invocation = (Get-Variable MyInvocation -Scope 1).Value
            $scriptDir = Split-Path $Invocation.MyCommand.Path
        }
        else {
            logInfo "Determining the script directory using the PSScriptRoot variable..."
            $scriptDir = $PSScriptRoot
        }
        if (!$scriptDir) {
            $msg =  "Unable to determine the script directory to get ASSET_DIR"
            logErr $msg
            throw $msg
        }
        else {
            $global:ASSET_DIR = "$scriptDir\.."
            logInfo "Determined ASSET_DIR to be: $global:ASSET_DIR"
        }
    }
}

###################### END HELPER FUNCTIONS ##########################

######################## SCRIPT EXECUTION ############################

new-item $logfile -itemType file -force
start-transcript -append -path $logfile
logInfo "Running $LOGTAG..."

try {
    logInfo "Installing at: $TIMESTAMP"

    # Set asset dir
    logInfo "Setting ASSET_DIR..."
    get_asset_dir

    # Set media dir and ensure it exists
    $mediaDir = "$global:ASSET_DIR\media"
    if (test-path $mediaDir) {
        logInfo "Found media directory: $mediaDir"
    }
    else {
        $msg = "Media directory not found: $mediaDir"
        logErr $msg
        throw $msg
    }

    # Find the installer and ensure it exists
    $installerFileName = get-childitem $mediaDir -name | select-string $installerFileNamePart | select-string "exe"
    if (!$installerFileName) {
        $msg = "Unable to determine the installer file name in directory: $mediaDir"
        logErr $msg
        throw $msg
    }
    $installer = "$mediaDir\$installerFileName"
    if (test-path $installer) {
        logInfo "Found the installer: $installer"
    }
    else {
        $msg = "Installer file not found: $installer"
        logErr $msg
        throw $msg
    }

    # Install the app
    logInfo "Running the installer: $installer..."
    $lastexitcode = 0
    & $installer /S
    $installerExitStatus = $?
    $installerExitCode = $lastexitcode

    # Esnure the installer was successful
    if ($installerExitStatus -eq $false -or $installerExitCode -ne 0 ) {
        $msg = "The installer exited with status [$installerExitStatus] and code [$installerExitCode]"
        logErr $msg
        throw $msg
    }
    else {
        logInfo "The installer exited successfully!"
    }
}
catch {
    logErr "Caught exception after $($stopwatch.Elapsed): $_"
    $exitCode = 1
}
finally {
    logInfo "$LOGTAG complete in $($stopwatch.Elapsed)"
}

###################### END SCRIPT EXECUTION ##########################

logInfo "Exiting with code: $exitCode"
stop-transcript
get-content -Path $logfile
exit $exitCode
