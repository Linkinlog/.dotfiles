dev:
	@command "$(HOME)/.local/bin/pre_dev_setup"
	@command "$(HOME)/.local/bin/post_dev_setup"

.PHONY: dev
