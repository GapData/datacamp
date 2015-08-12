# Installation and requirements

In order to use the software multiple required components need to by installed on the system. This chapter walks a systems administrator and/or a developer through the process of setting up the software on a clean system. We assume a unix based operating systems (linux, mac os etc.) is used. We also assume that the reader is a reasonably competent unix user comfortable using the command line. Windows users may be able to successfully install the software, but we do not provide any support for the platform.

## Requirements

The tutorial will cover installation of the following parts needed for the software to function properly on a clean system:

- git
- mysql database server
- ruby language (rbenv) and rubygems (bundler)
- rails config
- run the app
- run the worker process

*The tutorial was tested and is supported on Mac OS X and Ubuntu/Debian based linux distribu-tions.*


## Git

The project is hosted on github: [https://github.com/fairplaysk/datacamp](https://github.com/fairplaysk/datacamp)

In order to be able to use the project we recommend downloading it via the git source control management. It can be downloaded from the github page via zip, but updates may be difficult to apply this way.

You can test if it is present by issuing the following command on the command line:

    $ git --version
    git version 1.7.4.4

If the result on your command line is not similar to the one provided you need to install git.

### Linux OS

We recommend installing git in linux via the package management tool present on your distribu-tion. The command to install the git binary is:

    sudo apt-get install git-core

### Mac OS

In order to have the build tools required to build some of the required software you will need to install Xcode. We recommend version 4.1 as later versions as of this writing do not have a gcc compiler required to build ruby. The Xcode package contains a git client.

## Download

In order to download the project you need to issue the following command:

    git clone [git@github.com](mailto:git@github.com):fairplaysk/datacamp.git

which will download the project into a directory called datacamp in the working directory of the command line. At this point you can browse the contents of the project.

## Ruby language

The project needs the Ruby language (ruby-lang.org) and the Ruby on Rails (rubyonrails.org) framework to run. We recommend installing the ruby language via the rbenv ruby manager ( [https://github.com/sstephenson/rbenv](https://github.com/sstephenson/rbenv)).

### Mac OS

On mac systems we recommend using homebrew package manager system ( [http://mxcl.github.com/homebrew/](http://mxcl.github.com/homebrew/)) to install rbenv and then use rbenv to install a recent ruby version. We support running on the latest ruby 1.9.3 as of writing this document.

To install homebrew issue the following command on the terminal:

    $ /usr/bin/ruby -e "$(curl -fsSL [https://raw.github.com/gist/323731](https://raw.github.com/gist/323731))"

After a successful installation of homebrew issue the following command to install rbenv:

    $ brew update
    
    $ brew install rbenv
    
    $ brew install ruby-build

Once rbenv is installed add rbenv init to your shell to enable shims and autocompletion:

    $ echo 'eval "$(rbenv init -)"' >> ~/.bash_profile

Now restart your shell and install ruby version 1.9.3-p0

    $ rbenv install 1.9.3-p0

Upon completion of the last step a fully working ruby should be installed on the system. The following command will make it the default ruby on the system:

    $ rbenv global local 1.9.3-p0

### Linux OS

Linux users can use the rbenv installer to install ruby. In linux there are some dependencies that can prevent the ruby VM from compiling. To ensure they are present issue the following command on the terminal (ubuntu/debian):

    $ sudo apt-get install apache2 curl git libmysqlclient-dev mysql-server nodejs

To install rbenv and ruby (version 1.9.3-p0) please follow part 2.1 (basic github checkout) on

[https://github.com/sstephenson/rbenv](https://github.com/sstephenson/rbenv)

## Mysql server

The application uses the mysql database. We recommend mysql version 5.1 instead of the latest version at the time of writing (5.5) because the native c connectors works better with ruby.

To install it on linux we recommend using the package management tool present on your system:

    $ sudo apt-get install libmysqlclient-dev mysql-server

To install it on the Mac OS X we recommend using the binary distribution available at [http://dev.mysql.com/downloads/mysql/5.1.html](http://dev.mysql.com/downloads/mysql/5.1.html) and following the onscreen instructions.

We assume that you use the default configuration with the root user without a password. For production use we recommend changing this behavior. For local development this setting is fine.

## Rubygems

In order to run the project several ruby libraries (called gems) need to be present on the system. To simplify the process a tool is present to install all of the libraries. If you have a ruby installed (see previous chapter), you can install it by issuing:

    $ gem install bundler

Once installed issue the following command from within the project folder you checked out in an earlier chapter about git:

    $ pwd
    ~/code/datanest
    $ bundle install

The command will take a few seconds to run and you will see all of the libraries installing.

## Rails config

A plain downloaded project will not boot, because there is some configuration necessary in order to make it run. Configuration file in the project have examples included. To use them, copy the files without the .example extension to have all of the configuration files present in the project folder. The following files need to be present in the project to be able to run it:

    config/sphinx.yml
    config/datacamp_config.yml
    config/database.yml
    config/initializes/site_keys.rb
    config/initializes/secret_token.rb

The sphinx.yml file can be used without modification with the defaults provided. The datacamp_config.yml is mainly used for production configuration such as capcha keys. The database.yml file is where connection information to the mysql database lives. We use 3 databases per environment (application, data and staging). For more information on initializing the database please referer to the chapter 'mysql server'. For site_keys.rb and secret_token.rb please referer to the documentation inside the examples.

To make changes to some of the constants in the project, use the config/

## Preparing databases

The software needs three databases in order to use all of its features. The configuration is located inside the config/database.yml file and the three databases need to be configured for the rails environment that will be used. For the purpose of this tutorial the development environment will be used. To find more information on rails environments see

[http://guides.rubyonrails.org/getting_started.html#](http://guides.rubyonrails.org/getting_started.html#)configuring-a-database

We recommend creating the databases manually, so for the example database.yml provided databases datanest_app, datanest_data and datanest_staging need to be created to run the software in development mode. Datanest_app holds meta information about the published data, datanest_data holds the actual data and datanest_staging is a deprecated database that is used as a staging area when scraping data from sites.

You can use rake task to create all databases with rails:

    $ rake db:create:all

To load the schema into the app database use the standard rake command (to learn more about rake and how to use it with rails see

[http://guides.rubyonrails.org/command_line.html#](http://guides.rubyonrails.org/command_line.html#)rake).

    $ rake db:schema:load
    
    $ rake db_staging:schema:load
    
    $ rake db_data:schema:load
    
    To check if you are completely schema in all databases use rake tasks for migrations:
    
    $ rake db:migrate   //standard rake task for migration in primary database
    
    $ rake db_staging:migrate  //rake task to migrate staging database
    
    $ rake db_data:migrate  //rake task to migrate data database


To load seed data into the app database to make the app work issue:

    $ rake db:bootstrap   	//initialize

 app, system variables, pages, admin user

To initialize datasets and etl parsers into the app run standard seed task:

    $ rake db:seed			//initialize datasets, etl configurations

To initialize staging datasets run seed task for staging:

    $ rake db_staging:seed  //initialize staging database

There is an additional command to load schema into the data database to use the automated scrapers. These are highly customized to the way AFP needs them and should be used as a template on how to create custom ones.

    $ rake db_data:migrate

## Run the app

In order to run the app for the first time in development the following command will startup a development server:

    $ bundle exec rails server

Navigating a browser to the page [http://localhost:3000](http://localhost:3000/) will open the main page. To login and start editing data use the user 'admin' with password 'admin' to login as a highly privileged user who has all privileges.

## Run the worker process

In order to use some of the functionality a worker process needs to be running. this starts the process until it gets shut down (ctrl+c).

bundle exec rake jobs:work

To start a daemon and leave it running in the background

    bundle exec script/delayed_job start

## Create CSV dumps

To use the API csv dumps of datasets need to be created beforehand. To create them use

    rake db:dump

which will use the dataset_dump_path setting in the datacamp_config.yml to dump the csv files in the selected directory.

## Install Cron

To initialize background etl and other jobs the project is set up to install cron jobs on the system. To do this an external library (see [https://github.com/javan/whenever](https://github.com/javan/whenever)) is used to define the jobs and the following issued on the system will install it to the current system user's crontab.

    $ bundle exec whenever

To edit the currently set up jobs open the schedule.rb file in the config directory of the project.