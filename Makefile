.PHONY: main postinstall desktop desktop-all

main:
	ansible-playbook -i inventory install.yml -vvv --skip-tags "postinstall,desktop"

postinstall:
	ansible-playbook -i inventory postinstall.yml -vvv --tags "postinstall"