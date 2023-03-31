GitLab is an open-source DevOps platform which provides Git repositories management, continuous integration, issue tracking, and other features. Self-managed GitLab can be installed on the own server.

This tutorial explains how to install GitLab Community Edition (CE) inside a Docker container in the Linux. Commands have been tested on Ubuntu.

Prepare environment
Make sure you have installed Docker in your system. If you are using Ubuntu, installation instructions can be found in the post.

## Install GitLab CE
### Host network
Run the following command to create a container for GitLab that uses host network:

```
docker run -d --name=gitlab --restart=always --network=host \
    -v /opt/gitlab/data:/var/opt/gitlab \
    -v /opt/gitlab/config:/etc/gitlab \
    -v /opt/gitlab/logs:/var/log/gitlab \
    gitlab/gitlab-ce
```
### User-defined bridge network
User-defined bridge network can be used for listening on different port. By default, GitLab web service is listening on port 80 and SSH service is listening on port 22. Both ports can be changed with -p option.
```
docker network create GitLab-Docker
```
```
docker run -d --name=gitlab --restart=always --network=GitLab-Docker \
    -p 7070:80 -p 8084:22 \
    -v /opt/gitlab/data:/var/opt/gitlab \
    -v /opt/gitlab/config:/etc/gitlab \
    -v /opt/gitlab/logs:/var/log/gitlab \
    gitlab/gitlab-ce
```
Note: it might take a while before initialization is finished and the Docker container starts to respond to requests.

## Testing GitLab CE
By default, a random password is generated during installation. The password can be found by running the following command:
```
docker exec -it gitlab cat /etc/gitlab/initial_root_password
```
Open a web browser and go to `http://<IP_ADDRESS>`, where <IP_ADDRESS> is the IP address of the system. Use root username and password from a file to log in to the dashboard.

## GitLab CE Inside Docker Container in Linux
Password can be changed in user settings page:
```
<GITLAB_URL>/-/profile/password/edit
```
## Uninstall GitLab CE
To completely remove GitLab, remove its container:
```
docker rm --force gitlab
```
Remove GitLab image:
```
docker rmi gitlab/gitlab-ce
```
You can also remove GitLab data, logs and configuration files:
```
sudo rm -rf /opt/gitlab
```
If a user-defined bridge network was created, you can delete it as follows:
```
docker network rm app-net
```
