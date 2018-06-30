# Define NM if it wasn't
export NM=${NM:-nm}

# Define a test with an auto-generated main function which
# calls all functions named "test_*"
# CHECK [<name>] <source>.c [CC options]
CHECK()
{
  CHECK_SOURCE="$BUILD_SOURCE_DIR/$MODULE/$1"
  CHECK_NAME=$(basename "$CHECK_SOURCE" .c)
  case "$2" in
  (-*) ;;
  (?*.c) CHECK_SOURCE="$BUILD_SOURCE_DIR/$MODULE/$2"; shift;;
  esac
  shift
  CHECK_MKFILE="$TARGET_TEMP_DIR/$MODULE/test/$CHECK_NAME.d"
  CHECK_OBJECT="$TARGET_TEMP_DIR/$MODULE/test/$CHECK_NAME.o"
  CHECK_GENSRC="$TARGET_TEMP_DIR/$MODULE/test/${CHECK_NAME}_check.c"
  CHECK_GENOBJ="$TARGET_TEMP_DIR/$MODULE/test/${CHECK_NAME}_check.o"
  CHECK_BINARY="$TARGET_TEST_BINARY_DIR/$MODULE/$CHECK_NAME"

  printf '%s: %s %s %s\n' \
    "$CHECK_BINARY" \
    "$CHECK_SOURCE" \
    "$TARGET_LIBRARY_DIR/lib$MODULE.a" \
    "$TARGET_LIBRARY_DIR/libcheck.a"

  # Build object file of tests
  build_source_recipe "$@" \
    $(build_depend_flags "$CHECK_BINARY" "$CHECK_MKFILE") \
    -c "\"$CHECK_SOURCE\"" \
    -o "\"$CHECK_OBJECT\""

  # Test dependency information
  printf '\t$(AR) -rc "%s" "%s"\n' "$TEST_DEPEND" "$CHECK_MKFILE"

  # Generate stubs and test list based on which symbols were defined
  printf '\t$(NM) -PA "%s" | awk -f "%s" >"%s"\n' \
    "$CHECK_OBJECT" \
    "$BUILD_SOURCE_DIR/check/checkgen.awk" \
    "$CHECK_GENSRC"

  build_source_recipe -c "$CHECK_GENSRC" -o "$CHECK_GENOBJ"

  build_binary_recipe \
    -o "\"$CHECK_BINARY\"" \
    "\"$CHECK_OBJECT\"" \
    "\"$CHECK_GENOBJ\"" \
    -lcheck \
    -l$MODULE \
    "\$(MODULE_LDFLAGS.$MODULE)"

  printf '\trm "%s" "%s" "%s" "%s"\n' \
    "$CHECK_OBJECT" \
    "$CHECK_MKFILE" \
    "$CHECK_GENSRC" \
    "$CHECK_GENOBJ"

  printf '\ntest-%s: %s\n\n' "$MODULE" "$CHECK_BINARY"

  TEST "$CHECK_BINARY"
}
