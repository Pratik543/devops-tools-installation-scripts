#!/bin/bash

#=============================#
#   SCP Interactive Script    #
#=============================#

#---------------------------------------------------------#
#   CONFIGURATION: Hardcode your values below             #
#   Leave empty ("") to be prompted interactively         #
#---------------------------------------------------------#

# PEM Key - Hardcoded path
HARDCODED_PEM_KEY="C:\Users\Pratik\Desktop\admin.pem"
#HARDCODED_PEM_KEY=""

# Source File/Directory - Hardcoded path
HARDCODED_SOURCE="C:\Users\Pratik\Desktop\devops-tool-installation-script\tools.sh"
#HARDCODED_SOURCE=""

# Destination Path - Hardcoded path (overrides /home/$USER default)
#HARDCODED_DESTINATION=""

#---------------------------------------------------------#
#   END OF CONFIGURATION                                  #
#---------------------------------------------------------#

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Separator line
separator() {
    echo -e "${CYAN}=============================================${NC}"
}

# ============================================
# FUNCTION: Generic Hardcoded/Interactive Menu
# Usage: select_path "LABEL" "HARDCODED_VALUE" "VALIDATE_TYPE"
#   VALIDATE_TYPE: "file" | "dir" | "any" | "none"
#     file = must exist as file
#     dir  = must exist as directory
#     any  = must exist (file or dir)
#     none = no validation (remote path)
# Returns value via global variable: SELECTED_PATH
# ============================================
select_path() {
    local LABEL="$1"
    local HARDCODED="$2"
    local VALIDATE="$3"

    SELECTED_PATH=""

    # --- Case 1: Hardcoded is set and valid ---
    if [[ -n "$HARDCODED" ]]; then

        local hardcoded_valid=false

        case "$VALIDATE" in
            file)
                [[ -f "$HARDCODED" ]] && hardcoded_valid=true
                ;;
            dir)
                [[ -d "$HARDCODED" ]] && hardcoded_valid=true
                ;;
            any)
                [[ -e "$HARDCODED" ]] && hardcoded_valid=true
                ;;
            none)
                # No local validation needed (e.g., remote path)
                hardcoded_valid=true
                ;;
        esac

        if $hardcoded_valid; then
            echo -e "  ${GREEN}Hardcoded ${LABEL} found:${NC} ${BOLD}${HARDCODED}${NC}"
            echo ""
            echo "  1) Use hardcoded: ${HARDCODED}"
            echo "  2) Enter a different path"
            echo ""

            while true; do
                read -rp "$(echo -e "${BOLD}Enter your choice [1 or 2]: ${NC}")" path_choice
                case $path_choice in
                    1)
                        SELECTED_PATH="$HARDCODED"
                        echo -e "${GREEN}✔ Using hardcoded ${LABEL}: ${BOLD}${SELECTED_PATH}${NC}"
                        return 0
                        ;;
                    2)
                        break
                        ;;
                    *)
                        echo -e "${RED}Invalid choice. Please enter 1 or 2.${NC}"
                        ;;
                esac
            done
        else
            echo -e "${RED}⚠ Hardcoded ${LABEL} NOT valid: ${HARDCODED}${NC}"
            echo -e "${YELLOW}Falling back to interactive input...${NC}"
            echo ""
        fi
    else
        echo -e "${YELLOW}No hardcoded ${LABEL} configured. Enter path manually.${NC}"
        echo ""
    fi

    # --- Interactive input ---
    while true; do
        read -rp "$(echo -e "${BOLD}Enter ${LABEL} path: ${NC}")" input_path
        input_path="${input_path/#\~/$HOME}"

        case "$VALIDATE" in
            file)
                if [[ -f "$input_path" ]]; then
                    SELECTED_PATH="$input_path"
                    echo -e "${GREEN}✔ ${LABEL} found: ${BOLD}${SELECTED_PATH}${NC}"
                    return 0
                else
                    echo -e "${RED}✘ File not found: '${input_path}'. Try again.${NC}"
                fi
                ;;
            dir)
                if [[ -d "$input_path" ]]; then
                    SELECTED_PATH="$input_path"
                    echo -e "${GREEN}✔ ${LABEL} found: ${BOLD}${SELECTED_PATH}${NC}"
                    return 0
                else
                    echo -e "${RED}✘ Directory not found: '${input_path}'. Try again.${NC}"
                fi
                ;;
            any)
                if [[ -e "$input_path" ]]; then
                    SELECTED_PATH="$input_path"
                    echo -e "${GREEN}✔ ${LABEL} found: ${BOLD}${SELECTED_PATH}${NC}"
                    return 0
                else
                    echo -e "${RED}✘ Path not found: '${input_path}'. Try again.${NC}"
                fi
                ;;
            none)
                if [[ -n "$input_path" ]]; then
                    SELECTED_PATH="$input_path"
                    echo -e "${GREEN}✔ ${LABEL} set to: ${BOLD}${SELECTED_PATH}${NC}"
                    return 0
                else
                    echo -e "${RED}✘ Path cannot be empty. Try again.${NC}"
                fi
                ;;
        esac
    done
}

# ============================================
# MAIN SCRIPT STARTS HERE
# ============================================

# Banner
clear
separator
echo -e "${BOLD}${GREEN}       SCP FILE TRANSFER TOOL${NC}"
separator
echo ""

# ---- Display current configuration ----
echo -e "${BOLD}${CYAN}Current Hardcoded Configuration:${NC}"
echo -e "  PEM Key     : ${HARDCODED_PEM_KEY:-${RED}(not set)${NC}}"
echo -e "  Source       : ${HARDCODED_SOURCE:-${RED}(not set)${NC}}"
echo -e "  Destination  : ${HARDCODED_DESTINATION:-${RED}(not set)${NC}}"
echo ""

#--- Step 1: Select User ---#
separator
echo -e "${YELLOW}[Step 1]${NC} Select the remote user:"
echo ""
echo "  1) ubuntu"
echo "  2) ec2-user"
echo ""

while true; do
    read -rp "$(echo -e "${BOLD}Enter your choice [1 or 2]: ${NC}")" user_choice
    case $user_choice in
        1)
            USER="ubuntu"
            break
            ;;
        2)
            USER="ec2-user"
            break
            ;;
        *)
            echo -e "${RED}Invalid choice. Please enter 1 or 2.${NC}"
            ;;
    esac
done

echo -e "${GREEN}✔ User selected: ${BOLD}${USER}${NC}"
echo ""

#--- Step 2: PEM Key Selection ---#
separator
echo -e "${YELLOW}[Step 2]${NC} PEM Key Configuration:"
echo ""

select_path "PEM Key" "$HARDCODED_PEM_KEY" "file"
PEM_KEY="$SELECTED_PATH"
echo ""

#--- Step 3: Source File/Directory ---#
separator
echo -e "${YELLOW}[Step 3]${NC} Source File/Directory:"
echo ""

select_path "Source" "$HARDCODED_SOURCE" "any"
SOURCE_PATH="$SELECTED_PATH"
echo ""

#--- Step 4: Destination Path ---#
separator
echo -e "${YELLOW}[Step 4]${NC} Remote Destination Path:"
echo ""

# If no hardcoded destination, set default to /home/$USER/
if [[ -z "$HARDCODED_DESTINATION" ]]; then
    DEFAULT_DEST="/home/${USER}/"
    echo -e "  ${CYAN}Default destination: ${BOLD}${DEFAULT_DEST}${NC}"
    echo ""
    echo "  1) Use default: ${DEFAULT_DEST}"
    echo "  2) Enter a custom destination path"
    echo ""

    while true; do
        read -rp "$(echo -e "${BOLD}Enter your choice [1 or 2]: ${NC}")" dest_choice
        case $dest_choice in
            1)
                DEST_PATH="$DEFAULT_DEST"
                echo -e "${GREEN}✔ Using default destination: ${BOLD}${DEST_PATH}${NC}"
                break
                ;;
            2)
                while true; do
                    read -rp "$(echo -e "${BOLD}Enter destination path: ${NC}")" custom_dest
                    if [[ -n "$custom_dest" ]]; then
                        DEST_PATH="$custom_dest"
                        echo -e "${GREEN}✔ Destination set to: ${BOLD}${DEST_PATH}${NC}"
                        break
                    else
                        echo -e "${RED}✘ Path cannot be empty. Try again.${NC}"
                    fi
                done
                break
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 1 or 2.${NC}"
                ;;
        esac
    done
else
    select_path "Destination" "$HARDCODED_DESTINATION" "none"
    DEST_PATH="$SELECTED_PATH"
fi
echo ""

#--- Step 5: Recursive flag check ---#
SCP_FLAGS="-i ${PEM_KEY}"
if [[ -d "$SOURCE_PATH" ]]; then
    echo -e "${YELLOW}⚠ Source is a directory. Adding '-r' flag automatically.${NC}"
    SCP_FLAGS="-r -i ${PEM_KEY}"
    echo ""
fi

#--- Step 6: Enter IP Addresses ---#
separator
echo -e "${YELLOW}[Step 5]${NC} Enter target IP addresses:"
echo -e "  ${CYAN}(Enter one IP per line. Type ${BOLD}'done'${NC}${CYAN} when finished)${NC}"
echo ""

IP_LIST=()
while true; do
    read -rp "$(echo -e "${BOLD}IP Address: ${NC}")" ip_input

    if [[ "${ip_input,,}" == "done" ]]; then
        if [[ ${#IP_LIST[@]} -eq 0 ]]; then
            echo -e "${RED}✘ You must enter at least one IP address.${NC}"
            continue
        fi
        break
    fi

    if [[ $ip_input =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IP_LIST+=("$ip_input")
        echo -e "${GREEN}  ✔ Added: ${ip_input}${NC}"
    else
        echo -e "${RED}  ✘ Invalid IP format: '${ip_input}'. Try again.${NC}"
    fi
done
echo ""

#--- Step 7: Summary & Confirmation ---#
separator
echo -e "${BOLD}${YELLOW}               TRANSFER SUMMARY${NC}"
separator
echo -e "  ${BOLD}User        :${NC} ${USER}"
echo -e "  ${BOLD}PEM Key     :${NC} ${PEM_KEY}"
echo -e "  ${BOLD}Source      :${NC} ${SOURCE_PATH}"
echo -e "  ${BOLD}Destination :${NC} ${DEST_PATH}"
echo -e "  ${BOLD}SCP Flags   :${NC} ${SCP_FLAGS}"
echo -e "  ${BOLD}Targets     :${NC}"
for ip in "${IP_LIST[@]}"; do
    echo -e "               - ${ip}"
done
separator
echo ""

read -rp "$(echo -e "${BOLD}Proceed with transfer? [y/N]: ${NC}")" confirm
if [[ "${confirm,,}" != "y" ]]; then
    echo -e "${RED}Transfer cancelled by user.${NC}"
    exit 0
fi
echo ""

#--- Step 8: Execute SCP ---#
separator
echo -e "${BOLD}${GREEN}       STARTING TRANSFERS...${NC}"
separator
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_IPS=()

for ip in "${IP_LIST[@]}"; do
    echo -e "${CYAN}➤ Transferring to ${BOLD}${USER}@${ip}:${DEST_PATH}${NC}"

    scp -o StrictHostKeyChecking=no \
        -o ConnectTimeout=10 \
        ${SCP_FLAGS} \
        "${SOURCE_PATH}" \
        "${USER}@${ip}:${DEST_PATH}"

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}  ✔ SUCCESS: ${ip}${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}  ✘ FAILED:  ${ip}${NC}"
        ((FAIL_COUNT++))
        FAILED_IPS+=("$ip")
    fi
    echo ""
done

#--- Step 9: Final Report ---#
separator
echo -e "${BOLD}${YELLOW}            TRANSFER REPORT${NC}"
separator
echo -e "  ${GREEN}Successful : ${SUCCESS_COUNT}${NC}"
echo -e "  ${RED}Failed     : ${FAIL_COUNT}${NC}"

if [[ ${#FAILED_IPS[@]} -gt 0 ]]; then
    echo -e "  ${RED}Failed IPs :${NC}"
    for fip in "${FAILED_IPS[@]}"; do
        echo -e "               ${RED}- ${fip}${NC}"
    done
fi
separator
echo ""
echo -e "${GREEN}Done!${NC}"
exit 0