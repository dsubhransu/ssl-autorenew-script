#!/bin/bash

domain=$1

#./certbot-auto renew --register-unsafely-without-email --nginx -d $domain -n

./certbot-auto certonly --register-unsafely-without-email --nginx -d $domain -n

./change.sh -d "$domain" -i "13.234.17.52" -p "81"

#./change.sh -d "$domain" -i "$host" -p "$port"
root@ip-172-31-47-204:/etc/letsencrypt# cat change.sh 
#!/bin/bash

while getopts ":d:i:p:" opt; do
  case $opt in
    d) domain="$OPTARG"
    ;;
    i) host="$OPTARG"
    ;;
    p) port="$OPTARG"    
    ;;
    \?) echo "Invalid option -$OPTARG" >&3
    ;;
  esac
done

#domain=$1
#host=$2
#port=$3
scheme="\$scheme"
http_host="\$http_host"
remote_addr="\$remote_addr"
proxy_add_x_forwarded_for="\$proxy_add_x_forwarded_for"
#uri=\return 301 https://$hostrequest_uri
block="/etc/nginx/conf.d/$domain.conf"

sudo tee $block > /dev/null <<EOF
upstream $domain {
        server $host:$port;
#        $uri;
        }
server {
        listen 80;
        server_name  $domain;

 location / {
    proxy_read_timeout      300;
    proxy_connect_timeout   300;
    proxy_redirect          off;
    proxy_set_header        X-Forwarded-Proto $scheme;
    proxy_set_header        Host              $http_host;
    proxy_set_header        X-Real-IP         $remote_addr;
    proxy_set_header        X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header        X-Frame-Options   SAMEORIGIN;
    proxy_pass              http://$domain;

 }
}
server {
        listen 443;
        server_name $domain;


        ssl on;
        ssl_certificate /etc/letsencrypt/live/$domain/cert.pem;
        ssl_certificate_key  /etc/letsencrypt/live/$domain/privkey.pem;

 location / {
    proxy_read_timeout      300;
    proxy_connect_timeout   300;
    proxy_redirect          off;
    client_max_body_size 2G;
    proxy_set_header        X-Forwarded-Proto $scheme;
    proxy_set_header        Host              $http_host;
    proxy_set_header        X-Real-IP         $remote_addr;
    proxy_set_header        X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header        X-Frame-Options   SAMEORIGIN;

    proxy_pass              http://$domain;
  }
}

EOF

sudo nginx -t && sudo service nginx reload
