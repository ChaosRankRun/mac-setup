#!/bin/bash

#/ Usage: setup.sh [--debug]

# TODO
#	1. git user name and email	
#	2. setup logstash

set -e

HOME_DIR="$(cd ~ && pwd)"
SETUP_DIR="$(cd "$(dirname "$0")" && pwd)"

install_aws () {
	local AWS_DIR="${HOME_DIR}/.aws"
	local AWS_CRED_FILE="${AWS_DIR}/credentials"
	local AWS_CONFIG_FILE="${AWS_DIR}/config"

	echo "--> Setting up AWS credentials"
	mkdir -p "${HOME_DIR}/.aws"
	
	if [ -f "${AWS_CONFIG_FILE}" ]; then
		echo "==> AWS config file exists. Skipping"
	else
		cp "${SETUP_DIR}/aws/aws-config.template" "${AWS_CONFIG_FILE}"
	fi

	if [ -f "${AWS_CRED_FILE}" ]; then
		echo "==> AWS credential file exists. Skipping"
	else
		cp "${SETUP_DIR}/aws/aws-credentials.template" "${AWS_CRED_FILE}"
	fi
	
	echo "--> Finished setting up AWS credentials"
}

configure_ssh () {
	local SSH_DIR="${HOME_DIR}/.ssh"

	echo "--> Configuring ssh"
	mkdir -p "${SSH_DIR}"	

	if [ -f "${SSH_DIR}/id_rsa" ]; then
		echo "==> ssh key exists"
	else
		ssh-keygen -t rsa -b 4096 -N '' -f "${SSH_DIR}/id_rsa"
	fi
	
	echo "--> Finished configuring ssh"
}

configure_defaults () {
	echo "--> set mac defaults"

	defaults write com.apple.screensaver askForPasswordDelay -int 0
}

enable_filevault () {
	echo "--> checking filevault"
	if ! fdesetup status | grep -q -E "FileVault is (On|Off, but will be enabled after the next restart)."; then
		echo "==> enabling filevault"
		sudo fdesetup enable -user $USER | tee ~/Desktop/"filevault_recovery_key.txt"
	fi
}

run_homebrew () {
	local HOMEBREW="$(BREW --prefix 2>/dev/null || echo "/usr/local")"
	local HOMBREW_REPO="$(brew --repository 2>/dev/null || true)"

	if ! type brew &> /dev/null; then
		echo "--> Installing Homebrew:"
		/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	fi

	echo "--> update brew"
	brew update
	
	echo "--> intalling brew taps"
	brew bundle --file="${SETUP_DIR}/homebrew/Brewfile.taps" 

	echo "--> installing brewfile"
	brew bundle --file="${SETUP_DIR}/homebrew/Brewfile"
}

copy_dot_files () {
	echo "copying vimrc and bash_profile from ${SETUP_DIR}"
	cp "${SETUP_DIR}/vim/vimrc" "${HOME_DIR}/.vimrc"
	cp "${SETUP_DIR}/bash/bash_profile" "${HOME_DIR}/.bash_profile"
}


install_pip () {
    echo "--> checking pip"
    if ! type "pip" &> /dev/null; then
        echo "--> install pip"
        sudo easy_install pip
    fi
}

install_vundle () {
    echo "--> checking vundle"
    if [ ! -d ~/.vim/bundle/Vundle.vim ]; then
        echo "--> installing vundle"
        git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
        vim +PluginInstall +qall
    fi
}

install_xcode () {
    echo "--> software update for mac"
    softwareupdate -ia

    echo "--> checking xcode"
    XCODE_DIR=$("xcode-select" -print-path 2>/dev/null || true)
    if [ -z $XCODE_DIR ]; then
        echo "--> install xcode"
        xcode-select --install
    fi
}

install_awscli () {
    echo "--> checking awscli"
    if ! type "aws" &> /dev/null; then
        echo "--> install awscli"
        pip install awscli==1.11
    fi
}

install_s3cmd () {
    echo "--> checking s3cmd"
    if ! type "s3cmd" &> /dev/null; then
        echo "--> install s3cmd"
        pip install s3cmd==2.0
    fi
}

setup () {
	if [ "$USER" = "root" ]; then
		echo "==> failed user"
		exit 1
	fi

	install_aws
	configure_ssh
	configure_defaults
	enable_filevault
	run_homebrew
	copy_dot_files
    install_vundle
    install_xcode
    install_pip
    install_awscli
    install_s3cmd

	echo "--> System is set up"	
}

setup
