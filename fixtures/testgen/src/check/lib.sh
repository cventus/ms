# Make NM available from environment by default
export NM=${NM:-nm}

# Define a test with an auto-generated main function which
# calls all functions named "test_*"
# addcheck [<name>] <source>.c [CC options]
addcheck()
{
  CHECK_SOURCE="$MODULE_DIR/$1"
  CHECK_NAME=$(basename "$CHECK_SOURCE" .c)
  case "$2" in
  (-*) ;;
  (?*.c) CHECK_SOURCE="$MODULE_DIR/$2"; shift;;
  esac
  shift
  CHECK_OBJECT="$TEST_TEMP_DIR/$CHECK_NAME.o"
  CHECK_GENSRC="$TEST_TEMP_DIR/${CHECK_NAME}_check.c"
  CHECK_GENOBJ="$TEST_TEMP_DIR/${CHECK_NAME}_check.o"
  CHECK_BINARY="$TEST_BIN_DIR/$CHECK_NAME"
  CHECK_DEPEND="$TARGET_DEPEND_DIR/mk-test-$MODULE-$CHECK_NAME.a"

  append TESTS "$CHECK_BINARY"

  target_bin \
    "$CHECK_BINARY" \
    "$CHECK_SOURCE" \
    "$LIBRARY" \
    "$TARGET_LIBRARY_DIR/libcheck.a"

  object_cmd "$CHECK_OBJECT" "$CHECK_SOURCE" "$@"

  # Add source dependencies to archive
  ar_cmd "$CHECK_DEPEND" "$CHECK_OBJECT.d"

  # Generate stubs and test list based on which symbols were defined
  sh_cmd \
    '$(NM)' -PA $CHECK_OBJECT \| \
    awk -f $BUILD_SOURCE_DIR/check/checkgen.awk \
    \>$CHECK_GENSRC

  # Compile generated source
  cc_cmd -c "$CHECK_GENSRC" -o "$CHECK_GENOBJ"

  # Link test executable
  ld_cmd \
    -o "\"$CHECK_BINARY"\" \
    "\"$CHECK_OBJECT"\" \
    "\"$CHECK_GENOBJ"\" \
    -lcheck \
    -l$MODULE

  # Remove temporary files
  rm_cmd \
    "$CHECK_OBJECT" \
    "$CHECK_OBJECT.d" \
    "$CHECK_GENSRC" \
    "$CHECK_GENOBJ"

  end_target
}
