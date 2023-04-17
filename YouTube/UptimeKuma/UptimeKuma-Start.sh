# Scripted form of docker run command
# save it to your sbin directory to run as needed

docker run -d --restart=always -p 3001:3001 -v /var/run/docker.sock:/var/run/docker.sock -v uptime-kuma:/app/data --name UptimeKuma louislam/uptime-kuma:1
