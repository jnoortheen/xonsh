# Make GNU Make xonshy
SHELL=xonsh
.SHELLFLAGS=-c
.ONESHELL:
#.SILENT:

# Unlike normal makefiles: executes the entire body in one go under xonsh, and doesn't echo

.PHONY: help
help:
	print("""
	Utility file for xonsh project. Try these targets:
	* amalgamate: Generate __amalgam__.py files
	* clean: Remove generated files (namely, the amalgamations)
	""")

.PHONY: xonsh/ply
xonsh/ply:
	git remote add ply https://github.com/dabeaz/ply.git
	git fetch ply
	git branch ply-branch ply/master
	git rm -rf xonsh/ply
	git read-tree --prefix=xonsh/ply/ply -u ply-branch:ply
	git add xonsh/ply
	git commit -m "Merged changes from ply to sub-directory"
	git branch -D ply-branch
	git remote remove ply

.PHONY: clean
clean:
	find xonsh -name __amalgam__.py -delete -print
	find xonsh -name "*.pyc" -delete
	find xonsh -name "*.so" -delete -print
	find xonsh -name "*.c" -not -path "*/test/*" -delete -print

.PHONY: nuitka
nuitka: clean
	pip install nuitka
	for module in (
	    "xonsh/tokenize",
	    "xonsh/lexer",
	    "xonsh/ply/ply/lex",
	    "xonsh/ply/ply/yacc",
	):
	    location, file = module.rsplit("/", 1)
	    python -m nuitka --no-pyi-file --output-dir=build --module @(f"{module}.py")
	    mv @(f"build/{file}.cpython-39-x86_64-linux-gnu.so") @(f"{location}")

.PHONY: cython
cython: clean
	pip install cython --pre
	env CYTHONIZE=True python setup.py build_ext --inplace

.PHONY: mypyc
mypyc: clean
	#pip install git+https://gitlab.com/python/mypy/git --force
	#pip install mypy
	env MYPYCIZE=True python setup.py build_ext --inplace

.PHONY: bench
bench:
	xonsh .local.out/profile/bench.xsh

.PHONY: bench-nk
bench-nk: clean nuitka bench

.PHONY: bench-cy
bench-cy: clean cython bench

.PHONY: bench-py
bench-py: clean-compiled bench

.PHONY: amalgamate
amalgamate:
	import sys
	sys.path.insert(0, '.')
	import setup
	setup.amalgamate_source()
	_ = sys.path.pop(0)
