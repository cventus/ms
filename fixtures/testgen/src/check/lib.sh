# Make NM available from environment by default
export NM=${NM:-nm}

# Define a test with an auto-generated main function which
# calls all functions named "test_*"
# addcheck [<name>] <source>.c [CC options]
addcheck()
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
  target_cc "$CHECK_OBJECT" "$CHECK_SOURCE"
    object_cmd $CHECK_OBJECT "$CHECK_SOURCE" "$@"
  end_target

  # Rule for generated source and function stubs
  target_generic $CHECK_GENSRC $CHECK_OBJECT $CHECK_SCRIPT
    sh_cmd '$(NM)' -PA $CHECK_OBJECT \| awk -f $CHECK_SCRIPT '>$@'
  end_target

  # Rule to build generated source
  target_cc $CHECK_GENOBJ $CHECK_GENSRC
    object_cmd $CHECK_GENOBJ $CHECK_GENSRC
  end_target

  # Rule to link the test executable
  target_ld "$CHECK_BINARY" \
    "$CHECK_OBJECT" "$CHECK_GENOBJ " \
    "\$(TARGET)/lib/lib$MODULE.a" "\$(TARGET)/lib/libcheck.a" \
    "$CHECK_DEPDIR\$D"

    # Add source dependencies to archive
    ar_cmd "$CHECK_DEPEND" "${CHECK_OBJECT%.o}.d" "${CHECK_GENOBJ%.o}.d"

    # Link test executable
    ld_cmd \
      -o "\"$CHECK_BINARY"\" \
      "\"$CHECK_OBJECT"\" \
      "\"$CHECK_GENOBJ"\" \
      -lcheck \
      -l$MODULE
  end_target
}
