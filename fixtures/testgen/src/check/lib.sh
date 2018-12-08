# Make NM available from environment by default
export NM=${NM:-nm}

NM() { SH '$(NM)' "$@"; }

# Define a test with an auto-generated main function which
# calls all functions named "test_*"
# define_check [<name>] <source>.c [CC options]
define_check()
{
  CHECK_SOURCE="\$(SOURCE)/$MODULE_DIR/$1"
  CHECK_NAME=$(basename "$CHECK_SOURCE" .c)

  case "$2" in
  (-*) ;;
  (?*.c) CHECK_SOURCE="\$(SOURCE)/$MODULE_DIR/$2"; shift;;
  esac
  shift

  CHECK_OBJECT="\$(TARGET)/test/$MODULE/obj/$CHECK_NAME.o"
  CHECK_GENSRC="\$(TARGET)/test/$MODULE/src/$CHECK_NAME.check.c"
  CHECK_GENOBJ="\$(TARGET)/test/$MODULE/obj/$CHECK_NAME.check.o"
  CHECK_BINARY="\$(TARGET)/test/$MODULE/bin/$CHECK_NAME"
  CHECK_DEPDIR="\$(TARGET)/make/test/$MODULE"
  CHECK_DEPEND="$CHECK_DEPDIR/make$CHECK_NAME.a"
  CHECK_SCRIPT="\$(SOURCE)/src/check/checkgen.awk"

  # Rule to compile test functions
  cc_target "$CHECK_OBJECT" "$CHECK_SOURCE"
    CC_object $CHECK_OBJECT "$CHECK_SOURCE" "$@"

  # Rule for generated source and function stubs
  new_target $CHECK_GENSRC $CHECK_OBJECT $CHECK_SCRIPT
    NM -PA $CHECK_OBJECT \| awk -f $CHECK_SCRIPT '>$@'

  # Rule to build generated source
  cc_target $CHECK_GENOBJ $CHECK_GENSRC
    CC_object $CHECK_GENOBJ $CHECK_GENSRC

  # Rule to link the test executable
  ld_target "$CHECK_BINARY" \
    "$CHECK_OBJECT" "$CHECK_GENOBJ " \
    "\$(TARGET)/lib/lib$MODULE.a" "\$(TARGET)/lib/libcheck.a" \
    "$CHECK_DEPDIR\$D"

    # Add source dependencies to archive
    AR "$CHECK_DEPEND" "${CHECK_OBJECT%.o}.d" "${CHECK_GENOBJ%.o}.d"

    # Link test executable
    LD \
      -o "\"$CHECK_BINARY"\" \
      "\"$CHECK_OBJECT"\" \
      "\"$CHECK_GENOBJ"\" \
      -lcheck \
      -l$MODULE
}
