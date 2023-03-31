  

  

## [](https://github.com/tubearchivist/tubearchivist#core-functionality)Core functionality

-   Subscribe to your favorite YouTube channels
-   Download Videos using **yt-dlp**
-   Index and make videos searchable
-   Play videos
-   Keep track of viewed and unviewed videos
## [](https://github.com/tubearchivist/tubearchivist#problem-tube-archivist-tries-to-solve)Problem Tube Archivist tries to solve

Once your YouTube video collection grows, it becomes hard to search and find a specific video. That's where Tube Archivist comes in: By indexing your video collection with metadata from YouTube, you can organize, search and enjoy your archived YouTube videos without hassle offline through a convenient web interface.

## [](https://github.com/tubearchivist/tubearchivist#installing-and-updating)Installing and updating

There's dedicated user-contributed install steps under [docs/Installation.md](https://github.com/tubearchivist/tubearchivist/blob/master/docs/Installation.md) for podman, Unraid, Truenas and Synology which you can use instead of this section if you happen to be using one of those. Otherwise, continue on.

For minimal system requirements, the Tube Archivist stack needs around 2GB of available memory for a small testing setup and around 4GB of available memory for a mid to large sized installation. Minimal with dual core with 4 threads, better quad core plus.

This project requires docker. Ensure it is installed and running on your system.

Note for **arm64**: Tube Archivist is a multi arch container, same for redis. For Elasitc Search use the official image for arm64 support. Other architectures are not supported.

Save the [docker-compose.yml](https://github.com/tubearchivist/tubearchivist/blob/master/docker-compose.yml) file from this reposity somewhere permanent on your system, keeping it named `docker-compose.yml`. You'll need to refer to it whenever starting this application.

Edit the following values from that file:

-   under `tubearchivist`->`environment`:
    -   `HOST_UID`: your UID, if you want TubeArchivist to create files with your UID. Remove if you are OK with files being owned by the the container user.
    -   `HOST_GID`: as above but GID.
    -   `TA_HOST`: change it to the address of the machine you're running this on. This can be an IP address or a domain name.
    -   `TA_PASSWORD`: pick a password to use when logging in.
    -   `ELASTIC_PASSWORD`: pick a password for the elastic service. You won't need to type this yourself.
    -   `TZ`: your time zone. If you don't know yours, you can look it up [here](https://www.timezoneconverter.com/cgi-bin/findzone/findzone).
-   under `archivist-es`->`environment`:
    -   `"ELASTIC_PASSWORD=verysecret"`: change `verysecret` to match the ELASTIC_PASSWORD you picked above.

By default Docker will store all data, including downloaded data, in its own data-root directory (which you can find by running `docker info` and looking for the "Docker Root Dir"). If you want to use other locations, you can replace the `media:`, `cache:`, `redis:`, and `es:` volume names with absolute paths; if you do, remove them from the `volumes:` list at the bottom of the file.

From a terminal, `cd` into the directory you saved the `docker-compose.yml` file in and run `docker compose up --detach`. The first time you do this it will download the appropriate images, which can take a minute.

You can follow the logs with `docker compose logs -f`. Once it's ready it will print something like `celery@1234567890ab ready`. At this point you should be able to go to `http://your-host:8000` and log in with the `TA_USER`/`TA_PASSWORD` credentials.

You can bring the application down by running `docker compose down` in the same directory.

Use the _latest_ (the default) or a named semantic version tag for the docker images. The _unstable_ tag is for intermediate testing and as the name implies, is **unstable** and not be used on your main installation but in a [testing environment](https://github.com/tubearchivist/tubearchivist/blob/master/CONTRIBUTING.md).

## [](https://github.com/tubearchivist/tubearchivist#installation-details)Installation Details

Tube Archivist depends on three main components split up into separate docker containers:

### [](https://github.com/tubearchivist/tubearchivist#tube-archivist)Tube Archivist

The main Python application that displays and serves your video collection, built with Django.

-   Serves the interface on port `8000`
-   Needs a volume for the video archive at **/youtube**
-   And another volume to save application data at **/cache**.
-   The environment variables `ES_URL` and `REDIS_HOST` are needed to tell Tube Archivist where Elasticsearch and Redis respectively are located.
-   The environment variables `HOST_UID` and `HOST_GID` allows Tube Archivist to `chown` the video files to the main host system user instead of the container user. Those two variables are optional, not setting them will disable that functionality. That might be needed if the underlying filesystem doesn't support `chown` like _NFS_.
-   Set the environment variable `TA_HOST` to match with the system running Tube Archivist. This can be a domain like _example.com_, a subdomain like _ta.example.com_ or an IP address like _192.168.1.20_, add without the protocol and without the port. You can add multiple hostnames separated with a space. Any wrong configurations here will result in a `Bad Request (400)` response.
-   Change the environment variables `TA_USERNAME` and `TA_PASSWORD` to create the initial credentials.
-   `ELASTIC_PASSWORD` is for the password for Elasticsearch. The environment variable `ELASTIC_USER` is optional, should you want to change the username from the default _elastic_.
-   For the scheduler to know what time it is, set your timezone with the `TZ` environment variable, defaults to _UTC_.
-   Set the environment variable `ENABLE_CAST=True` to send videos to your cast device, [read more](https://github.com/tubearchivist/tubearchivist#enable-cast).

### [](https://github.com/tubearchivist/tubearchivist#port-collisions)Port collisions

If you have a collision on port `8000`, best solution is to use dockers _HOST_PORT_ and _CONTAINER_PORT_ distinction: To for example change the interface to port 9000 use `9000:8000` in your docker-compose file.

Should that not be an option, the Tube Archivist container takes these two additional environment variables:

-   **TA_PORT**: To actually change the port where nginx listens, make sure to also change the ports value in your docker-compose file.
-   **TA_UWSGI_PORT**: To change the default uwsgi port 8080 used for container internal networking between uwsgi serving the django application and nginx.

Changing any of these two environment variables will change the files _nginx.conf_ and _uwsgi.ini_ at startup using `sed` in your container.

### [](https://github.com/tubearchivist/tubearchivist#ldap-authentication)LDAP Authentication

You can configure LDAP with the following environment variables:

-   `TA_LDAP` (ex: `true`) Set to anything besides empty string to use LDAP authentication **instead** of local user authentication.
-   `TA_LDAP_SERVER_URI` (ex: `ldap://ldap-server:389`) Set to the uri of your LDAP server.
-   `TA_LDAP_DISABLE_CERT_CHECK` (ex: `true`) Set to anything besides empty string to disable certificate checking when connecting over LDAPS.
-   `TA_LDAP_BIND_DN` (ex: `uid=search-user,ou=users,dc=your-server`) DN of the user that is able to perform searches on your LDAP account.
-   `TA_LDAP_BIND_PASSWORD` (ex: `yoursecretpassword`) Password for the search user.
-   `TA_LDAP_USER_ATTR_MAP_USERNAME` (default: `uid`) Bind attribute used to map LDAP user's username
-   `TA_LDAP_USER_ATTR_MAP_PERSONALNAME` (default: `givenName`) Bind attribute used to match LDAP user's First Name/Personal Name.
-   `TA_LDAP_USER_ATTR_MAP_SURNAME` (default: `sn`) Bind attribute used to match LDAP user's Last Name/Surname.
-   `TA_LDAP_USER_ATTR_MAP_EMAIL` (default: `mail`) Bind attribute used to match LDAP user's EMail address
-   `TA_LDAP_USER_BASE` (ex: `ou=users,dc=your-server`) Search base for user filter.
-   `TA_LDAP_USER_FILTER` (ex: `(objectClass=user)`) Filter for valid users. Login usernames are matched using the attribute specified in `TA_LDAP_USER_ATTR_MAP_USERNAME` and should not be specified in this filter.

When LDAP authentication is enabled, django passwords (e.g. the password defined in TA_PASSWORD), will not allow you to login, only the LDAP server is used.

### [](https://github.com/tubearchivist/tubearchivist#enable-cast)Enable Cast

As Cast doesn't support authentication, enabling this functionality will make your static files like artwork and media files accessible by guessing the links. That's read only access, the application itself is still protected.

Enabling this integration will embed an additional third party JS library from **Google**.

**Requirements**:

-   HTTPS: To use the cast integration HTTPS needs to be enabled, which can be done using a reverse proxy. This is a requirement by Google as communication to the cast device is required to be encrypted, but the content itself is not.
-   Supported Browser: A supported browser is required for this integration such as Google Chrome. Other browsers, especially Chromium-based browsers, may support casting by enabling it in the settings.
-   Subtitles: Subtitles are supported however they do not work out of the box and require additional configuration. Due to requirements by Google, to use subtitles you need additional headers which will need to be configured in your reverse proxy. See this [page](https://developers.google.com/cast/docs/web_sender/advanced#cors_requirements) for the specific requirements.  
    You need the following headers: Content-Type, Accept-Encoding, and Range. Note that the last two headers, Accept-Encoding and Range, are additional headers that you may not have needed previously.  
    Wildcards "*" can not be used for the Access-Control-Allow-Origin header. If the page has protected media content, it must use a domain instead of a wildcard.

### [](https://github.com/tubearchivist/tubearchivist#elasticsearch)Elasticsearch

**Note**: Tube Archivist depends on Elasticsearch 8.

Use `bbilly1/tubearchivist-es` to automatically get the recommended version, or use the official image with the version tag in the docker-compose file.

Use official Elastic Search for **arm64**.

Stores video meta data and makes everything searchable. Also keeps track of the download queue.

-   Needs to be accessible over the default port `9200`
-   Needs a volume at **/usr/share/elasticsearch/data** to store data

Follow the [documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html) for additional installation details.

### [](https://github.com/tubearchivist/tubearchivist#elasticsearch-on-a-custom-port)Elasticsearch on a custom port

Should you need to change the port for Elasticsearch to for example _9500_, follow these steps:

-   Set the environment variable `http.port=9500` to the ES container
-   Change the _expose_ value for the ES container to match your port number
-   For the Tube Archivist container, change the _ES_URL_ environment variable, e.g. `ES_URL=http://archivist-es:9500`

### [](https://github.com/tubearchivist/tubearchivist#redis-json)Redis JSON

Functions as a cache and temporary link between the application and the file system. Used to store and display messages and configuration variables.

-   Needs to be accessible over the default port `6379`
-   Needs a volume at **/data** to make your configuration changes permanent.

### [](https://github.com/tubearchivist/tubearchivist#redis-on-a-custom-port)Redis on a custom port

For some architectures it might be required to run Redis JSON on a nonstandard port. To for example change the Redis port to **6380**, set the following values:

-   Set the environment variable `REDIS_PORT=6380` to the _tubearchivist_ service.
-   For the _archivist-redis_ service, change the ports to `6380:6380`
-   Additionally set the following value to the _archivist-redis_ service: `command: --port 6380 --loadmodule /usr/lib/redis/modules/rejson.so`

### [](https://github.com/tubearchivist/tubearchivist#updating-tube-archivist)Updating Tube Archivist

You will see the current version number of **Tube Archivist** in the footer of the interface. There is a daily version check task querying tubearchivist.com, notifying you of any new releases in the footer. To take advantage of the latest fixes and improvements, make sure you are running the _latest and greatest_.

-   This project is tested for updates between one or two releases maximum. Further updates back may or may not be supported and you might have to reset your index and configurations to update. Ideally apply new updates at least once per month.
-   There can be breaking changes between updates, particularly as the application grows, new environment variables or settings might be required for you to set in the your docker-compose file. _Always_ check the **release notes**: Any breaking changes will be marked there.
-   All testing and development is done with the Elasticsearch version number as mentioned in the provided _docker-compose.yml_ file. This will be updated when a new release of Elasticsearch is available. Running an older version of Elasticsearch is most likely not going to result in any issues, but it's still recommended to run the same version as mentioned. Use `bbilly1/tubearchivist-es` to automatically get the recommended version.

### [](https://github.com/tubearchivist/tubearchivist#helm-charts)Helm charts

There is a Helm Chart available at [https://github.com/insuusvenerati/helm-charts](https://github.com/insuusvenerati/helm-charts). Mostly self-explanatory but feel free to ask questions in the discord / subreddit.

## [](https://github.com/tubearchivist/tubearchivist#common-errors)Common Errors

### [](https://github.com/tubearchivist/tubearchivist#vmmax_map_count)vm.max_map_count

**Elastic Search** in Docker requires the kernel setting of the host machine `vm.max_map_count` to be set to at least 262144.

To temporary set the value run:

```
sudo sysctl -w vm.max_map_count=262144
```

To apply the change permanently depends on your host operating system:

-   For example on Ubuntu Server add `vm.max_map_count = 262144` to the file _/etc/sysctl.conf_.
-   On Arch based systems create a file _/etc/sysctl.d/max_map_count.conf_ with the content `vm.max_map_count = 262144`.
-   On any other platform look up in the documentation on how to pass kernel parameters.

### [](https://github.com/tubearchivist/tubearchivist#permissions-for-elasticsearch)Permissions for elasticsearch

If you see a message similar to `Unable to access 'path.repo' (/usr/share/elasticsearch/data/snapshot)` or `failed to obtain node locks, tried [/usr/share/elasticsearch/data]` and `maybe these locations are not writable` when initially starting elasticsearch, that probably means the container is not allowed to write files to the volume.  
To fix that issue, shutdown the container and on your host machine run:

```
chown 1000:0 -R /path/to/mount/point
```

This will match the permissions with the **UID** and **GID** of elasticsearch process within the container and should fix the issue.

### [](https://github.com/tubearchivist/tubearchivist#disk-usage)Disk usage

The Elasticsearch index will turn to _read only_ if the disk usage of the container goes above 95% until the usage drops below 90% again, you will see error messages like `disk usage exceeded flood-stage watermark`, [link](https://github.com/tubearchivist/tubearchivist#disk-usage).

Similar to that, TubeArchivist will become all sorts of messed up when running out of disk space. There are some error messages in the logs when that happens, but it's best to make sure to have enough disk space before starting to download.

## [](https://github.com/tubearchivist/tubearchivist#getting-started)Getting Started

1.  Go through the **settings** page and look at the available options. Particularly set _Download Format_ to your desired video quality before downloading. **Tube Archivist** downloads the best available quality by default. To support iOS or MacOS and some other browsers a compatible format must be specified. For example:

```
bestvideo[vcodec*=avc1]+bestaudio[acodec*=mp4a]/mp4
```

2.  Subscribe to some of your favorite YouTube channels on the **channels** page.
3.  On the **downloads** page, click on _Rescan subscriptions_ to add videos from the subscribed channels to your Download queue or click on _Add to download queue_ to manually add Video IDs, links, channels or playlists.
4.  Click on _Start download_ and let **Tube Archivist** to it's thing.
5.  Enjoy your archived collection!

## [](https://github.com/tubearchivist/tubearchivist#roadmap)Roadmap

We have come far, nonetheless we are not short of ideas on how to improve and extend this project. Issues waiting for you to be tackled in no particular order:

-   User roles
-   Podcast mode to serve channel as mp3
-   Implement [PyFilesystem](https://github.com/PyFilesystem/pyfilesystem2) for flexible video storage
-   Implement [Apprise](https://github.com/caronc/apprise) for notifications ([#97](https://github.com/tubearchivist/tubearchivist/issues/97))
-   User created playlists, random and repeat controls ([#108](https://github.com/tubearchivist/tubearchivist/issues/108), [#220](https://github.com/tubearchivist/tubearchivist/issues/220))
-   Auto play or play next link ([#226](https://github.com/tubearchivist/tubearchivist/issues/226))
-   Multi language support
-   Show total video downloaded vs total videos available in channel
-   Add statistics of index
-   Download speed schedule ([#198](https://github.com/tubearchivist/tubearchivist/issues/198))
-   Download or Ignore videos by keyword ([#163](https://github.com/tubearchivist/tubearchivist/issues/163))
-   Custom searchable notes to videos, channels, playlists ([#144](https://github.com/tubearchivist/tubearchivist/issues/144))

Implemented:

-   Download video comments [2022-11-30]
-   Show similar videos on video page [2022-11-30]
-   Implement complete offline media file import from json file [2022-08-20]
-   Filter and query in search form, search by url query [2022-07-23]
-   Make items in grid row configurable to use more of the screen [2022-06-04]
-   Add passing browser cookies to yt-dlp [2022-05-08]
-   Add [SponsorBlock](https://sponsor.ajay.app/) integration [2022-04-16]
-   Implement per channel settings [2022-03-26]
-   Subtitle download & indexing [2022-02-13]
-   Fancy advanced unified search interface [2022-01-08]
-   Auto rescan and auto download on a schedule [2021-12-17]
-   Optional automatic deletion of watched items after a specified time [2021-12-17]
-   Create playlists [2021-11-27]
-   Access control [2021-11-01]
-   Delete videos and channel [2021-10-16]
-   Add thumbnail embed option [2021-10-16]
-   Create a github wiki for user documentation [2021-10-03]
-   Grid and list view for both channel and video list pages [2021-10-03]
-   Un-ignore videos [2021-10-03]
-   Dynamic download queue [2021-09-26]
-   Backup and restore [2021-09-22]
-   Scan your file system to index already downloaded videos [2021-09-14]

## [](https://github.com/tubearchivist/tubearchivist#known-limitations)Known limitations

-   Video files created by Tube Archivist need to be playable in your browser of choice. Not every codec is compatible with every browser and might require some testing with format selection.
-   Every limitation of **yt-dlp** will also be present in Tube Archivist. If **yt-dlp** can't download or extract a video for any reason, Tube Archivist won't be able to either.
-   There is currently no flexibility in naming of the media files.

