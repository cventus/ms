HEADERS=rational.h

cpp_macros() {
  echo "-D TYPE=\"$1\" -D UTYPE=\"$2\" -D TYPE_PFX=\"$3\" -D UTYPE_MAX=\"$4\""
}

specialize_object() {
  define_object "${3}rat.o" rat.c $(cpp_macros "$@")
}

specialize_header() {
  new_target "\$(TARGET)/src/$MODULE/${3}rat.h" "\$(SOURCE)/$MODULE_DIR/rat.h"
  cc_cmd -E -C $(cpp_macros "$@") "\$(SOURCE)/$MODULE_DIR/rat.h" '>"$@"'
}

# List integer types on fd 3
exec 3<<EOF # signed:unsigned:mangle:max
int:unsigned int::UINT_MAX
long:unsigned long:l:ULONG_MAX
long long:unsigned long long:ll:ULLONG_MAX
EOF

# Generate object and header for each integer type
while IFS=: read -r TYPE UTYPE TYPE_PFX UTYPE_MAX <&3; do
  set -- "$TYPE" "$UTYPE" "$TYPE_PFX" "$UTYPE_MAX"
  specialize_object "$@"
  specialize_header "$@"
done

# Close fd 3
exec 3<&-

new_target "\$(TARGET)/include/rational.h" \
  $(printf " \$(TARGET)/src/$MODULE/%srat.h" "" l ll)

# Recipe for composing header from parts
sh_cmd \
  "sed -n '/begin public rat.h/,/end public rat.h/p'" \
  "$(printf " \$(TARGET)/src/$MODULE/%srat.h" "" l ll)" \| \
  "sed '/\\(begin\\|end\\) public rat.h/d'" \| \
  "cat \$(SOURCE)/$MODULE_DIR/prolog.h - \$(SOURCE)/$MODULE_DIR/epilog.h" \
  '>$@'
