#! /bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
function createdata(){
  function createtext() {
    if [ -f "/$DIR/DB_MDjango/DB_MDjango.py" ] 
    then
      echo "File not found!"
    else
      echo "app = MDjango v1" > /$DIR/DB_MDjango/DB_MDjango.py
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


function Main() {
  echo "--------------- Menu App ---------------"
  createdata
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
    Main
  fi
fi
