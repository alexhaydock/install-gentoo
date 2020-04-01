.PHONY: main postinstall nuke

main:
	ansible-playbook -i inventory install.yml -vvv --skip-tags "postinstall,desktop"

postinstall:
	ansible-playbook -i inventory postinstall.yml -vvv --tags "postinstall"

nuke:
	-vagrant destroy
	-rm -rv ./packer_cache
	-rm -rv ./packer_output
	-rm -rv ./vagrant_output
	-rm -v ./Vagrantfile
	-rm -rv ./.vagrant
	-vagrant box remove gentoo