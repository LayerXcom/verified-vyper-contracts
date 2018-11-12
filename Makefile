# Settings
# --------

specs_dir:=specs
build_dir:=.build

K_VERSION   :=e36d4ce05d85a8c1f8a237c2c88ff0a7ada5c9cd
KEVM_VERSION:=e6c4b961495768a429fcffaa81418472953c8568

.PHONY: all clean k kevm clean-kevm

all: k kevm k-files

clean:
	rm -rf $(specs_dir) $(build_dir)/*

pandoc_tangle_submodule:=$(build_dir)/pandoc-tangle
TANGLER:=$(pandoc_tangle_submodule)/tangle.lua
LUA_PATH:=$(pandoc_tangle_submodule)/?.lua;;
export LUA_PATH

$(TANGLER):
	git submodule update --init -- $(pandoc_tangle_submodule)

k_repo:=https://github.com/kframework/k
k_repo_dir:=$(build_dir)/k
k_bin:=$(shell pwd)/$(k_repo_dir)/k-distribution/target/release/k/bin

k:
	git clone $(k_repo) $(k_repo_dir)
	cd $(k_repo_dir) \
		&& git reset --hard $(K_VERSION) \
		&& mvn package -DskipTests

kevm_repo:=https://github.com/kframework/evm-semantics
kevm_repo_dir:=$(build_dir)/evm-semantics

kevm:
	git clone $(kevm_repo) $(kevm_repo_dir)
	cd $(kevm_repo_dir) \
		&& git reset --hard $(KEVM_VERSION) \
		&& make tangle-deps \
		&& make defn \
		&& $(k_bin)/kompile -v --debug --backend java -I .build/java -d .build/java --main-module ETHEREUM-SIMULATION --syntax-module ETHEREUM-SIMULATION .build/java/driver.k


# Definition Files
# ----------------

k_files:=lemmas.k

k-files: $(patsubst %, $(specs_dir)/%, $(k_files))

# Lemmas
$(specs_dir)/lemmas.k: resources/lemmas.md $(TANGLER)
	@echo >&2 "== tangle: $@"
	mkdir -p $(dir $@)
	pandoc --from markdown --to "$(TANGLER)" --metadata=code:".k" $< > $@

# Spec Files
# ----------

vyper_files:= # TODO: add files

vyper: $(patsubst %, $(specs_dir)/vyper/%, $(vyper_files)) $(specs_dir)/lemmas.k

vyper_tmpls:=vyper/module-tmpl.k vyper/spec-tmpl.k

 $(specs_dir)/vyper/%-spec.k: $(vyper_tmpls) vyper/vyper-spec.ini
	@echo >&2 "==  gen-spec: $@"
	mkdir -p $(dir $@)
	python3 resources/gen-spec.py $^ $* $* > $@
	cp vyper/abstract-semantics.k $(dir $@)
	cp vyper/verification.k $(dir $@)

# Testing
# -------

TEST:=$(k_bin)/kprove -v -d $(kevm_repo_dir)/.build/java -m VERIFICATION --z3-executable --z3-impl-timeout 500

test_files:=$(wildcard specs/*/*-spec.k)

test: $(test_files:=.test)

specs/%-spec.k.test: specs/%-spec.k
	$(TEST) $<
