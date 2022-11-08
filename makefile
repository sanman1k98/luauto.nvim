XDG_DATA_HOME ?= $(HOME)/.local/share


.PHONY : \
	test


test :
	nvim --headless \
		--noplugin \
		-u "./tests/testing_init.lua" \
		-c "PlenaryBustedDirectory ./tests/ { minimal_init = './tests/testing_init.lua' }"

