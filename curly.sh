#!/bin/bash
###
# Author : Shakiba Moshiri
###

################################################################################
# an associative array for storing color and a function for colorizing
################################################################################
declare -A _colors_;
_colors_[ 'red' ]='\x1b[1;31m';
_colors_[ 'green' ]='\x1b[1;32m';
_colors_[ 'yellow' ]='\x1b[1;33m';
_colors_[ 'cyan' ]='\x1b[1;36m';
_colors_[ 'reset' ]='\x1b[0m';

function colorize(){
    if [[ ${_colors_[ $1 ]} ]]; then
        echo -e "${_colors_[ $1 ]}$2${_colors_[ 'reset' ]}";
    else
        echo 'wrong color name!';
    fi
}

################################################################################
# __help function
################################################################################
function __help(){
    echo -e  " $0 help ...\n
definition:
 doing things in a 'curl' way ...

arguments:
 -F | --ftp             FTP actions ...
    |                   $(colorize 'cyan' 'check'): checking FTP connection
    |                   $(colorize 'cyan' 'mount'): mount over FTP
    |                   $(colorize 'cyan' 'umount'): umount: umount FTP mount point
    |                   $(colorize 'cyan' 'upload'): upload: upload to a FTP account
    |                   $(colorize 'cyan' 'download'): download: download from a FTP account
    | --fc              ftp configuration file
    | --fmp             ftp mount point (local machine)
    | --fl              ftp local file for upload
    | --fr              ftp remote path

 -S | --ssl             SSL actions ...
    |                   $(colorize 'cyan' 'valid'): checking if SSL of a domain is valid
    |                   $(colorize 'cyan' 'date'): check start and end date of the certificate
    |                   $(colorize 'cyan' 'cert'): show the certificate
    |                   $(colorize 'cyan' 'name'): name of domains the certificate issued for
    |                   $(colorize 'cyan' 'issue_dv'): issue Domain Validation cert
    |                   $(colorize 'cyan' 'issue_wc'): issue Wild Card cert

 -H | --http            HTTP actions ....
    |                   $(colorize 'cyan' 'response'): print response header of server
    |                   $(colorize 'cyan' 'redirect'): check if redirect id done or not
    |                   $(colorize 'cyan' 'status'): print status for the GET request
    |                   $(colorize 'cyan' 'ttfb'): print statistics about Time to First Byte
    |                   $(colorize 'cyan' 'gzip'): check if gzip is enabled or not
                        
 -D | --dns             DNS actions ...
    |                   $(colorize 'cyan' 'root'): check on root DNS servers
    |                   $(colorize 'cyan' 'public'): check on public DNS servers e.g 1.1.1.1
    |                   $(colorize 'cyan' 'trace'): trace from a public DNS server to main server
    | --dc              dns servers to use, default is: 1.1.1.1
    |                   or a file containing some DNS servers ( IPs | names )

 -I | --ip              IP actions ...
    |                   $(colorize 'cyan' 'info'): any info based on shodan dB
    |                   $(colorize 'cyan' 'port'): quick check open ports
    |                   $(colorize 'cyan' 'route'): trace route
    | --ia              ip address e.g. : 1.1.1.1
    | --im              maximum number of hops
    | --ic              set the number of pings sent

 -E | --email           Email actions ...
    |                   $(colorize 'cyan' 'send'): send an email
    | --ec              email configuration file for sending an email
    | --eb              email body (= contents) of the email that is send

 -C | --command         Command actions ...
    |                   $(colorize 'cyan' 'check'): check prerequisite for run curly
    |                   $(colorize 'cyan' 'install'): install all prerequisite

 -h | --help            print this help
 -d | --domain          name of a domain, e.g. example.com

Copyright (C) 2020 Shakiba Moshiri
https://github.com/k-five/curly "
    exit 0;
}

################################################################################
# __debug function
################################################################################
function __debug(){
    echo '######### DEBUG ##########';
    echo "conf file $_conf_path_";
    echo "ftp ${FTP['action']}";
    echo "mount point ${FTP['mount_point']}";
    echo
    echo
    echo -e "1. $_user_domain_ \n2. $_user_name_ \n3. $_user_pass_";
}

################################################################################
# print the result of each action
################################################################################
function print_result(){
    echo -e "\noption: $2" >&2;
    echo "action:" $(colorize 'cyan'  $3) >&2;
    if [[ $1 == 0 ]]; then
        echo "status:" $(colorize 'green' 'OK') >&2;
    else
        echo "status:" $(colorize 'red' 'ERROR') >&2;
    fi
}

################################################################################
# check for required commands
# curl, curlftpfs
# grep, sed
# nmap, perl
################################################################################
function command_check () {
    declare -a _cmds_;
    _cmds_=(curl curlftpfs perl nmap openssl certbot dig grep sed shodan mtr echo);
    return_code=0;

    for cmd in ${_cmds_[@]}; do
        temp_var=$(which  $cmd > /dev/null 2>&1);
        if [[ $? != 0 ]]; then
            printf "%-20s %s" "$cmd~" "~" | tr ' ~' '. ';
            printf "[ $(colorize 'red' 'ERROR') ] not found\n";
            if [[ $cmd == 'shodan' ]]; then
                echo '>  Please install shodan manually: https://cli.shodan.io/';
            fi
            return_code=1;
        else
            printf "%-20s %s" "$cmd~" "~" | tr ' ~' '. ';
            printf "[ $(colorize 'green' 'OK') ]\n";

        fi
    done
    return $return_code;
}

################################################################################
# if there is no flags, prints help
################################################################################
if [[ $1 == "" ]]; then
    __help;
fi


################################################################################
# main flags, both longs and shorts
################################################################################
ARGS=`getopt -o "hc:F:S:H:D:I:E:m:l:r:d:" -l "help,fc:,ftp:,ssl:,http:,dns:,ip:,ia:,im:,ic:,dc:,email:,command:,ec:,eb:,fmp:,fl:,fr:,domain:" -- "$@"`
eval set -- "$ARGS"

################################################################################
# global variable 
################################################################################
_conf_path_="";

declare -a _conf_file_;

# variables for FTP
declare -A FTP;
FTP['flag']=0;
FTP['action']='';
FTP['conf_path']='';
FTP['local_file']='';
FTP['mount_point']='';
FTP['remote_path']='';

# variables for SSL
declare -A ssl;
declare -A ssl_action;
ssl['flag']=0;
ssl['action']='';
ssl['domain']='';

# variables for HTTP
declare -A http;
http['flag']=0;
http['action']='';
http['domain']='';

declare -A dns;
dns['flag']=0;
dns['action']='';
dns['domain']='';
dns['server']='1.1.1.1';

declare -A ip;
ip['flag']=0;
ip['action']='';
ip['count']=10;
ip['address']='';
ip['max_hop']=0;

declare -A email;
email['flag']=0;
email['conf']='';
email['body']='';
email['user']='';
email['pass']='';
email['smtp']='';
email['port']='';
email['rcpt']='';

declare -A command;
command['flag']=0;
command['action']='';

################################################################################
# parse configuration file and assigns values to variables
################################################################################
function check_conf_path(){
    # check if the file exist and it is readable
    if ! [[ -r ${FTP['conf_path']} ]]; then
        echo "$(colorize 'red' 'ERROR' ) ...";
        echo "file: $_conf_path_ does NOT exist!";
        exit 1;
    elif ! [[ -s ${FTP['conf_path']} ]]; then
        echo "$(colorize 'yellow' 'WARNING' ) ...";
        echo "file: $_conf_path_ is empty!";
        exit 0;
    fi

    _conf_file_=($(cat ${FTP['conf_path']}));
    # check if length of the array is 3
    if [[ ${#_conf_file_[@]} != 3 ]]; then
        echo "$(colorize 'yellow' 'WARNING') ...";
        echo "conf file format is NOT valid or some lines are missed!";
        echo -e "\nRight format ...";
        echo "example.com  # should be a domain name or an IP address";
        echo "username     # should be the username";
        echo "12345        # should be the password for that username";
        exit 2;
    fi

    _user_domain_=${_conf_file_[0]};
    _user_name_=${_conf_file_[1]};
    _user_pass_=${_conf_file_[2]};

}

################################################################################
# reading configuration for an email
################################################################################
function email_read_conf(){
    if ! [[ -r ${email['conf']} ]]; then
        echo "$(colorize 'red' 'ERROR' ) ...";
        echo "file: ${email['conf']}  does NOT exist!";
        exit 1;
    elif ! [[ -s ${email['conf']} ]]; then
        echo "$(colorize 'yellow' 'WARNING' ) ...";
        echo "file: ${email['conf']} is empty!";
        exit 0;
    fi

    temp_var=($(cat ${email['conf']}));
    # check if length of the array is 3
    if [[ ${#temp_var[@]} != 5 ]]; then
        echo "$(colorize 'yellow' 'WARNING') ...";
        echo "conf file format is NOT valid or some lines are missed!";
        echo -e "\nRight format ...";
        exit 2;
    fi
    
    email['user']=${temp_var[0]};
    email['pass']=${temp_var[1]};
    email['smtp']=${temp_var[2]};
    email['port']=${temp_var[3]};
    email['rcpt']=${temp_var[4]};
}

################################################################################
# extract options and their arguments into variables.
################################################################################
while true ; do
    case "$1" in
        -h | --help )
            __help;
        ;;
        
        # configure file
        --fc )
            FTP['conf_path']=$2;
            check_conf_path
            shift 2;
        ;;
        
        # --ftp
        -F | --ftp )
            FTP['flag']=1;
            FTP['action']=$2;
            case "$2" in
                check )
                ;;

                mount )
                ;;

                umount )
                ;;

                upload )
                ;;

                download )
                ;;
            esac
            shift 2;
        ;;

        -S | --ssl )
            ssl['flag']=1;
            ssl['action']=$2;
            case $2 in
                valid )
                ;;

                date )
                ;;
            esac
            shift 2;
        ;;

        -H | --http )
            http['flag']=1;
            http['action']=$2;
            shift 2;
        ;;

        -D | --dns )
            dns['flag']=1;
            dns['action']=$2;
            shift 2;
        ;;
        --dc )
            dns['server']=$2;
            shift 2;
        ;;

        -I | --ip )
            ip['flag']=1;
            ip['action']=$2;
            shift 2;
        ;;
        --ia )
            ip['address']=$2;
            shift 2;
        ;;
        --im )
            ip['max_hop']=$2;
            shift 2;
        ;;
        --ic )
            ip['count']=$2;
            shift 2;
        ;;

        -E | --email )
            email['flag']=1;
            email['action']=$2;
            shift 2;
        ;;

        --ec )
            email['conf']=$2;
            email_read_conf;
            shift 2;
        ;;

        --eb )
            email['body']=$2;
            shift 2;
        ;;

        # command
        -C | --command )
            command['flag']=1;
            command['action']=$2;
            shift 2;
        ;;


        # ftp mount point
        --fmp )
            FTP['mount_point']=$2;

            # check if the directory exist
            if ! [[ -d ${FTP['mount_point']} ]]; then
                echo "$(colorize 'yellow' 'WARNING' ) ...";
                echo  "${FTP['mount_point']} directory does NOT exist";
                read -p "Do you want to create it? ( yes | no ) " _mount_point_creation_;
                case $_mount_point_creation_ in
                    y | yes )
                        echo "trying to create $_mount_point_creation_";
                    ;;
                    n | no )
                        echo "program exited because there is not directory to be mounted";
                        exit 1;
                    ;;
                    * )
                        echo "A mount point is required!";
                        exit 1;
                    ;;
                esac
            fi
            shift 2;
        ;;

        ## FTP local file
        --fl )
            FTP['local_file']=$2
            shift 2;
        ;;

        # FTP remote path
        --fr )
            FTP['remote_path']=$2;
            shift 2;
        ;;

        -d | --domain )
           ssl['domain']=$2;
           http['domain']=$2;
           dns['domain']=$2;
           shift 2;
        ;;

        # last line
         --)
            shift;
            break;
         ;;

         *) echo "Internal error!" ; exit 1 ;;
    esac
done



################################################################################
# check and run FTP actions
################################################################################
if [[ ${FTP['flag']} == 1 ]]; then
    if [[ ${FTP['conf_path']} == '' && ${FTP['action']} != 'umount' ]]; then
        echo "$(colorize 'red' 'ERROR') ...";
        echo "The configuration file is required with ${FTP['action']} action.";
        echo "Use '--fc' and give it a path to configuration file name.";
        exit 2;
    fi

    case ${FTP['action']} in 
        check )
            curl --insecure --user "${_user_name_}:${_user_pass_}" ftp://${_user_domain_}/${FTP['remote_path']}/;
            print_result $? 'ftp' 'check';
        ;;

        mount )
           if [[ ${FTP['mount_point']} == '' ]]; then
                echo "$(colorize 'yellow' 'WARNING' ) ...";
                echo "With 'mount' ftp a 'mount point' is required.";
                echo "Use '--fmp' with a path.";
                exit 2;
            fi

            curlftpfs "${_user_name_}:${_user_pass_}@${_user_domain_}" ${FTP['mount_point']}
            print_result $? 'ftp' 'mount';
        ;;

        umount )
            if [[ ${FTP['mount_point']} == '' ]]; then
                echo "$(colorize 'yellow' 'WARNING' ) ...";
                echo "With 'umount' ftp a 'mount point' is required.";
                echo "Use '--fmp' with a path.";
                exit 2;
            fi

            sudo umount ${FTP['mount_point']}
            print_result $? 'ftp' 'umount';
        ;;

        upload )
            if [[ $flag_local_file == 0 ]]; then
                echo "$(colorize 'yellow' 'WARNING') ...";
                echo "A file is required with 'upload' action";
                echo "use '--fl' and give it a single file name";
                exit 2;
            fi

            curl  --insecure --user "${_user_name_}:${_user_pass_}" ftp://${_user_domain_}/${FTP['remote_path']}/ -T "${FTP['local_file']}";
            print_result $? 'ftp' 'upload';
        ;;

        download )
            if [[ ${FTP['remote_path']} == '' ]]; then
                echo "$(colorize 'red' 'ERROR') ...";
                echo "Absolute path to the remote file is required!.";
                echo "Use '--fr' with a given file name.'.";
                exit 2;
            fi

            curl --insecure --user "${_user_name_}:${_user_pass_}" ftp://${_user_domain_}/${FTP['remote_path']};
            print_result $? 'ftp' 'download';
        ;;

        * )
            echo "$(colorize 'yellow' 'WARNING') ...";
            echo "Action ${FTP['action']} is not supported";
            echo "Use '-h' or '--help' to see the available action for ftp.";
            exit 1;
        ;;
    esac
fi

################################################################################
# check and run SSL actions
################################################################################
if [[ ${ssl['flag']} == 1 ]]; then
    if [[ ${ssl['domain']} == '' ]]; then
        echo "$(colorize 'red' 'ERROR') ...";
        echo "A domain name is required!.";
        echo "Use '-d' or '--domain' with a given name.";
        exit 2;
    fi

    case ${ssl['action']} in
        valid )
            echo | openssl s_client -showcerts -connect ${ssl['domain']}:443 |& grep -i 'return code' | sed 's/^ \+//g'
            echo | openssl s_client -servername ${ssl['domain']}  -connect ${ssl['domain']}:443 2>/dev/null | openssl x509 -noout -issuer -subject | sed 's/, /\n/g'
            print_result $? 'ssl' 'valid';
        ;;

        date )
            ssl_start=$(echo | openssl s_client -servername ${ssl['domain']} -connect ${ssl['domain']}:443 2>/dev/null | openssl x509 -noout -startdate | sed 's/.\+=//')
            ssl_end=$(echo | openssl s_client -servername ${ssl['domain']}  -connect ${ssl['domain']}:443 2>/dev/null | openssl x509 -noout -enddate | sed 's/.\+=//')

            ssl_start_sec=$(date -u --date="$ssl_start" "+%s");
            ssl_end_sec=$(date -u --date="$ssl_end" "+%s");

            today_sec=$(date "+%s");
            one_day=$(( 24 * 60 * 60 ));

            days_passed=$(( $(( $today_sec - $ssl_start_sec  )) / $one_day ));
            days_left=$(( $(( $ssl_end_sec -  $today_sec  )) / $one_day ));
            days_total=$(( $days_passed + $days_left ));

            echo | openssl s_client -showcerts -connect ${ssl['domain']}:443 |& grep -i 'return code' | sed 's/^ \+//g'
            echo -n 'from: ';
            date -u --date="$ssl_start"
            echo -n 'till: ';
            date -u --date="$ssl_end"
            echo "days total:  $days_total";
            echo "days passed: $days_passed";
            echo "days left:   $days_left";

            print_result $? 'ssl' 'date';
        ;;

        cert )
            command_output=$(nmap --script ssl-cert -v1  -p 443 ${ssl['domain']} | sed 's/|[ _]//g' | perl -lne '$/=null; /-----BEGIN.*CERTIFICATE-----/sg && print $&');
            if [[ $? != 0 ]]; then
                echo "${ssl['domain']} does not have a valid certificate.";
                exit 0;
            fi
            echo "$command_output";
            print_result $? 'ssl' 'cert';
        ;;

        name )
            command_output=$(nmap --script ssl-cert -v1  -p 443 ${ssl['domain']} | sed 's/|[ _]//g' | perl -lne '$/=null; /-----BEGIN.*CERTIFICATE-----/sg && print $&');
            echo "$command_output" | openssl x509  -text -noout  | grep DNS | tr ',' '\n' | sed 's/^ \+DNS://g'
            if [[ $? != 0 ]]; then
                echo "${ssl['domain']} does not have a valid certificate.";
                exit 0;
            fi
            print_result $? 'ssl' 'name';
        ;;

        issue_dv )
            if [[ ${FTP['mount_point']} == '' ]]; then
                echo "$(colorize 'yellow' 'WARNING' ) ...";
                echo "With ${ssl['action']} ssl a 'mount point' is required.";
                echo "Use '--fmp' with a path.";
                exit 2;
            fi
            certbot certonly --server https://acme-v02.api.letsencrypt.org/directory --agree-tos --webroot -w ${FTP['mount_point']} -d ${ssl['domain']} -d www.${ssl['domain']};
        ;;

        issue_wc )
            certbot certonly --server https://acme-v02.api.letsencrypt.org/directory --agree-tos --manual --preferred-challenges dns -d ${ssl['domain']} -d *.${ssl['domain']};
        ;;

        * )
            echo "$(colorize 'yellow' 'WARNING') ...";
            echo "Action ${ssl['action']} is not supported";
            echo "Use '-h' or '--help' to see the available action for ssl.";
            exit 1;
        ;;
    esac
fi

################################################################################
# check and run http actions
################################################################################
if [[ ${http['flag']} == 1 ]]; then
    if [[ ${http['domain']} == '' ]]; then
        echo "$(colorize 'red' 'ERROR') ...";
        echo "A domain name is required!.";
        echo "Use '-d' or '--domain with a given name'.";
        exit 2;
    fi

    case ${http['action']} in
        res | respon | response )
            curl -LI ${http['domain']}
            print_result $? 'http' 'response';
        ;;

        st | stat | status )
            curl -sLo /dev/null -w \
'URL               %{url_effective}
status            %{http_code}
remote_ip         %{remote_ip}
remote_port       %{remote_port}
num_connects      %{num_connects}
num_redirects     %{num_redirects}
scheme            %{scheme}
http_version      %{http_version}
ssl_verify_result %{ssl_verify_result}
' ${http['domain']};
            print_result $? 'http' 'status';
        ;;

        red | redir | redirect )
            curl -LI ${http['domain']} 2>&1 | grep  -e HTTP -e [lL]ocation
            print_result $? 'http' 'redirect';
        ;;

        gz | gzip )
            curl -sLH 'Accept-Encoding: gzip' ${http['domain']} -o /tmp/curl.gz;
            gzip -l /tmp/curl.gz
            if [[ $? == 0 ]]; then
                echo 'gzip is enabled';
            else
                echo 'gzip is NOT enabled';
            fi
            print_result $? 'http' 'gzip';
        ;;

        tt | tt | ttfb )
            printf "%-20s" "date";
            date '+%F at %T';
            curl -sLo /dev/null -w \
'url_effective       %{url_effective}
time_namelookupe    %{time_namelookup} | DNS lookup
time_connect        %{time_connect} | TCP connection
time_appconnect     %{time_appconnect} | App connection
time_redirect       %{time_redirect} | Redirection time
time_starttransfer  %{time_starttransfer} | TTFB
time_total          %{time_total}
' ${http['domain']};
            print_result $? 'http' 'ttfb';
        ;;

        * )
            echo "$(colorize 'yellow' 'WARNING') ...";
            echo "Action ${http['action']} is not supported";
            echo "Use '-h' or '--help' to see the available action for ssl.";
            exit 1;
        ;;
    esac
fi

if [[ ${dns['flag']} == 1 ]]; then
    if [[ ${dns['domain']} == '' ]]; then
        echo "$(colorize 'red' 'ERROR') ...";
        echo "A domain name is required!.";
        echo "Use '-d' or '--domain with a given name'.";
        exit 2;
    fi

    case ${dns['action']} in
        ro | root )
            TLD=$(egrep -o '[^\.]+$' <<< ${dns['domain']});
            while read server; do
                echo $(colorize 'cyan' "DNS server $server");
                dig +nocmd +nocomments +nostats ANY ${dns['domain']} @${server};
                if [[ $? == 0 ]]; then
                    break;
                fi
            done < <(whois $TLD | grep -i nserver | perl -alne 'print $F[1]');
            print_result $? 'dns' 'root';
        ;;

        pub | public )
            # if it is a file
            if [[ -r ${dns['server']} ]]; then
                if ! [[ -s ${dns['server']} ]]; then
                    echo "$(colorize 'yellow' 'WARNING' ) ...";
                    echo "file: ${dns['server']} is empty!";
                    echo 'falling back to default: 1.1.1.1';
                    exit 2;
                fi
                # xargs -I xxx dig ${dns['domain']} ANY @xxx < ${dns['server']};
                while read server; do
                    echo $(colorize 'cyan' "DNS server $server");
                    dig +nocmd +nocomments +nostats AnY ${dns['domain']} @${server};
                    if [[ $? == 0 ]]; then
                        break;
                    fi
                done < ${dns['server']}
            # if it is NOT a file
            else
                echo $(colorize 'cyan' "DNS server ${dns['server']}");
                dig +nocmd +nocomments +nostats A ${dns['domain']} @${dns['server']};
            fi
            print_result $? 'dns' 'public';
        ;;

        tra | trace )
            dig +trace ${dns['domain']} @${dns['server']};
            print_result $? 'dns' 'trace';
        ;;

        * )
            echo "$(colorize 'yellow' 'WARNING') ...";
            echo "Action ${dns['action']} is not supported";
            echo "Use '-h' or '--help' to see the available action for dns.";
            exit 1;
        ;;

    esac
    
fi

if [[ ${ip['flag']} == 1 ]]; then
    if [[ ${ip['address']} == '' ]]; then
        echo "$(colorize 'red' 'ERROR') ...";
        echo "An ip address is required";
        echo "Use '--ia' and provide it an address";
        exit 2;
    fi
    case ${ip['action']} in
        info )
            shodan host ${ip['address']};
            print_result $? 'ip' 'info';
        ;;

        port )
            sudo nmap --open -Pn -sS -F ${ip['address']};
            print_result $? 'ip' 'port';
        ;;

        route )
            if [[ ${ip['max_hop']} == 0 ]]; then
                mtr --report-wide --report --report-cycles ${ip['count']} --show-ips ${ip['address']};
            else
                mtr --report-wide --report --report-cycles ${ip['count']} --show-ips --max-ttl ${ip['max_hop']} ${ip['address']};
            fi
            print_result $? 'ip' 'route';
        ;;

        * )
            echo "$(colorize 'yellow' 'WARNING') ...";
            echo "Action ${ip['action']} is not supported";
            echo "Use '-h' or '--help' to see the available action for --ip";
            exit 1;
        ;;
    esac
fi

if [[ ${command['flag']} == 1 ]]; then
    case ${command['action']} in
        check )
            command_check;
            print_result $? 'command' 'check';
        ;;

        install )
            os_release=$(perl -lne '/(centos|ubuntu|debian|arch)/i; $os=$&; END{print lc($os)}' /etc/*-release);
            read -p "Is your OS $(colorize 'green' $os_release)? [ y / n ]: " os_confirm;
            if [[ $os_confirm != 'y' ]]; then
               echo "detected os: $os_release";
               echo "noting done";
               exit 0;
            fi
            centos_install=$(curl curlftpfs perl nmap openssl certbot grep sed mtr echo);
            debian_install=$(curl curlftpfs perl nmap openssl certbot grep sed mtr echo);
            ubuntu_install=$(curl curlftpfs perl nmap openssl certbot grep sed mtr echo);
            arch_install=$(curl curlftpfs perl nmap openssl certbot grep sed mtr echo);
            case $os_release in
                centos )
                    sudo yum -y update;
                    sudo yum -y install net-tools;
                    sudo yum -y install bind-utils;
                    sudo yum -y install ${centos_install[@]};
                ;;

                debian )
                    sudo apt-get -y update;
                    sudo apt-get -y install net-tools;
                    sudo apt-get -y install dnsutils;
                    sudo apt-get -y install ${debian_install[@]};
                ;;

                ubuntu )
                    sudo apt-get -y update;
                    sudo apt-get -y install net-tools;
                    sudo apt-get -y install dnsutils;
                    sudo apt-get -y install ${ubuntu_install[@]};
                ;;

                arch )
                    sudo pacman -Sy update;
                    sudo pacman -Sy net-tools;
                    sudo pacman -Sy dnsutils;
                    sudo pacman -Sy install ${arch_install[@]};
                ;;

                * )
                    echo 'A not supported os';
                ;;
            esac
        ;;
    esac
fi


if [[ ${email['flag']} == 1 ]]; then
    if [[ ${email['conf']} == '' ]]; then
        echo "$(colorize 'red' 'ERROR') ...";
        echo "A configuration file is required for sending an email.";
        echo "Use '--ec' and provide it file name";
        exit 2;
    fi

    if [[ ${email['body']} == '' ]]; then
        echo "$(colorize 'yellow' 'WARNING') ...";
        echo 'body of the email is not provided!';
        echo "'Hi there!' will be used a fall back";
        email['body']='Hi there!';
    else
        if [[ -r ${email['body']} ]]; then
            if ! [[ -s ${email['body']} ]]; then
                echo "$(colorize 'yellow' 'WARNING' ) ...";
                echo "file: ${email['body']} is empty!";
                echo "'Hi there!' will be used a fall back";
                email['body']='Hi there!';
            else
                email['body']=$(cat ${email['body']});
            fi
        fi
    fi

    case ${email['action']} in
        send )
email_content='From: "Curly Script by Shakiba Moshiri" <'"${email['user']}"'>
To: "Gmail" <'"${email['rcpt']}"'>
Subject: from '"${email['user']}"' to Gamil
Date: '"$(date)"'

'"${email['body']}"' ';

            echo "$email_content" | curl -s \
                --url "smtp://${email['smtp']}:${email['port']}" \
                --user "${email['user']}:${email['pass']}" \
                --mail-from "${email['user']}" \
                --mail-rcpt "${email['rcpt']}" \
                --upload-file - # email.txt
            
            print_result $? 'email' 'send';
        ;;
    esac
fi
