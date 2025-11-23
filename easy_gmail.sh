#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display messages
error_msg() { echo -e "${RED}❌ $1${NC}"; }
success_msg() { echo -e "${GREEN}✅ $1${NC}"; }
info_msg() { echo -e "${BLUE}ℹ️  $1${NC}"; }
warning_msg() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Check Internet Connection
check_internet() {
    info_msg "Checking internet connection..."
    if ping -c 1 -W 1 google.com &> /dev/null || \
       curl -s --connect-timeout 5 https://www.google.com &> /dev/null; then
        success_msg "Internet connection: OK"
        return 0
    else
        error_msg "No internet connection"
        echo ""
        warning_msg "Please check:"
        echo "  • Mobile data/WiFi connection"
        echo "  • Airplane mode"
        echo "  • VPN settings"
        echo ""
        return 1
    fi
}

# Install Dependencies
install_dependencies() {
    info_msg "Checking dependencies..."
    
    # Check if running in Termux
    if [ -d "/data/data/com.termux/files/usr" ]; then
        info_msg "Termux environment detected"
        pkg update -y && pkg upgrade -y
        pkg install -y curl wget python jq
        pip install requests beautifulsoup4
    else
        # For other Linux systems
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y curl wget python3 python3-pip jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y curl wget python3 jq
        fi
        pip3 install requests beautifulsoup4
    fi
    success_msg "Dependencies installed successfully"
}

# Check Email Availability
check_email_availability() {
    local email=$1
    info_msg "Checking email availability: $email"
    
    # Simple availability check using Google signup
    local response=$(curl -s "https://accounts.google.com/signup/v1/lookup" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-raw "continue=https://mail.google.com/mail/&flowName=GlifWebSignIn&flowEntry=ServiceSignUp&email=$email" \
        --compressed 2>/dev/null)
    
    if echo "$response" | grep -q "EMAIL_EXISTS"; then
        error_msg "Email $email already exists"
        return 1
    else
        success_msg "Email $email is available!"
        return 0
    fi
}

# Generate Email Variations
generate_email_variations() {
    local first=$1 last=$2
    local emails=()
    
    # Convert to lowercase and clean
    first_clean=$(echo "$first" | tr 'A-Z' 'a-z' | sed 's/[^a-z]//g')
    last_clean=$(echo "$last" | tr 'A-Z' 'a-z' | sed 's/[^a-z]//g')
    
    # Different email formats
    emails+=("${first_clean}.${last_clean}@gmail.com")
    emails+=("${first_clean}${last_clean}@gmail.com")
    emails+=("${first_clean}_${last_clean}@gmail.com")
    emails+=("${first_clean}${last_clean:0:1}@gmail.com")
    emails+=("${first_clean:0:1}${last_clean}@gmail.com")
    emails+=("${first_clean}.${last_clean}$(date +%S)@gmail.com")
    
    printf '%s\n' "${emails[@]}"
}

# Create Account File
save_account() {
    local first=$1 last=$2 email=$3 pass=$4 dob=$5 gender=$6
    
    # Create accounts directory
    ACC_DIR="$HOME/gmail_accounts"
    mkdir -p "$ACC_DIR"
    
    # Create account file
    ACC_FILE="$ACC_DIR/account_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== Gmail Account Created ==="
        echo "Date      : $(date)"
        echo "First Name: $first"
        echo "Last Name : $last" 
        echo "Birth Date: $dob"
        echo "Gender    : $gender"
        echo "Email     : $email"
        echo "Password  : $pass"
        echo "Status    : READY FOR CREATION"
        echo "============================="
    } > "$ACC_FILE"
    
    echo "$ACC_FILE"
}

# Main Account Creation Function
create_gmail_account() {
    clear
    echo -e "${CYAN}"
    echo "==============================================="
    echo "        🚀 EASY GMAIL ACCOUNT CREATOR        "
    echo "==============================================="
    echo -e "${NC}"
    
    # Check internet
    if ! check_internet; then
        error_msg "Cannot continue without internet"
        exit 1
    fi
    
    # Install dependencies if needed
    read -p "Do you want to install dependencies? (y/n): " install_deps
    if [[ $install_deps == "y" || $install_deps == "Y" ]]; then
        install_dependencies
    fi
    
    echo ""
    info_msg "Please enter your details:"
    echo ""
    
    # Get user information
    read -p "Enter First Name: " FIRST
    read -p "Enter Last Name: " LAST
    read -p "Enter Birth Date (DD-MM-YYYY): " DOB
    read -p "Enter Gender (Male/Female): " GENDER
    
    # Password with confirmation
    while true; do
        echo ""
        read -s -p "Enter Password: " PASS
        echo
        read -s -p "Confirm Password: " PASS_CONFIRM
        echo
        
        if [[ "$PASS" != "$PASS_CONFIRM" ]]; then
            error_msg "Passwords do not match!"
            continue
        fi
        
        if [[ ${#PASS} -lt 8 ]]; then
            error_msg "Password must be at least 8 characters!"
            continue
        fi
        
        success_msg "Password strength: OK"
        break
    done
    
    echo ""
    info_msg "Generating email variations..."
    
    # Generate and check email variations
    available_emails=()
    while IFS= read -r email; do
        if check_email_availability "$email"; then
            available_emails+=("$email")
        fi
        sleep 1 # Avoid rate limiting
    done < <(generate_email_variations "$FIRST" "$LAST")
    
    # Display available emails
    if [[ ${#available_emails[@]} -eq 0 ]]; then
        error_msg "No available email addresses found!"
        warning_msg "Try different first/last names"
        exit 1
    fi
    
    echo ""
    success_msg "Available email addresses:"
    for i in "${!available_emails[@]}"; do
        echo "  $((i+1)). ${available_emails[i]}"
    done
    
    # Let user choose email
    echo ""
    read -p "Choose email (1-${#available_emails[@]}): " email_choice
    if [[ $email_choice -ge 1 && $email_choice -le ${#available_emails[@]} ]]; then
        SELECTED_EMAIL="${available_emails[$((email_choice-1))]}"
    else
        SELECTED_EMAIL="${available_emails[0]}"
    fi
    
    # Save account information
    ACC_FILE=$(save_account "$FIRST" "$LAST" "$SELECTED_EMAIL" "$PASS" "$DOB" "$GENDER")
    
    # Display results
    clear
    echo -e "${GREEN}"
    echo "==============================================="
    echo "        🎉 ACCOUNT READY FOR CREATION!        "
    echo "==============================================="
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}📧 Email    : ${GREEN}$SELECTED_EMAIL${NC}"
    echo -e "${CYAN}🔐 Password : ${GREEN}$PASS${NC}"
    echo -e "${CYAN}👤 Name     : ${GREEN}$FIRST $LAST${NC}"
    echo -e "${CYAN}🎂 Birth    : ${GREEN}$DOB${NC}"
    echo -e "${CYAN}⚧️  Gender   : ${GREEN}$GENDER${NC}"
    echo ""
    echo -e "${BLUE}===============================================${NC}"
    echo ""
    info_msg "To complete account creation:"
    echo "1. Go to: ${CYAN}https://accounts.google.com/signup${NC}"
    echo "2. Use the information above"
    echo "3. Complete verification steps"
    echo ""
    echo -e "${GREEN}✅ Account details saved: ${ACC_FILE}${NC}"
    echo ""
    
    # Ask to open browser if possible
    if command -v termux-open-url &> /dev/null; then
        read -p "Open signup page in browser? (y/n): " open_browser
        if [[ $open_browser == "y" || $open_browser == "Y" ]]; then
            termux-open-url "https://accounts.google.com/signup"
        fi
    fi
}

# Auto-run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_gmail_account
fi
