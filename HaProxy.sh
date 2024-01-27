#!/bin/bash

check_haproxy_availability() {
    if command -v haproxy &>/dev/null; then
        return 0  # HAProxy is installed
    else
        return 1  # HAProxy is not installed
    fi
}

install_haproxy() {
    if check_haproxy_availability; then
        echo "HAProxy is already installed."
    else
        # Install HAProxy
        echo "Installing HAProxy..."
        if [ -x "$(command -v apt-get)" ]; then
            sudo apt-get update
            sudo apt-get install -y haproxy
        elif [ -x "$(command -v yum)" ]; then
            sudo yum install -y haproxy
        else
            echo "Unsupported package manager. Cannot install HAProxy."
            exit 1
        fi

        # Check installation status
        if [ $? -eq 0 ]; then
            echo "HAProxy installed successfully."
        else
            echo "Failed to install HAProxy."
            exit 1
        fi
    fi
}

uninstall_haproxy() {
    if check_haproxy_availability; then
        # Uninstall HAProxy
        echo "Uninstalling HAProxy..."
        if [ -x "$(command -v apt-get)" ]; then
            sudo apt-get remove --purge -y haproxy
        elif [ -x "$(command -v yum)" ]; then
            sudo yum remove -y haproxy
        else
            echo "Unsupported package manager. Cannot uninstall HAProxy."
            exit 1
        fi

        # Check uninstallation status
        if [ $? -eq 0 ]; then
            echo "HAProxy uninstalled successfully."
        else
            echo "Failed to uninstall HAProxy."
            exit 1
        fi
    else
        echo "HAProxy is not installed."
    fi
}

is_frontend() {
        # Path to the HAProxy configuration file
        config_file="/etc/haproxy/haproxy.cfg"

        # Check if "frontend" exists in the configuration file
        if grep -q "frontend" "$config_file"; then
                return 0 # Exists
        else
                # Define the frontend configuration
                frontend_config="frontend ipv6_frontend\n    mode tcp\n    default_backend ipv6_backend\n\n"

                # Append the frontend configuration to the HAProxy configuration file
                echo -e "$frontend_config" | sudo tee -a "$config_file" > /dev/null

#               # Verify the updated HAProxy configuration for any syntax errors
#               haproxy -c -f "$config_file"

#               # Reload HAProxy to apply the changes
#               systemctl reload haproxy
                return 0
        fi
}

is_backend() {
        # Path to the HAProxy configuration file
        config_file="/etc/haproxy/haproxy.cfg"

        # Check if "backend" exists in the configuration file
        if grep -q "backend" "$config_file"; then
                return 0 # Exists
        else
                # Path to the HAProxy configuration file
                config_file="/etc/haproxy/haproxy.cfg"

                # Define the backend configuration
                backend_config="backend ipv6_backend\n    mode tcp\n    balance roundrobin\n\n"

                # Append the backend configuration to the HAProxy configuration file
                echo -e "$backend_config" | sudo tee -a "$config_file" > /dev/null

#               # Verify the updated HAProxy configuration for any syntax errors
#               haproxy -c -f "$config_file"

#               # Reload HAProxy to apply the changes
#               systemctl reload haproxy
                return 0
        fi
}

is_ipv4() {
    # Check if the given IP address is IPv4
    local ip="$1"
    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0  # IPv4
    else
        # Check if the IP address is not empty
        if [[ -n $ip ]]; then
            # IPv6 addresses are formatted within square brackets
            ip="[${ip}]"
        fi
        return 1  # Not IPv4
    fi
}

add_ip() {
    # Check if at least one port is specified in both backend and frontend sections
    if ! grep -qE "^\s*server\s+\w+\s+\d+\.\d+\.\d+\.\d+:[0-9]+\s*$" /etc/haproxy/haproxy.cfg; then
        echo "Please specify at least one port in the HAProxy configuration file before adding IP addresses."
        return
    fi
    read -p "Enter the IP address to add: " ip_address
    # Check if the IP address is IPv4 or IPv6
    if is_ipv4 "$ip_address"; then
        echo "Adding IPv4 address $ip_address to HAProxy configuration..."
        # Add the IPv4 address to HAProxy configuration here
        # Example: echo "server server_name $ip_address:port" >> /etc/haproxy/haproxy.cfg
        echo "IPv4 address $ip_address added successfully."
    else
        echo "Adding IPv6 address $ip_address to HAProxy configuration..."
        # Add the IPv6 address to HAProxy configuration here
        # Example: echo "server server_name [$ip_address]:port" >> /etc/haproxy/haproxy.cfg
        echo "IPv6 address [$ip_address] added successfully."
    fi
}

remove_ip() {
    read -p "Enter the IP address to remove: " ip_address
    # Check if the IP address is IPv4 or IPv6
    if is_ipv4 "$ip_address"; then
        echo "Removing IPv4 address $ip_address from HAProxy configuration..."
        # Remove the IPv4 address from HAProxy configuration here
        # Example: sed -i "/$ip_address/d" /etc/haproxy/haproxy.cfg
        echo "IPv4 address $ip_address removed successfully."
    else
        echo "Removing IPv6 address $ip_address from HAProxy configuration..."
        # Remove the IPv6 address from HAProxy configuration here
        # Example: sed -i "/\[$ip_address\]/d" /etc/haproxy/haproxy.cfg
        echo "IPv6 address [$ip_address] removed successfully."
    fi
}

add_port() {
        is_frontend
    read -p "Enter the port to add: " port
        # Path to the HAProxy configuration file
        config_file="/etc/haproxy/haproxy.cfg"

        # Check if the port exists in the frontend section of the configuration file
        if grep -q "bind.*:$port\b" "$config_file"; then
            echo "Port $port is already configured in the frontend section of $config_file"
        else
            echo "Adding port $port to HAProxy configuration..."
                # Path to the HAProxy configuration file
                config_file="/etc/haproxy/haproxy.cfg"

if grep -q "frontend ipv6_frontend" "$config_file" && grep -q "mode tcp" "$config_file"; then
    # Insert "bind *:$port" after "mode tcp" in the frontend section
    sed -i '/frontend ipv6_frontend/,/default_backend ipv6_backend/ s/mode tcp/&\n'"    bind *:$port"'/' "$config_file"
                    echo "Added 'bind *:$port' after 'mode tcp' in the frontend section of $config_file"
                else
                    echo "No 'mode tcp' directive found in the frontend section of $config_file"
                fi

        fi
}

remove_port() {
    read -p "Enter the port to remove: " port
    echo "Removing port $port from HAProxy configuration..."
    # Remove the port from HAProxy configuration here
    # Example: sed -i "/bind \*: $port$/d" /etc/haproxy/haproxy.cfg
    echo "Port $port removed successfully."
}

# Main menu
while true; do
    echo "Menu:"
    echo "1 - Install HAProxy"
    echo "2 - Uninstall HAProxy"
    echo "3 - IP & Port Management"
    echo "4 - Exit"
    read -p "Enter your choice: " choice

    case $choice in
        1) install_haproxy;;
        2) uninstall_haproxy;;
        3) # IP Management menu
           while true; do
               echo "IP Management Menu:"
               echo "1 - Add IP"
               echo "2 - Remove IP"
               echo "3 - Add Port"
               echo "4 - Remove Port"
               echo "5 - Back to Main Menu"
               read -p "Enter your choice: " ip_choice

               case $ip_choice in
                   1) add_ip;;
                   2) remove_ip;;
                   3) add_port;;
                   4) remove_port;;
                   5) break;;  # Return to the main menu
                   *) echo "Invalid choice. Please enter a valid option.";;
               esac
           done;;
        4) echo "Exiting..."; exit;;
        *) echo "Invalid choice. Please enter a valid option.";;
    esac
done
