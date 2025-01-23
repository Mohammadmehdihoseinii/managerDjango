#! /bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
requirementsFile=/$DIR/DB_MDjango/requirements.txt
# var in app
declare -A Apps=(
	[0]=UserApp
	)

Username_Django=Username
password_Django=password
Email_Django=Email@gmail.com
name_db=namedb
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
    echo "" > $requirementsFile
  }
  function installrequirements(){
    managerVenv
    #update pip
    python -m pip install --upgrade pip
    pip install --upgrade --force-reinstall -r $requirementsFile
  }
  function backuprequirements(){
    pip3 freeze > $requirementsFile || pip freeze > $requirementsFile  
  }
  while true 
		do
			echo "--------------- manager requirements ---------------"
      echo "1- buld requirements"
      echo "2- install requirements"
      echo "3- backup requirements"
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
function django(){
  function installdjango(){
    python -m pip install Django
    echo 'Django\n' >> $requirementsFile
    buldingdjango
  }
  function buldingdjango(){
    read -p "name site:" name
    django-admin startproject $name 
  }
  function Createapp(){
    read -p "name app:" nameapp
    python ./manage.py startapp $nameapp 
  }
  function createsuperuser(){
    echo "create super user ..."
    echo "from django.contrib.auth import get_user_model;User=get_user_model();Adminiser=User.objects.create_superuser('$Username_Django', '$Email_Django', '$password_Django');" | python manage.py shell
  }

  managerVenv
  while true 
		do
			echo "--------------- manager Django ---------------"
      echo "1- install Django"
      echo "2- bulding Django"
      echo "3- create app Django"
      echo "4- create super user"
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
						installdjango
          elif [ $Selectmenu == 2 ]; then
						buldingdjango || installdjango
          elif [ $Selectmenu == 3 ]; then
						Createapp || buldingdjango
          elif [ $Selectmenu == 4 ]; then
            createsuperuser || buldingdjango
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

function Database(){
  function installpostgresDatabase(){
    echo "install postgres-17 Database"
    sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/F-41-x86_64/pgdg-fedora-repo-latest.noarch.rpm
    sudo dnf install -y postgresql17-server
    sudo /usr/pgsql-17/bin/postgresql-17-setup initdb
    sudo systemctl enable postgresql-17
    sudo systemctl start postgresql-17
  }
  function CreateupdateDatabase(){
    echo "Create/update Database"

    for key in "${!Apps[@]}"
      do
      python ./manage.py makemigrations ${Apps[$key]}
    done
    for key in "${!Apps[@]}"
      do
      python ./manage.py migrate ${Apps[$key]}
    done
    python ./manage.py makemigrations
    python ./manage.py migrate
  }
  function resetDatabase(){
    removeFolderDatabase
    echo "rest Database ..."
    sudo -u postgres psql -c "drop database IF EXISTS '$name_db'"
    sudo -u postgres psql -c "CREATE DATABASE '$name_db'"

    CreateupdateDatabase
    createsuperuser
  }
  function removeFolderDatabase(){
    echo "Remobve migrations and __pycache__ folder"

    for key in "${!Apps[@]}"
      do
      if [ -d "./${Apps[$key]}/migrations" ] ; then
        sudo rm -r ./${Apps[$key]}/migrations
      else
        echo "App ${Apps[$key]} Not migrations"
      fi
      if [ -d "./${Apps[$key]}/__pycache__" ] ; then
        sudo rm -r ./${Apps[$key]}/__pycache__
      else
        echo "App ${Apps[$key]} Not __pycache__"
      fi
    done
  }
  function createsuperuser(){
    echo "create super user ..."
    echo "from django.contrib.auth import get_user_model;User=get_user_model();Adminiser=User.objects.create_superuser('$Username_Django', '$Email_Django', '$password_Django');" | python manage.py shell
  }

  managerVenv
  while true 
		do
			echo "--------------- manager Database ---------------"
      echo "1- install Database"
      echo "2- Create/update Database"
      echo "3- reset Database"
      echo "4- create super user"
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
						installpostgresDatabase
          elif [ $Selectmenu == 2 ]; then
						CreateupdateDatabase
          elif [ $Selectmenu == 3 ]; then
						resetDatabase
          elif [ $Selectmenu == 4 ]; then
            createsuperuser
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
      echo "3- manager django"
      echo "4- manager Database"
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
          elif [ $Selectmenu == 3 ]; then
						django
          elif [ $Selectmenu == 4 ]; then
						Database
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
