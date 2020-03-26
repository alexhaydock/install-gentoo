.PHONY: main
main:
	ansible-playbook -i inventory main.yml -vvv --skip-tags "postinstall,desktop"

.PHONY: postinstall
postinstall:
	ansible-playbook -i inventory main.yml -vvv --tags "postinstall"

.PHONY: desktop
desktop:
	ansible-playbook -i inventory main.yml -vvv --tags "desktop"

.PHONY: desktop-all
desktop-all:
	ansible-playbook -i inventory main.yml -vvv --skip-tags "postinstall,desktop"
	sleep 30
	ansible-playbook -i inventory main.yml -vvv --tags "desktop"