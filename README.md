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
