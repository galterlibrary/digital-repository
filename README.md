# DigitalHub

This is the source code for the Galter's institutional repository.

This is a [samvera/sufia](https://github.com/samvera/sufia/tree/6.x-stable) based rails application, branch `6.x-stable`.

### Getting Started
---
##### Prerequisites
* Ruby 2.3.7
* Rails 4.2.7
* redis
* [hydra-jetty](https://github.com/galterlibrary/hydra-jetty)


##### OSX Installation Debugging Tips
**Ruby Installation**
Ruby version 2.4.2 requires OpenSSL Version 1.0.* (versions older than 1.1+). If using RVM the easiest way to install
this version of OpenSSL is to use `rvm pkg install openssl`. After this completes install Ruby 2.4.2 with
`rvm install 2.4.2 --with-openssl-dir=$HOME/.rvm/usr/`. If there are other versions of Ruby installed you might run into
an issue with symbolic links and OpenSSL, something like `Too many levels of symbolic links`. This seems to be caused by
the directory `~/.rvm/usr/ssl/man/`, which contains manual pages for openssl, and the problem can be resolved by just
removing this directory entirely `rm -rf ~/.rvm/usr/ssl/man/`.

If there are issues with gem versions when running `bundle install` edit Gemfile.lock to use versions that are available
currently. Realistically this should **only** happen with the gem `logger` which previously had version 1.2.8 available
from RubyGems before it was replaced with version 1.2.7 ((seriously...))[https://github.com/nahi/logger/issues/3]. It is
recommended to use version 1.3.0 for now as there are features in version 1.2.8 that were not in version 1.2.7.

After running `bundle install` without errors, if there are issues with starting your server try running
`rvm gemset pristine` and then starting the rails server again.

**Hydra Jetty Installation**
Make sure that you're using the version of hydra-jetty that was forked specifically for Galter Library repos (it's the
repo linked in this README). Basically this repo provides a jar file that runs two applications: Fedora (repository not
linux distro) and Solr from Apache. For anything to work you will need to ensure you're using **Java 8**. On OSX run
`java -version` if it does not list `java version "1.8...` (by Java version naming conventions 1.8 means Java 8) then
you will need to make sure that Java 8 is installed and that your shell is set to use it.
To check all installed java versions run `/usr/libexec/java_home -V` and if Java 8 is in the list it is installed. If
the shell is still listing some other version use the following command to change to Java 8
`export JAVA_HOME=`/usr/libexec/java_home -v 1.8`; java -version`. You can switch back to whatever the previous version
of java was using the same command, but replacing `-v 1.8` with whatever the desired version is.

To ensure that everything is running properly open your web browser to http://localhost:8983 and click the links. If
either app does not load properly check the debug log located in the hydra-jetty project directory at `logs/debugger.log`

##### Environment variables
You will need to request the secret env variables for this to work.

##### Development
1. Start the hydra-jetty app
```
hydra-jetty/$ java -jar start.jar
```
2. Start redis

3. Start the resque service
```
digital-repository/$ QUEUE=* rake environment resque:work
```
4. Start up your rails server
```
digital-repository/$ rails s
```

##### Testing
* hydra-jetty and redis need to be running first
```
digital-repository/$ rspec spec/
```

##### Deployment
* Capistrano-based deployments
```
digital-repository/$ cap <stage> deploy
```

##### Digital Hub Export
* Export repo to JSON formatted for InvenioRDM
```
./bin/rake repo_export
```
* Same as above, but with extra debugging information
```
./bin/rake verbose debug repo_export
```
