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

  build_bin_target \
    "$CHECK_BINARY" \
    "$CHECK_SOURCE" \
    "$LIBRARY" \
    "$TARGET_LIBRARY_DIR/libcheck.a"

  build_object_recipe "$CHECK_OBJECT" "$CHECK_SOURCE" "$@"

  # Add source dependencies to archive
  build_ar_recipe "$CHECK_DEPEND" "${CHECK_OBJECT%.o}.d"

  # Generate stubs and test list based on which symbols were defined
  build_sh_recipe \
    '$(NM)' -PA $CHECK_OBJECT \| \
    awk -f $BUILD_SOURCE_DIR/check/checkgen.awk \
    \>$CHECK_GENSRC

  # Compile generated source
  build_cc_recipe -c "$CHECK_GENSRC" -o "$CHECK_GENOBJ"

  # Link test executable
  build_ld_recipe \
    -o "\"$CHECK_BINARY"\" \
    "\"$CHECK_OBJECT"\" \
    "\"$CHECK_GENOBJ"\" \
    -lcheck \
    -l$MODULE

  # Remove temporary files
  build_rm_recipe \
    "$CHECK_OBJECT" \
    "${CHECK_OBJECT%.o}.d" \
    "$CHECK_GENSRC" \
    "$CHECK_GENOBJ"

  build_end_target
}
