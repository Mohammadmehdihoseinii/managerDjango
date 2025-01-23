#! /bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#
Venv_chack=$false
function createdata(){
  function createtext() {
    if [ -f "/$DIR/DB_MDjango/DB_MDjango.py" ] 
    then
      echo "File not found!"
    else
      echo "app = 'MDjango v1'" > /$DIR/DB_MDjango/DB_MDjango.py
    fi
  }
  function createFolder() {
    #! echo "$DIR"
    if [ -d "/$DIR/DB_MDjango" ] 
    then
      echo "Directory DB_MDjango found"
    else
      mkdir -m 777 /$DIR/DB_MDjango
      createtext
    fi
  }
  createFolder
}

function managerVenv(){
  function activateVenv(){
    if [ $Venv_chack ]; then
        echo "activate Venv ..."
        source ./.venv/bin/activate
        Venv_chack=$true
    else
      echo "Venv is activate ..."
    fi
  }

  function installVenv(){
    echo "install venv ..."
    sudo dnf install python3-virtualenv
    buldVenv
  }
  function buldVenv(){
    if [ -d "/$DIR/env" ] 
    then
      echo "env found"
      activateVenv
    else
      echo "bulding venv ..."
      python3 -m venv env
      activateVenv
    fi
    
  }
  buldVenv || installVenv
}

function requirements(){
  function buldrequirements(){
    echo "" > /$DIR/DB_MDjango/requirements.txt
  }
  function installrequirements(){
    managerVenv
    #update pip
    python -m pip install --upgrade pip
    pip install --upgrade --force-reinstall -r /$DIR/DB_MDjango/requirements.txt
  }
  function backuprequirements(){
    pip3 freeze > /$DIR/DB_MDjango/requirements.txt || pip freeze > /$DIR/DB_MDjango/requirements.txt 
    
  }
  while true 
		do
			echo "--------------- Menu requirements ---------------"
      echo "1- buld requirements"
      echo "2- install requirements"
      echo "2- backup requirements"
      echo "b- back"

      read -p "select in menu: " Selectmenu
			clear
			#Checking if variable is empty
			if test -z "$Selectmenu"; then
				echo "\$ input is null. input => ($Selectmenu)"
			else
				if [[ $Selectmenu =~ ^[0-9]+$ ]]; then
					#echo "${Selectmenu} is a number"
					if [ $Selectmenu == 1 ]; then
						buldrequirements
          elif [ $Selectmenu == 2 ]; then
						installrequirements
          elif [ $Selectmenu == 3 ]; then
						backuprequirements
          fi
				else
					#echo "${NUM} is not a number"
					if [ "$Selectmenu" = "b" ] || [ "$Selectmenu" = "B" ]; then
						ret
					fi
				fi
      fi
  done  
  
}
function help(){
  echo "Test help app "
}
function Main() {
  while true 
		do
			echo "--------------- Menu App ---------------"
			echo "1- manager Venv"
      echo "2- manager requirements"
			echo "h - help"
			read -p "select in menu: " Selectmenu
			clear
			#Checking if variable is empty
			if test -z "$Selectmenu"; then
				echo "\$ input is null. input => ($Selectmenu)"
			else
				if [[ $Selectmenu =~ ^[0-9]+$ ]]; then
					#echo "${Selectmenu} is a number"
					if [ $Selectmenu == 1 ]; then
						managerVenv
          elif [ $Selectmenu == 2 ]; then
						requirements
          fi
				else
					#echo "${NUM} is not a number"
					if [ "$Selectmenu" = "h" ] || [ "$Selectmenu" = "h" ]; then
						break
					fi
				fi
			fi 
	# We can press Ctrl + C to exit the script
	done 
}
# run sudo app
if [ $EUID != 0 ]; then
  sudo "$0" "$@"
  exit 
else
  # Checking chmod file
  if [ ! +x $file ]; then
    me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
    echo "run command => chmod +x ./$me"
  else
    # run app
    createdata
    Main
  fi
fi
