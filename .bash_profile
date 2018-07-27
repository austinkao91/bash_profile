set -o vi

source ~/.sonar/properties
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
export MODELS_HOME="$HOME/workspace/maglev/models"
export APICEM_HOME="/Users/aukao/workspace/maglev/apic-em-core"
export ISAC_HOME="/Users/aukao/Workspaces/DNA_SDK_maglev/ACA_Demo/isac"
export MAG_SETTINGS="$HOME/Downloads/apic-dev-settings.xml"
export UNIQ_HOME="/Users/aukao/.virtualenvs"
export UNIQ_WORK="$APICEM_HOME/test/uniq"
#export PYTHONPATH="${PATH}:$UNIQ_TEST_HOME"
export PATH=$PATH:/usr/local/sbin:$HOME/Downloads/sonarqube-6.5/bin/macosx-universal-64:$HOME/workspace/maglev/tools/build-tools/grapevine
alias ss="source ~/.bash_profile"
alias ll="ls -la"
alias gitgraph='git log --all --decorate --oneline --graph'
alias gitcan="git commit --amend --no-edit"
alias gitpf="git push -f"
alias gitfix="gitcan && gitpf"
alias gitlc="git log --format="%H" -n"
alias vlogin="vagrant up && vagrant ssh"
alias gitup="git fetch && git merge --ff-only"
alias gitfix="gitcan && gitpf"
alias mci="mvn clean install -Dmaven.test.skip=true"
alias jettyup="java -Denable_tcp_md5=false -jar start.jar"
alias uniqup="source $UNIQ_HOME/uniq/bin/activate"
alias setws=set_workspace
alias magload_profile="upload_profile $MAGLEV_PASS $MAGLEV_USER@$MAGLEV_IP"
alias cgrep="grep --color=always"
alias dl="displayLine"
alias gl="getLine"
alias sl="showLineN"

################################################################################
# Git Commands
################################################################################

function gitC() {
	 git status |awk '/Changes not staged for commit:|Unmerged paths:/,/Untracked files:/' | grep -o "them:.*\|us:.*\|deleted:.*\|modified:.*" | awk '{print $1"\t"$2}'
}

function gitR() {
	line_num="$1"
	fileName="$(gitFile $line_num)"
	gitN diff "$line_num"
	info_log "Do you want to commit changes for $fileName? (y/n)"
	read accept
	line_num="$1"
	if [ "$accept" == "y" ]; then
		gitN add "$line_num"
	fi
	line_num=$((line_num+1))
}

function gitBH() {
	git reflog | grep checkout | awk '{print $NF}'
}
function gitBHN() {
	length="$(($#-1))"
	git_args="${@:1:length}"
	line_num="${!#}"
	if [ $# -eq 0 ]; then
		sl gitBH
	else
		line_name=$(gl gitBH ${line_num})
		echo $line_name
		git checkout $line_name
	fi
}

function gitN() {
	length="$(($#-1))"
	git_args="${@:1:length}"
	line_num="${!#}"
	if [ $# -eq 0 ]; then
		displayLine gitC
	else
		line_name=$(gitFile ${line_num})
		info_log "Executing \"git $git_args\" for file \"$line_name\""
		git $git_args $line_name
	    echo
		echo =====================================================================================================================================
		echo
		gitN
	fi
}


function gitFile() {
	#echo "$(gitC  | sed -n "$1p" | awk '{print $NF}')"
	echo "$(getLine gitC $1)"
}

function gitstash() {
	git stash show -p stash@{$1} | grep +++
}

function searchGitStash() {
	for (( i=1; i<=$1; i++ ))
	do
		echo "GIT STASH $i======================================="
		gitstash $i | grep $2
	done
}

function get_mvn_info() {
	GROUP_ID=$(grep $1 -B 3 -A 3 $2  | grep groupId | awk -F '[<>]' '{print $3}')
	ARTIFACT_ID=$(grep $1 -B 3 -A 3 $2  | grep artifactId | awk -F '[<>]' '{print $3}')
	ARTIFACT_VERSION=$(grep $1 -B 3 -A 3 $2  | grep version | awk -F '[<>]' '{print $3}')
	info_log "Extracted details of $1 from the pom $2. Group ID: $GROUP_ID, Artifact ID: $ARTIFACT_ID, Version: $ARTIFACT_VERSION"
}

function mvn_install_from_pom() {
	ARTIFACT_REGEX=$1
	POM_FILE=$2
	JAR=$3
	get_mvn_info $ARTIFACT_REGEX $POM_FILE
	mvn_install_jar $JAR $GROUP_ID $ARTIFACT_ID $ARTIFACT_VERSION jar

}

function mvn_install_jar() {
	mvn install:install-file -Dfile=$1 -DgroupId=$2 -DartifactId=$3 -Dversion=$4 -Dpackaging=$5

}

function build_sxp() {
	SXP_ENGINE_POM=$ISAC_HOME/jars/sxp-parent/sxp-engine-facade/pom.xml
	cd $SXP_HOME;
	if [ $# -ne 0 ]; then
		exec mvn $*
	fi
	SXP_CORE_JAR=$(find . -iname org.opendaylight.sxp.sxp-core*jar)
	SXP_API_JAR=$(find . -iname org.opendaylight.sxp.sxp-api*jar)
	info_log "Install sxp-core jar from $SXP_CORE_JAR and sxp-api jar from $SXP_API_JAR"
	exec mvn_install_from_pom at-sxp-core $SXP_ENGINE_POM $SXP_CORE_JAR && mvn_install_from_pom at-sxp-api $SXP_ENGINE_POM $SXP_API_JAR 

}

################################################################################
# Helper Commands
################################################################################
function showLineN() {
	length="$(($#-1))"
	args="${@:1:length}"
	line_num="${!#}"
	info_log $line_num
	num_regex='^[0-9]+$'
	if [[ $line_num =~ $num_regex ]]; then
		line_name=$(getLine $args ${line_num})
		info_log "Executing \"$args\" for file \"$line_name\""
		$args $line_name
	    lineSeparator
		displayLine $args 
	else
		displayLine $args $line_num
	fi
}

function lineSeparator() {
	echo
	echo =====================================================================================================================================
	echo
}

function displayLine() {
	exec "$@" |sed -e /^$/d | nl -s ') ' | more
	if [[ "$@" != "elc" ]]; then
		storeCommand $@
	fi
}

function cdd() {
	cd "$*"
}

function getLine() {
	length="$(($#-1))"
	command="${@:1:length}"
	line_num="${!#}"

	displayLine "$command" | sed -n "${line_num}p" | awk '{print $NF}'
}
function elc() {
	exec $LC
}

function storeCommand() {
	info_log "STORING COMMAND $@"
	echo "LC=\"$@\"" > $HOME/.cli
	source ~/.cli
}

function exec() {
	$@
	local status=$?
	if [ $status -ne 0 ]; then
		error_log "Failed executing $1. Exit code $status"
		kill -INT $$
	fi
}

function info_log() {
    echo "[INFO] $1"
}

function error_log() {
	echo "[ERROR] $1"
}


function clear_known() {
	sed -i -e "${1}d" ~/.ssh/known_hosts
}


function set_workspace() {
	export WORKSPACE="$(pwd)"
	echo "WORKSPACE=\"$WORKSPACE\"" > $HOME/.workspace
	echo $WORKSPACE
}

function set_var() {
	export "$1"="$2"
	echo "$1=$2"
}
function ipAddr() {
	ifconfig | grep -e "inet " | grep -v 127.0.0.1 | awk '{print $2}'
}

function fd() {
    LINE=${2:-0}
	declare -f | grep $1 -A$LINE
}

function openPR() {
    $1 2>&1 | grep -E "remote(.+)*$2" | awk '{print $2}' | xargs chrome.exe
}

function gitBranch() {
   git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

function setShellPrompt() {
    PS1="\e[1;31m\t[\e[m\$?\e[1;31m\\h:\e[1;35m\\W\e[1;31m \\u\[\033[32m\]\$(gitBranch)\e[m\\$ "
    PS2=">"
}

function conn_docker() {
	docker exec -it $(docker ps | grep $1 | head -n 1 | awk '{print $1}') /bin/bash
}

function add_sp() {
	sshpass -p $*
}

function upload_profile() {
	echo $1
	echo $2
    add_sp $1 scp ~/.bash_profile $2:/tmp
	add_sp $1 scp ~/.vimrc $2:/tmp
}

################################################################################
# Maglev Commands
################################################################################

function maglev_plugin_patch() {
	INSTALL_LOC=${2:-"model-plugin"}
	info_log "Installing $1 to $INSTALL_LOC"
	maglev_patch plugin add $1 fusion "pkg-$INSTALL_LOC" $INSTALL_LOC
}

function mag_sonar_build() {
	declare -a arr=(
		"/Users/aukao/Workspaces/DNA SDK maglev/ACA_Demo/isac/jars/sxp-parent/sxp-engine-facade"
		"/Users/aukao/Workspaces/DNA SDK maglev/ACA_Demo/isac/jars/sxp-parent/aca-sxp-api"
		"/Users/aukao/Workspaces/DNA SDK maglev/ACA_Demo/isac/services/aca-sxp-connector-service"
		"/Users/aukao/Workspaces/DNA SDK maglev/ACA_Demo/isac/services/aca-sxp-binding-mgr-service"
	)
	for i in "${arr[@]}"
	do
		info_log "Building $i with options $*"
		cdd $i
		mag_mvn $*
	done
}

function mag_install_patcher() {

	PATCHER_VERSION="maglev-patcher"
	if [ $# -ne 0 ]; then
		PATCHER_VERSION="maglev-patcher==$1"
	fi
	mag_sudo_exec "/opt/maglev/bin/pip install --index-url https://engci-maven-master.cisco.com/artifactory/api/pypi/apic-em-pypi-group/simple --upgrade --no-deps --no-cache-dir $PATCHER_VERSION" 
}

function mvn_compile_engine() {
	cd "$ACA_WORK/../jars/sxp-parent/sxp-engine-facade" &&  mvn clean package install -s $MAG_SETTINGS $* && cd -
}

function maglev_patch() {
    IP=$MAGLEV_IP
	TYPE=$1
	ACTION=$2
	DIR=$3
	APPSTACK=$4
	PACKAGE=$5
	SBG=$6
	if [ "$PACKAGE" = "" ]; then
		PACKAGE_OPTS=""
	else
		PACKAGE_OPTS="--package $PACKAGE"
	fi

	info_log "Uploading $DIR to $IP"
    exec maglev_scp $DIR
	
	FILENAME=$(basename $DIR)
	if [[ "$ACTION" = "add" && "$PACKAGE_OPTS" = "" ]]; then
		info_log "PACKAGE_OPTS MUST BE SPECIFIED FOR ADD"
		return 1
	fi
	info_log "Adding $FILENAME to service at $IP with appstack $APPSTACK and package $PACKAGE_OPTS"
	maglev_patcher_exec $TYPE $ACTION /tmp/$FILENAME --appstack $APPSTACK $PACKAGE_OPTS $SBG  
}

function exec_at() {
	EXEC_DIR=$1
	EXEC_COMMAND=${@:2}
	info_log "Executing $EXEC_COMMAND at $EXEC_DIR"
	cd "$EXEC_DIR" && eval $EXEC_COMMAND && cd -	
}

function git_update() {
	BRANCH=$1
	REMOTE="origin"
	info_log "Checking out $BRANCH from $REMOTE and updating it"
	git fetch $REMOTE $BRANCH && git checkout $BRANCH && git pull $REMOTE $BRANCH 
}

function build_isac() {
	OPTS=${@:2}
	BRANCH_NAME=$1
	info_log "Building isac repo on $BRANCH_NAME with the maven options $OPTS"
	exec_at $APICEM_HOME/services/network-design/common-settings-core "git_update release/$BRANCH_NAME && mag_mvn clean install $OPTS"
    	
	exec_at $MODELS_HOME/models/aca-sxp-model "git_update feature/aca_$BRANCH_NAME && mag_mvn clean install $OPTS"
	mag_api_build $MODELS_HOME/models/aca-policy-model $OPTS
	mag_api_build $MODELS_HOME/models/aca-trustsec-model $OPTS
	exec_at $WORKSPACE "git_update release/$BRANCH_NAME && mag_mvn clean install $OPTS"

}

function mag_service_wait() {
	info_log "Waiting for $1 to deploy."	
	status=$(mag_package_status $1)
	TIMEOUT=1000
	ST=10
	while [ "$status" != "DEPLOYED" ] && [ "$TIMEOUT" -gt 0 ]
	do
		sleep $ST
		TIMEOUT=$(($TIMEOUT-$ST))
		status=$(mag_package_status $1)
		info_log "$status"
	done
	if [ "$TIMEOUT" -eq 0 ]; then
		info_log "Timed out waiting for $1 to deploy. Status is $status"	
		return 1
	else
		info_log "$1 is now $status"
	fi
}

function mag_package_status() {
	PKG_NAME=$1
	magexec maglev package status $PKG_NAME| grep $PKG_NAME | awk '{print $NF}'
}

function mag_deploy() {
	SERVICE_NAME="$1"
	BUILD_OPTS=${@:2}
	info_log "Building package at $(pwd)"
	exec mag_mvn $BUILD_OPTS 
	mag_patch $SERVICE_NAME
}

function mag_patch() {
	SERVICE_NAME="$1"
	TARGZ=$(find . -iname '*.tar.gz' | grep $CEC_USER)
    info_log "FOUND tar.gz at $TARGZ"
    exec maglev_patch service add $TARGZ fusion $SERVICE_NAME
}
function mag_build_deploy() {
	BUILD_OPTS=${@:2}
	SERVICE_NAME_MAP="$1"
	info_log $SERVICE_NAME_MAP
	build_dep $BUILD_OPTS

    IFS=',' read -ra SERVICE_LIST <<< "$SERVICE_NAME_MAP"
    for i in "${SERVICE_LIST[@]}"; do
        SERVICE_NAME=${i%%:*}
        SERVICE_DIR=${i#*:}
        info_log "Navigating to $SERVICE_DIR and building and deploy the package $SERVICE_NAME with build options $BUILD_OPTS"
        exec cd $SERVICE_DIR && mag_deploy $SERVICE_NAME $BUILD_OPTS && cd -
    done
}
function build_dep() {
	BUILD_OPTS="$*"
    info_log "Building dependency path at $DEP_PATH"
    IFS=';' read -ra DEP_LIST<<< "$DEP_PATH"
    for DEP in "${DEP_LIST[@]}"; do
        info_log "BUILDING DEPENDENCY AT $DEP with build options $BUILD_OPTS"
        exec mag_api_build $DEP $BUILD_OPTS
    done

}

function mag_deploy_test() {
	
	BUILD_OPTS=${@:2}
	build_dep $BUILD_OPTS
	SERVICE_NAME_MAP="$1"
	IFS=';' read -ra SERVICE_LIST <<< "$SERVICE_NAME_MAP"
	for i in "${SERVICE_LIST[@]}"; do
		SERVICE_NAME=${i%%:*}
		SERVICE_DIR=${i#*:}
		info_log "Navigating to $SERVICE_DIR and building and deploy the package $SERVICE_NAME with build options $BUILD_OPTS"
		exec cd $SERVICE_DIR && mag_deploy $SERVICE_NAME $BUILD_OPTS && cd -
	done

    IFS=';' read -ra SERVICE_LIST <<< "$SERVICE_NAME_MAP"
	for i in "${SERVICE_LIST[@]}"; do
		SERVICE_NAME=${i%%:*}
		exec mag_service_wait $SERVICE_NAME
	done
	mag_auto_test
}

function mag_auto_test() {
	setup_auto_conf 
	uniqup && py.test -s $AUTOMATION_TEST_DIR  	
}

function setup_auto_conf() {
    CONF="${1:-$AUTO_TEST_CONFIG}"
	sed -i -e "s/\"host\".*/\"host\":\"$MAGLEV_IP\",/g" $CONF 
	sed -i -e "s/\"port\".*22.*/\"port\":\"$SSH_PORT\"/g" $CONF 
}

function install_jar() {
	mvn install:install-file -Dfile=$1  -DgroupId=$2 -DartifactId=$3 -Dversion=$4 -Dpackaging=jar -DgeneratePom=true
}
function mag_build() {
	mag_mvn clean install $*
}

function mag_mvn() {
	mvn -P build-maglev,-build-grapevine,opendaylight-snapshots -s $MAG_SETTINGS $*
}
function mag_plugin_build() {
	mag_build -Dbuild.skip.app.assembly.steps=false $*
}

function api_build() {
	API_DIR=$1
	MVN_OPTS="${@:2}"
	cd "$API_DIR" && mvn clean install $MVN_OPTS&& cd -
}

function mag_api_build() {
	API_DIR=$1
	MVN_OPTS="${@:2}"
	exec_at $API_DIR mag_mvn clean install $MVN_OPTS
}


function maglevup() {
    IP=${1:-$MAGLEV_IP}
	set_mag_ip $IP
	maglev_ssh $IP
}
function maglev_ssh() {
	add_sp $MAGLEV_PASS ssh $SSH_OPTS -o StrictHostKeyChecking=no $MAGLEV_USER@$1 "${@:2}"
}

function maglev_scp() {
	UPLOAD_DIR=${2:-"/tmp"}
	info_log "Uploading $1 to $MAGLEV_IP:$UPLOAD_DIR"
	mag_scp_exec "$1" ${MAGLEV_USER}@${MAGLEV_IP}:${UPLOAD_DIR}
}


function mag_scp_exec() {
	add_sp ${MAGLEV_PASS} scp -o StrictHostKeyChecking=no $SCP_OPTS $*
}

function get_mag_file() {
 	mag_scp_exec $SCP_OPTS ${MAGLEV_USER}@${MAGLEV_IP}:${1} "$2"
}

function get_service_file() {
	mag_exec magctl service cp "${1}:${2}" .
	get_mag_file $2
}


function mag_attach_jprofiler() {
	TMP_DIR="/tmp"	
	SERVICE_NAME="$1"
	JPROFILER_TAR_NAME="jprofiler.tar.gz"
	JSCRIPT_PATH="jprofiler_init.sh"
	JPROFILER_PORT="12345"
	JPROFILER_VERSION=${3:-"10.1.1"}
	JPROFILER_TAR_PATH=${2:-"$HOME/Downloads/jprofiler_linux_10_1_1.tar.gz"}
	info_log "Attaching jprofiler version $JPROFILER_VERSION from $JPROFILER_TAR_PATH to the service $SERVICE_NAME on $MAGLEV_IP"
	rm -rf $JSCRIPT_PATH
	echo "#!/bin/bash -e" > $JSCRIPT_PATH
	echo "magctl service cp '$TMP_DIR/$JPROFILER_TAR_NAME' $SERVICE_NAME:$JPROFILER_TAR_NAME" >> $JSCRIPT_PATH
	echo "magctl service exec $SERVICE_NAME 'tar -xvzf $JPROFILER_TAR_NAME'" >> $JSCRIPT_PATH
	echo "magctl service exec $SERVICE_NAME './jprofiler$JPROFILER_VERSION/bin/jpenable --port=$JPROFILER_PORT --gui'" >> $JSCRIPT_PATH
	exec maglev_scp $JSCRIPT_PATH
	exec maglev_scp $JPROFILER_TAR_PATH $TMP_DIR/$JPROFILER_TAR_NAME
	exec magexec "chmod +x $TMP_DIR/$JSCRIPT_PATH"
	magexec -tt "cd $TMP_DIR;./$JSCRIPT_PATH"
	magexec magctl service unexpose $SERVICE_NAME $JPROFILER_PORT
	magexec magctl service expose $SERVICE_NAME $JPROFILER_PORT

}

function mag_sudo_scp() {
	SOURCE=$1
	FILENAME=$(basename $SOURCE)
	DESTINATION=$2
	maglev_scp $1
	mag_sudo_exec mv /tmp/$FILENAME $DESTINATION
	echo
}

function mag_sudo_exec() {
	magexec "echo ${MAGLEV_PASS} | sudo -S $*"
}

function magexec() {
	info_log "Executing $* on $MAGLEV_IP"
	maglev_ssh $MAGLEV_IP $*
}

function maglev_patcher_exec() {
	mag_sudo_exec /opt/maglev/bin/patcher --username $MAGLEV_UI_USER --password $MAGLEV_UI_PASS $*
}


function mag_plugin_jar_deploy() {
	mag_plugin_build
	TAR_BALL_PATH=$(find . -iname "*.tar.gz")
	info_log "TAR BALL PATH IS: ${TAR_BALL_PATH}"

}

function mag_get_rmq_pwd() {
 	magexec -tt magctl service exec rabbitmq "cat vault/rabbitmq-appuser; echo " 2>/dev/null
 }


function mag_named_query_deploy() {
	PLUGIN_DIR="/data/maglev/srv/maglev-system/glusterfs/mnt/bricks/default_brick/fusion/plugin_catalog/model"
	FILENAME=$(basename $1)
	MAG_USER="root"
	info_log "Uploading $FILENAME to ${PLUGIN_DIR}/$2"
	mag_sudo_scp $1 ${PLUGIN_DIR}/$2
	info_log "Enabling execution permissions on ${PLUGIN_DIR}/$2/$FILENAME"
	mag_sudo_exec chmod +x ${PLUGIN_DIR}/$2/$FILENAME
	info_log "Changing file owner and group permissions to $MAG_USER"
	mag_sudo_exec chown ${MAG_USER}:${MAG_USER} ${PLUGIN_DIR}/$2/$FILENAME
}

function set_mag_ip() {
	set_var MAGLEV_IP "$1"
	info_log "Set MAGLEV_IP to $MAGLEV_IP"
}

function uniqApiGen() {
	uniq generate api-client -c $MAGLEV_IP -u $MAGLEV_UI_USER -p $MAGLEV_UI_PASS -s $1 --maglev
}

function get_basic_auth() {
	USER=$1
	PWD=$2
	BASE64CRED=$(printf "$USER:$PWD" | base64)
	echo "Authorization: Basic $BASE64CRED"
}

function get_mag_token() {
	BASIC_AUTH_HEADER=$(get_basic_auth $MAGLEV_UI_USER $MAGLEV_UI_PASS)
	JSON_TOKEN=$(curl --silent -k https://$MAGLEV_IP/api/system/v1/auth/token -X POST -H "$BASIC_AUTH_HEADER")
	echo $JSON_TOKEN | python3 -c "import sys, json; print(json.load(sys.stdin)['Token'])"
}

################################################################################
# Perforce Commands
################################################################################

function p4s() {
	p4 submit -c $P4CHANGEVERSION
}

function p4c() {
	echo "P4CHANGEVERSION=$1" > ~/.p4info
	export P4CHANGEVERSION=$1
}

function p4revert() {
	p4 revert -c $P4CHANGEVERSION
}

function p4stats() {
	p4 diff | grep ===
}

function p4change() {
	p4c $(P4EDITOR="" p4 change | grep -o '[0-9]\+')
}
function p4add() {
	p4 edit $1
	p4 reopen -c $P4CHANGEVERSION $1
}

function p4update(){
	p4 change -u $P4CHANGEVERSION
}

function backup() {
	mv ~/.ssh/id_rsa ~/.ssh/id_rsa.bak
}

function restore() {
	mv ~/.ssh/id_rsa.bak ~/.ssh/id_rsa
}

function set_ssh_port() {
	set_var SSH_PORT $1
	set_var SSH_OPTS "-p $SSH_PORT"
	set_var SCP_OPTS "-P $SSH_PORT"
}

function get_times() {
	grep -r "$1" "$2" | wc -l 
	grep -r "$1" "$2" | head -n 1
	grep -r "$1" "$2" | tail -n 1
}

function log_service() {
	magexec magctl service logs -rf $1 > $2
}

# Setting PATH for Python 3.6
# The original version is saved in .bash_profile.pysave
if [ -f ~/.git-completion.bash ]; then
	  . ~/.git-completion.bash
fi
[ -f $HOME/.p4info ] && source $HOME/.p4info
[ -f $HOME/.cli ] && source $HOME/.cli
[ -f $HOME/.workspace ] && source $HOME/.workspace
PATH="/Library/Frameworks/Python.framework/Versions/3.6/bin:${PATH}"
export PATH=$PATH:/Users/aukao/apache-maven-3.5.0/bin
export P4PORT=ise-p4-sjc.cisco.com:1666
export P4USER=aukao
export P4CLIENT=aukao
export P4EDITOR=vim
export CEC_USER=aukao
export NVM_DIR="$HOME/.nvm"
export MAGLEV_PASS=Maglev123
export MAGLEV_USER=maglev
export MAGLEV_UI_USER=admin
export MAGLEV_UI_PASS=Maglev123
export DEP_PATH="$WORKSPACE/jars/sxp-parent/sxp-dyn;$WORKSPACE/jars/sxp-parent/sxp-common;$WORKSPACE/jars/sxp-parent/sxp-engine-facade;$WORKSPACE/jars/common-service-api;$WORKSPACE/jars/sxp-parent/aca-sxp-api"
export AUTOMATION_TEST_DIR="$WORKSPACE/automation/aca/tests/api_test/test_sxp_binding_mgr"
export AUTO_TEST_CONFIG="$WORKSPACE/automation/aca/config/local.json"
#export MAGLEV_IP="172.23.109.32"
export MAGLEV_IP="172.23.118.83"
export SSH_PORT="2222"
export SSH_OPTS="-p $SSH_PORT"
export SCP_OPTS="-P $SSH_PORT"
export SXP_HOME="/Users/aukao/Workspaces/DNA_SDK_maglev/ACA_Demo/sxp"
alias totoro="while true; do echo Totoro is cool; done"
alias ww="echo \"$WORKSPACE\" && cd \"$WORKSPACE\""
#setShellPrompt
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Setting PATH for Python 3.6
# The original version is saved in .bash_profile.pysave
PATH="/Library/Frameworks/Python.framework/Versions/3.6/bin:${PATH}"
export PATH
