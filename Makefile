.PHONY: install postinstall nuke

install:
	ansible-playbook -i inventory.ini install.yml -vvv

postinstall:
	ansible-playbook -i inventory.ini postinstall.yml -vvv

nuke:
	-vagrant destroy
	-rm -rv ./packer_cache
	-rm -rv ./packer_output
	-rm -rv ./vagrant_output
	-rm -v ./Vagrantfile
	-rm -rv ./.vagrant
	-vagrant box remove gentoo
