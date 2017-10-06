SHELL = /bin/bash
MAKEFLAGS += --no-builtin-rules
.SUFFIXES:
.PHONY: install clean destroy vm_clean vm_purge var_clean

install: | .vagrant var/logs

.vagrant:
	@vagrant up --no-provision

var/logs:
	@vagrant provision


clean: | vm_clean var_clean


destroy: | vm_purge var_clean 


vm_clean:
	@for vm in tinc1 tinc2; do \
		vagrant ssh -c 'for n in nodejs tincd; do pid=$$(pidof $$n);((pid)) && sudo kill $$pid; sudo rm -rf /etc/tinc/sandbox; done' $$vm; \
	done

vm_purge:
	@vagrant destroy && rm -rf .vagrant

var_clean:
	@rm -rf var/{hosts,logs,tinc1,tinc2}

