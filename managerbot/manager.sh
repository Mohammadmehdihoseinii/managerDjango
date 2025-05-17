#!/bin/bash

# --------------------------
# Configuration Variables
# --------------------------
APP_TITLE="Project Manager"
DEFAULT_PATHS=(
    "./mplaner/settings.py"
    "./src/mplaner/settings.py"
    "./project/settings.py"
    "./settings.py"
)
APPS_DIR="./apps"
CONFIG_DIR="./config"
DB_BACKUP_DIR="./db_backups"
CONFIG_FILE="$CONFIG_DIR/.installer_config"
VENV_CHECK=0

# --------------------------
# Initial Setup
# --------------------------
function initialize_directories() {
    mkdir -p "$CONFIG_DIR" "$APPS_DIR" "$DB_BACKUP_DIR" || error_exit "Failed to create directories!"
}

# Create config file if missing
initialize_directories
if [ ! -f "$CONFIG_FILE" ]; then
    cat <<EOF > "$CONFIG_FILE"
APP_TITLE="$APP_TITLE"
DEFAULT_PATHS=(
    "${DEFAULT_PATHS[@]}"
)
APPS_DIR="$APPS_DIR"
VENV_CHECK=0
EOF
    echo "Config file created with default values: $CONFIG_FILE"
fi

# Load user config
source "$CONFIG_FILE"

# --------------------------
# Helper Functions
# --------------------------
function show_header() {
    clear
    echo "═══════════════════════════════════════"
    echo "          $APP_TITLE"
    echo "═══════════════════════════════════════"
    echo "📁 System Directories:"
    echo " - Config: $CONFIG_DIR"
    echo " - Apps: $APPS_DIR"
    echo " - DB Backups: $DB_BACKUP_DIR"
    echo "═══════════════════════════════════════"
}

function error_exit() {
    echo "❌ Error: $1"
    exit 1
}

function validate_path() {
    local path=$1
    if [ ! -d "$path" ]; then
        mkdir -p "$path" || error_exit "Failed to create directory: $path!"
        echo "✅ Directory created: $path"
    fi
}

# --------------------------
# Virtualenv Functions
# --------------------------
function activate_venv() {
    if [ $VENV_CHECK -eq 0 ]; then
        venv_paths=("./venv" "./.venv")
        for path in "${venv_paths[@]}"; do
            if [ -f "$path/bin/activate" ]; then
                source "$path/bin/activate"
                VENV_CHECK=1
                echo "✅ Virtual environment activated: $path"
                return 0
            fi
        done
        error_exit "Virtual environment not found! Use option 1 to create one."
        return 1
    fi
}

function manage_venv() {
    while true; do
        echo "═════ Virtual Environment Management ═════"
        echo "1) Create Virtual Environment"
        echo "2) Activate Virtual Environment"
        echo "3) Deactivate"
        echo "4) Delete Virtual Environment"
        echo "5) Return to Main Menu"
        read -p "Choose an option: " choice

        case $choice in
            1)
                read -p "Virtual env path [default: ./venv]: " venv_path
                venv_path=${venv_path:-./venv}
                python3 -m venv "$venv_path" || error_exit "Failed to create virtual environment!"
                echo "✅ Virtual environment created: $venv_path"
                ;;
            2)
                read -p "Virtual env path [default: ./venv]: " venv_path
                venv_path=${venv_path:-./venv}
                if [ -f "$venv_path/bin/activate" ]; then
                    source "$venv_path/bin/activate"
                    VENV_CHECK=1
                    echo "✅ Virtual environment activated!"
                else
                    error_exit "Virtual environment not found at $venv_path!"
                fi
                ;;
            3)
                if [[ "$VIRTUAL_ENV" != "" ]]; then
                    deactivate
                    VENV_CHECK=0
                    echo "✅ Virtual environment deactivated!"
                else
                    echo "⚠️ No active virtual environment!"
                fi
                ;;
            4)
                read -p "Virtual env path to delete [default: ./venv]: " venv_path
                venv_path=${venv_path:-./venv}
                rm -rf "$venv_path" || error_exit "Failed to delete virtual environment!"
                echo "✅ Virtual environment deleted: $venv_path"
                ;;
            5) break ;;
            *) echo "⚠️ Invalid choice!" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

# --------------------------
# Dependency Management
# --------------------------
function install_dependencies() {
    activate_venv || error_exit "Failed to activate virtual environment!"
    if [ ! -f "requirements.txt" ]; then
        error_exit "requirements.txt not found in current directory!"
    fi
    echo "📦 Installing dependencies from requirements.txt..."
    pip install -r requirements.txt || error_exit "Failed to install dependencies!"
}

# --------------------------
# Database Operations
# --------------------------
function db_operations() {
    activate_venv || error_exit "Failed to activate virtual environment!"
    PS3="Choose a database operation: "
    select operation in "Backup" "Restore" "Reset"; do
        case $operation in
            "Backup")
                backup_name="db_backup_$(date +%Y%m%d%H%M).json"
                python manage.py dumpdata --indent 2 > "$DB_BACKUP_DIR/$backup_name" || error_exit "Backup failed!"
                echo "✅ Backup saved at $DB_BACKUP_DIR/$backup_name"
                ;;
            "Restore")
                select backup in "$DB_BACKUP_DIR"/*; do
                    [ -z "$backup" ] && error_exit "No backup selected!"
                    python manage.py loaddata "$backup" || error_exit "Restore failed!"
                    break
                done
                ;;
            "Reset")
                python manage.py flush --no-input || error_exit "Database reset failed!"
                echo "✅ Database reset successfully!"
                ;;
            *) error_exit "Invalid operation!" ;;
        esac
        break
    done
}

# --------------------------
# Application Management
# --------------------------
function smart_find_settings() {
    read -p "Search directory [default: $PWD]: " search_dir
    search_dir=${search_dir:-$PWD}
    found_settings=($(find "$search_dir" -name "settings.py" 2>/dev/null))

    if [ ${#found_settings[@]} -eq 0 ]; then
        echo "⚠️ settings.py not found!"
        return 1
    elif [ ${#found_settings[@]} -eq 1 ]; then
        echo "${found_settings[0]}"
    else
        echo "🔍 Multiple settings.py files found:"
        select path in "${found_settings[@]}"; do
            [ -n "$path" ] && echo "$path" && break
        done
    fi
}

function create_app_with_template() {
    # یافتن مسیر settings.py
    settings_file=$(smart_find_settings) || return 1
    read -p "New app name: " app_name
    validate_path "$APPS_DIR/$app_name" || error_exit "Failed to create app directory!"

    # ایجاد اپلیکیشن
    activate_venv || error_exit "Failed to activate virtual environment!"
    python manage.py startapp "$app_name" "$APPS_DIR/$app_name" || error_exit "Failed to create app!"

    # ایجاد ساختار تمپلیت
    mkdir -p "$APPS_DIR/$app_name/templates/$app_name"
    touch "$APPS_DIR/$app_name/templates/$app_name/base.html"

    # افزودن اپ به INSTALLED_APPS
    app_config="$APPS_DIR.$app_name.apps.${app_name^}Config"
    if ! grep -q "$app_config" "$settings_file"; then
        sed -i "/INSTALLED_APPS\s*=\s*\[/a \ \ \ \ '$app_config'," "$settings_file" && \
        echo "✅ App '$app_name' added to INSTALLED_APPS in $settings_file"
    else
        echo "⚠️ App '$app_name' already exists in INSTALLED_APPS!"
    fi

    echo "✅ App '$app_name' created successfully!"
}

# --------------------------
# Help Menu
# --------------------------
function show_help() {
    show_header
    echo """
📘 Script Guide:
1) Virtual Environment Management: Create/Activate/Delete virtual environments
2) Dependency Management: Install packages from requirements.txt
3) Database Operations: 
   - Backup: Create JSON backup of database
   - Restore: Load data from a backup file
   - Reset: Wipe all database data (irreversible!)
4) Create New App: Generate Django app with template structure
5) Run Dev Server: Start Django development server
6) Project Settings: Edit config file ($CONFIG_FILE)
7) Help: Show this guide
8) Exit: Quit the script

Hot Tips:
- Always activate a virtual environment before installing dependencies
- Backup your database before major changes
- Store app-specific templates in 'apps/<app_name>/templates/'
"""
    read -p "Press Enter to continue..."
}

# --------------------------
# Main Menu
# --------------------------
function show_main_menu() {
    while true; do
        show_header
        PS3="Choose an option: "
        select option in \
            "Virtual Environment Management" \
            "Dependency Management" \
            "Database Operations" \
            "Create New App" \
            "Run Development Server" \
            "Project Settings" \
            "Help" \
            "Exit"; do
            case $option in
                "Virtual Environment Management") manage_venv ;;
                "Dependency Management") install_dependencies ;;
                "Database Operations") db_operations ;;
                "Create New App") create_app_with_template ;;
                "Run Development Server")
                    activate_venv
                    python manage.py runserver || error_exit "Failed to start development server!"
                    ;;
                "Project Settings") nano "$CONFIG_FILE" ;;
                "Help") show_help ;;
                "Exit") exit 0 ;;
                *) echo "⚠️ Invalid option!" ;;
            esac
            break
        done
        read -p "Press Enter to continue..."
    done
}

# --------------------------
# Execution
# --------------------------
show_main_menu
