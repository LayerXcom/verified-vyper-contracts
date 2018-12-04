# Settings
# --------

specs_dir:=specs
build_dir:=.build

K_VERSION   :=b65568ade007d54dd21667f4f56f2d7471bb6596
KEVM_VERSION:=5d3bbb6d9dd3a2913201071937cb3f00d66832b0

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

# ERC20
erc20_files:=totalSupply-spec.k \
             balanceOf-spec.k \
             allowance-spec.k \
             approve-spec.k \
             transfer-success-1-spec.k \
             transfer-success-2-spec.k \
             transfer-failure-1-spec.k \
             transfer-failure-2-spec.k \
             transferFrom-success-1-spec.k \
             transferFrom-success-2-spec.k \
             transferFrom-failure-1-spec.k \
             transferFrom-failure-2-spec.k

erc20: $(patsubst %, $(specs_dir)/erc20/%, $(erc20_files)) $(specs_dir)/lemmas.k

erc20_tmpls:=erc20/module-tmpl.k erc20/spec-tmpl.k

 $(specs_dir)/erc20/%-spec.k: $(erc20_tmpls) erc20/erc20-spec.ini
	@echo >&2 "==  gen-spec: $@"
	mkdir -p $(dir $@)
	python3 resources/gen-spec.py $^ $* $* > $@
	cp erc20/abstract-semantics.k $(dir $@)
	cp erc20/verification.k $(dir $@)

# ERC721
erc721_files:=balanceOf-success-spec.k \
			  balanceOf-failure-spec.k \
			  ownerOf-success-spec.k \
			  ownerOf-failure-spec.k \
			  getApproved-success-spec.k \
			  getApproved-failure-spec.k \
			  isApprovedForAll-spec.k


erc721: $(patsubst %, $(specs_dir)/erc721/%, $(erc721_files)) $(specs_dir)/lemmas.k

erc721_tmpls:=erc721/module-tmpl.k erc721/spec-tmpl.k

 $(specs_dir)/erc721/%-spec.k: $(erc721_tmpls) erc721/erc721-spec.ini
	@echo >&2 "==  gen-spec: $@"
	mkdir -p $(dir $@)
	python3 resources/gen-spec.py $^ $* $* > $@
	cp erc721/abstract-semantics.k $(dir $@)
	cp erc721/verification.k $(dir $@)

# Testing
# -------

TEST:=$(k_bin)/kprove -v -d $(kevm_repo_dir)/.build/java -m VERIFICATION --z3-impl-timeout 500

test_files:=$(wildcard specs/*/*-spec.k)

test: $(test_files:=.test)

specs/%-spec.k.test: specs/%-spec.k
	$(TEST) $<
