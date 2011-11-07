maintainer       "Heavy Water Software Inc."
maintainer_email "darrin@heavywater.ca"
license          "Apache 2.0"
description      "Installs/Configures ganglia"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.0.2"

supports "debian"
supports "ubuntu"
supports "redhat"
supports "centos"
supports "fedora"

#The supervisor can be found here: https://github.com/coderanger/chef-supervisor
# coderanger is Noah Kantrowitz, working for Opscode, I expect the cookbook to be on the repo soon enough
depends "supervisor"