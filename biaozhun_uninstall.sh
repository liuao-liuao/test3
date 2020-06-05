#! /usr/bin/env bash
# Removes all traces of the appplication from the current system
# Parameters:
# -a | --all:  Whether the script should remove the user data
# -i | --ui:   Whether the script should show a success dialog at the end of the process
# -u | --user: The name of the logged-in user

# Make sure the output produced by this script is written out into a log file
LOGFILE="/tmp/uninstall_dlp3-$(basename "$0" .sh)-$(date +%s).log"
exec > "$LOGFILE" 2>&1

function killAllProcess(){
    local -r cnt_process="$(ps -ef|grep $1|grep -v grep|wc -l|sed -e 's/^[ \t]*//g')"
    if [ $cnt_process -gt 0 ]; then
        echo "[$1]:[$cnt_process] kill">&2
        killall -9 $1
    else
        echo "[$1]: No found">&2
    fi
}

function removeUserAgent() {
    echo "removeUserAgent()" >&2
    local -r NAME_USER_AGENT="CGEData.user.agent"
    local -r PATH_USER_AGENT="/Library/LaunchAgents/CGEData.agent.plist"

    #get current longon username
    local -r user_line="$(who | grep console)"
    local -r user_temp="${user_line%' console'*}"
    local -r CUR_LOGONUSER="$(echo ${user_temp} | sed -e 's/^[ ]*//g' | sed -e 's/[ ]*$//g')"
    local -r CUR_UID="$(id -u ${CUR_LOGONUSER})"
    echo "currentLogonUser=<${CUR_LOGONUSER}:${CUR_UID}>"

    #stop agent service
    local -r count_agent_usr="$(launchctl asuser ${CUR_UID} launchctl list|grep ${NAME_USER_AGENT})"
    echo "[SYS] name:[${NAME_USER_AGENT}], Count[${count_agent_usr}]">&2
    if [ -n '$count_agent_usr' ]; then
        echo "[User] launchctl asuser ${CUR_UID} launchctl unload -w ${PATH_USER_AGENT}">&2
        launchctl asuser ${CUR_UID} launchctl unload -w /Library/LaunchAgents/CGEData.agent.plist
        echo "[User] launchctl asuser ${CUR_UID} launchctl remove ${NAME_USER_AGENT}" >&2
        launchctl asuser ${CUR_UID} launchctl remove ${NAME_USER_AGENT}
    else
        echo "[SYS] launchctl unload -w ${PATH_USER_AGENT}">&2
        launchctl unload -w ${PATH_USER_AGENT}
        echo "[SYS] launchctl remove ${NAME_USER_AGENT}" >&2
        launchctl remove ${NAME_USER_AGENT}
    fi

    rm -rf "$PATH_USER_AGENT"
    killAllProcess "CGEData"
}

function removeAgent() {
    echo "removeAgent()" >&2
    local -r NAME_DLP_DEAMON="CirrusGate.DLP3"
    local -r PATH_DLP_DEAMON="/Library/LaunchDaemons/CirrusGate.DLP3.plist"

    #stop dlp service
    local -r count_dlp_service="$(launchctl list|grep ${NAME_DLP_DEAMON})"
    echo "[SYS] name:[${NAME_DLP_DEAMON}], Count[${count_dlp_service}]">&2
    if [ -n '$count_dlp_service' ]; then
        echo "removeAgent:[SYS] launchctl unload -w ${PATH_DLP_DEAMON}">&2
        launchctl unload -w ${PATH_DLP_DEAMON}
        echo "removeAgent:[SYS] launchctl remove ${NAME_DLP_DEAMON}" >&2
        launchctl remove ${NAME_DLP_DEAMON}
    fi

    echo "removeAgent: rm -rf ${PATH_DLP_DEAMON}" >&2
    rm -rf "${PATH_DLP_DEAMON}"  
}

function removeApp(){
    echo "removeApp()" >&2
    local -r APP_PATH="/Applications/DLP.app"

    if [ -d "${APP_PATH}" ];then
        echo "Remove dir ${APP_PATH}" >&2
        rm -rf "$APP_PATH"
    fi
}

function removeAppSupport(){
    echo "removeAppSupport()" >&2

    killAllProcess "CGEAgent"
    killAllProcess "CGEData"

    sleep 2

    local -r APP_SUPP="/Library/Application Support/DLP3.0"

    if [ -d "${APP_SUPP}" ];then
        echo "Remove dir ${APP_SUPP}" >&2
        rm -rf "$APP_SUPP"
    fi

    killAllProcess "CGEUninstall"
    killAllProcess "CGESA"

    killAllProcess "CGEData3"
    killAllProcess "CGEScheduler"
    killAllProcess "CGEScheduler2"
    killAllProcess "CGEScheduler3"
    killAllProcess "CGEComm"
    killAllProcess "CGEComm2"
    killAllProcess "CGEControl"
    killAllProcess "CGEControl2"
    killAllProcess "CGEControl3"
    killAllProcess "CGEDataService"

    sleep 1

    if [ -d "${APP_SUPP}" ];then
        echo "Remove dir ${APP_SUPP} try agin!" >&2
        rm -rf "$APP_SUPP"
    fi
}

function main (){

    echo "Dlp3.0 uninstall..." >&2
    # Make sure we are running as root
    if [[ "$(id -u)" -ne 0 ]]; then
        echo "Script must be executed with root priviledges" >&2
        exit 2
    fi

    removeAppSupport
    removeApp
    removeUserAgent
    removeAgent

    sleep 1

    local -r APP_SUPP="/Library/Application Support/DLP3.0"
    if [ -d "${APP_SUPP}" ];then
        rm -rf "$APP_SUPP"
    fi

    echo "uninstall success!" >&2
}

main "$@"
