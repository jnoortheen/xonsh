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
	* xonsh/ply: Pull down most recent ply
	""")

.PHONY: xonsh/ply
xonsh/ply:
	git subtree pull --prefix xonsh/ply https://github.com/dabeaz/ply.git master --squash


.PHONY: clean
clean:
	find xonsh -name __amalgam__.py -delete -print
	find xonsh -name "*.pyc" -delete

.PHONY: clean-compiled
clean-compiled: clean
	find xonsh -name "*.so" -delete -print
	find xonsh -name "*.c" -not -path "*/test/*" -delete -print

.PHONY: nuitka
nuitka: clean-compiled
	for module in (
	    "xonsh/tokenize",
	    "xonsh/lexer",
	    "xonsh/ply/ply/lex",
	    "xonsh/ply/ply/yacc",
	):
	    location, file = module.rsplit("/", 1)
	    python -m nuitka --no-pyi-file --output-dir=build --module @(f"{module}.py")
	    mv @(f"build/{file}.cpython-38-x86_64-linux-gnu.so") @(f"{location}")

.PHONY: cython
cython: clean-compiled
	env CYTHONIZE=True python setup.py build_ext --inplace

.PHONY: bench
bench:
	xonsh .local.out/cythonize/bench.xsh

.PHONY: bench-nk
bench-nk: clean nuitka bench

.PHONY: bench-cy
bench-cy: clean cython bench

.PHONY: bench-py
bench-py: clean-compiled bench

.PHONY: amalgamate
amalgamate:
	sys.path.insert(0, '.')
	import setup
	setup.amalgamate_source()
	_ = sys.path.pop(0)
