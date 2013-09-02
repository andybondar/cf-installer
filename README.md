# Overview

This project provides a mechanism to automate several tasks to be able to set up a Vagrant VM with the following V2 (NG) Cloud Foundry components:

* Cloud Controller
* NATS
* DEA
* Gorouter
* UAA
* Warden
* Health Manager

## Requirements

* Vagrant
    - Download it from http://www.vagrantup.com (version 1.2 or higher)
    - Install required plugins:  
     `vagrant plugin install vagrant-berkshelf`  
     `vagrant plugin install vagrant-omnibus`

* Ruby 1.9.3

* (Optional) The VMware Fusion or VMware Workstation provider.  
If you do not have these installed, you can use the default VirtualBox provider (http://docs.vagrantup.com/v2/vmware/index.html)
    - Fusion:      
      `vagrant plugin install vagrant-vmware-fusion`  
      `vagrant plugin license vagrant-vmware-fusion license.lic`

    - Workstation:  
      `vagrant plugin install vagrant-vmware-workstation`  
      `vagrant plugin license vagrant-vmware-workstation license.lic`  

## Installation

```
git clone https://github.com/andybondar/cf-installer.git
cd cf-installer
```

### Provision The VM
#### Using VirtualBox
Initialize the Vagrant VM using the default VirtualBox provider. 

```
vagrant up
```

#### Using VMware Fusion / Workstation
Alternatively, you can use a different Vagrant provider such as the VMware Fusion or VMware Workstation provider. See the [Vagrant documentation](http://docs.vagrantup.com/v2/providers/index.html) for information on installing and using providers.  

> **Stop!!** If you are going to use the VMware provider, you **must** follow the instructions [here] (vmware/VMware-Instructions.md) first, or the next steps will result in an environment that will not work.

```
Fusion: vagrant up --provider=vmware_fusion
Workstation: vagrant up --provider=vmware_workstation
```

## Running Cloud Foundry

Cloud Foundry will be bootstrapped the first time the Vagrant provisioner runs.  After the bootstrap is complete, an upstart configuration will be generated to automatically start Cloud Foundry at boot.

The following commands may be helpful if you wish to manually start and stop Cloud Foundry.

```
# shell into the VM if you are not already there
vagrant ssh

# cd into directory shared with the host
cd /vagrant

# start Cloud Foundry
./start.sh

# Also, to stop:
./stop.sh

```

There is also a foreman alternative (http://ddollar.github.io/foreman/) which will print every single log into the console
```
foreman start
```

## Test Your New Cloud Foundry (v2) Instance

> This has to be done inside the VM. Also, CF must be up and running

* Set up your PaaS account
* 
```
cd /vagrant
rake cf:init_cf_cli
```

* Push a very simple sinatra application
* 
```
cd /vagrant/test-apps/sinatra-test-app
cf push
```


Expected output:

```
Uploading hello... OK
Starting hello... OK
-----> Downloaded app package (4.0K)
Installing ruby.
-----> Using Ruby version: ruby-1.9.2
-----> Installing dependencies using Bundler version 1.3.2
       Running: bundle install --without development:test --path vendor/bundle --binstubs vendor/bundle/bin --deployment
       Fetching gem metadata from http://rubygems.org/..........
       Fetching gem metadata from http://rubygems.org/..
       Installing rack (1.5.1)
       Installing rack-protection (1.3.2)
       Installing tilt (1.3.3)
       Installing sinatra (1.3.4)
       Using bundler (1.3.2)
       Your bundle is complete! It was installed into ./vendor/bundle
       Cleaning up the bundler cache.
-----> Uploading staged droplet (21M)
Checking hello...
  1/1 instances: 1 running
OK
```

Check if the app is running and working ok:

```
curl hello.vcap.me

Hello from 0.0.0.0:<some assigned port>!
```

Use "cf apps" command to list the apps you pushed:
```
cf apps
Getting applications in myspace... OK

name    status    usage     url          
hello   running   1 x 64M   hello.vcap.me
```
There is also a node.js sample app in test-apps

## Collaborate

You are welcome to contribute via [pull request](https://help.github.com/articles/using-pull-requests).
