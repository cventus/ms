#!/bin/sh
set -e

# Short-hand functions for defining rules
target_generic() { printf '%s: ' "$1"; shift; echo "$*"; }
target_phony() { target_generic .PHONY "$*"; }
target_source() { target_generic "\$(TARGET)/src/$MODULE/$@"; }
target_include() { target_generic "\$(TARGET)/include/$@"; }
target_cc() { target_generic "$@" "\$(HEADERS.$MODULE)"; }
target_ld() { target_generic "$@" "\$(LIBRARIES.$MODULE)"; }
end_target() { printf '\n'; }

# Functions for adding rule commands
sh_cmd() { printf '\t%s\n' "$*"; }
ar_cmd() { sh_cmd '$(AR)' -rc "$*"; }

# Output command to compile a single source file (add neccessary compilation
# and preprocessor flags).
# Usage: cc_cmd <cc args>...
cc_cmd() {
  sh_cmd "\$(CC) \$(CFLAGS) \$(CFLAGS.$MODULE)" \
    "\$(CPPFLAGS) \$(CPPFLAGS.$MODULE) $INCLUDE_FLAGS $*"
}

# Output command to compile a single source file (add neccessary compilation
# and preprocessor flags) and generate makefile rules at the specified path at
# the same time.
# Usage: ccmk_cmd <makefile rules path> <cc args>...
ccmk_cmd() { cc_cmd "$DEPEND_FLAGS" "$@"; }

# Output command to compile and link a single source file (add neccessary
# linkage flags).
# Usage: ld_cmd <cc args>...
ld_cmd() {
  sh_cmd "\$(CC) \$(CFLAGS) \$(CFLAGS.$MODULE)" \
    "-L\$(TARGET)/lib \$(LDFLAGS) \$(LDFLAGS.$MODULE)" \
    "$* \$(LDLIBS.$MODULE) \$(LDLIBS)"
}

# Output command to compile a source file into an object with optional extra
# compiler flags (with default compilation flags) and generate makefile rules
# in the same directory as the object file (with a ".d" appended to the
# object's path name.
# Usage: object_cmd <target object> <source file> [<cc args>...]
object_cmd() {
  object_cmd_obj_="$1"
  shift 1
  ccmk_cmd "${object_cmd_obj_%.o}.d" -o "$object_cmd_obj_" -c "$@"
}

# Output a makefile rule to compile an object for a module.
# Usage: define_object <object> <source> [<cc flags> ...]
define_object() {
  OBJECTS="$OBJECTS $1"
  define_object_obj_="\$(TARGET)/obj/$MODULE/$1"
  define_object_src_="\$(SOURCE)/$MODULE_DIR/$2"
  shift 2

  target_cc "$define_object_obj_" "$define_object_src_"
    object_cmd "$define_object_obj_" "$define_object_src_" "$@"
  end_target
}

define_binary() {
  target_generic "all $MODULE" "\$(TARGET)/bin/${1:-$MODULE}"

  if [ "$1" -a "$1" != "$MODULE" ]; then
    target_generic "$1" "\$(TARGET)/bin/$1"
    target_phony "$1"
  fi

  target_ld "\$(TARGET)/bin/${1:-$MODULE}" "\$(TARGET)/lib/lib$MODULE.a"
    ld_cmd "\$(TARGET)/lib/lib$MODULE.a" -o "\$(TARGET)/bin/${1:-$MODULE}"
  end_target
}

build_read_config() {
  if [ -f "$BUILD_CONFIG" ]; then . "$BUILD_CONFIG"; fi
  if [ -z "$MODULES" ]; then
    echo "MODULES not defined in environment or $BUILD_CONFIG" >&2
    exit 1
  fi

  readonly TARGET="${TARGET:=target}" INCLUDE="${INCLUDE:=include}"
  readonly MODULES DEPEND_FLAGS='-MMD -MP -MT $@ -MF' INCLUDE_FLAGS="\
-I\$(TARGET)/include\
${INCLUDE:+$(printf ' -I$(SOURCE)/%s' $INCLUDE)}"
}

# Called in context of a module where CFLAGS, CPPFLAGS, LDFLAGS and LDLIBS are
# module specific
build_module_variables() {
  printf 'CFLAGS.%s = %s\n' "$MODULE" "$CFLAGS"
  printf 'CPPFLAGS.%s = %s\n' "$MODULE" "$CPPFLAGS"
  printf 'LIBRARIES.%s =' "$MODULE"
  if [ "$REQUIRE" ]; then
    printf ' $(TARGET)/lib/lib%s.a' $REQUIRE
    printf ' $(LIBRARIES.%s)' $REQUIRE
  fi
  printf '\n'
  printf 'LDFLAGS.%s = %s' "$MODULE" "$LDFLAGS"
  if [ "$REQUIRE" ]; then printf ' $(LDFLAGS.%s)' $REQUIRE; fi
  printf '\n'
  printf 'LDLIBS.%s = %s' "$MODULE" "$LDLIBS"
  if [ "$REQUIRE" ]; then
    printf ' -l%s' $REQUIRE
    printf ' $(LDLIBS.%s)' $REQUIRE
  fi
  printf '\n'
}

build_module_generated_headers() {
  printf 'HEADERS.%s =' "$MODULE"
  [ "$HEADERS" ] && printf ' $(TARGET)/include/%s' $HEADERS
  [ "$REQUIRE" ] && printf ' $(HEADERS.%s)' $REQUIRE
  printf '\n'
}

globexists() { test -f "$1"; }

build_module_targets() {
  # The default behavior when the module configuration defines neither sources
  # nor objects is to treat all source files in MODULE_DIR as source files,
  # which is convenient for small modules without even a module configuration.
  if [ ! "$SOURCES$OBJECTS" ] && globexists *.c; then SOURCES=*.c; fi
  for S in $SOURCES; do define_object "$(basename $S .c).o" $S; done

  if [ "$OBJECTS" ]; then
    printf 'OBJECTS.%s =' "$MODULE"
    printf '\\\n $(TARGET)/obj/'"$MODULE"'/%s' $OBJECTS
    echo
  fi

  # $1 = library path
  set "\$(TARGET)/lib/lib$MODULE.a"
  target_generic "all" "$1"
  target_generic "$1" "\$(OBJECTS.$MODULE)" '$(TARGET)/make$D'
    sh_cmd rm -f "$1" "\$(TARGET)/make/make$MODULE.a"
    ar_cmd -s "$1" "\$(OBJECTS.$MODULE)"
    ar_cmd "\$(TARGET)/make/make$MODULE.a" "\$(OBJECTS.$MODULE:.o=.d)"
  end_target
}

# Added first as-is to output makefile
build_makefile_header() {
  target_generic all
  target_generic clean \; find "$TARGET" -type f -exec rm -- {} '\;'
  target_phony all clean

  echo
  echo "SOURCE = $SOURCE"
  echo "TARGET = $TARGET"
  echo "D = /$DIRECTORY_TARGET_FILE"
  echo
  echo "CFLAGS = $CFLAGS"
  echo "CPPFLAGS = $CPPFLAGS"
  echo "LDFLAGS = $LDFLAGS"
  echo "LDLIBS = $LDLIBS"
  echo
}

build_module_rules() {
  echo
  # Produce all normal rules (each ``module.sh'' file evaluated in an
  # independent sub-shell)
  for MODULE_DIR in $MODULES; do (
    require() { REQUIRE="$REQUIRE $*"; }
    readonly MODULE_DIR MODULE=$(basename $MODULE_DIR)
    cd "$SOURCE/$MODULE_DIR"
    unset CFLAGS CPPFLAGS LDFLAGS LDLIBS
    unset SOURCES OBJECTS HEADERS REQUIRE
    if [ -f module.sh ]; then . ../$MODULE/module.sh; fi
    for C in $MODULE_COMMANDS; do $C; done
  ); done
}

build_depend_rules() {
  # Include source header dependencies
  if [ -d "$TARGET/make" ]; then
    find "$TARGET/make"  -name 'make*.a' -exec $AR -p {} \;
  fi
}

# Print entire generated makefile to standard output
build_makefile() {
  build_makefile_header

  for C in $MAKEFILE_COMMANDS; do $C; done | LC_ALL=C awk '
  # Save all lines in a buffer and also expand escaped lines
  { buffer[n++] = $0; m++; line = line substr($0, 1, length($0) - /\\$/); }

  /^$/ || /[^\\]$/ {
    if (line !~ /^\t/) {
      sub(/#.*$/, "", line)
      gsub(/\$[{(][^{($:]*:[^({$})=]*=[^({$})]*[)}]/, "", line)
      if (line ~ /^[^:=]{1,}=/) { # variable definition
        n -= m
        for (i = 0; i < m; i++) { print buffer[n + i]; }
      } else if (line ~ /[^:]{1,}:/) { # rule definition
        m = split(line, targets, /[ \t:]{1,}/)
        for (i = 1; i <= m; i++) {
          target = targets[i]
          while (target ~ /\$[({]TARGET[^})]*[})]\/./) {
            parent_dir = target
            sub(/\/[^\/]*$/, "", parent_dir)
            target_dirs[target] = parent_dir "$D"
            target = parent_dir "$D"
          }
        }
      }
    }
    m = 0;
    line = "";
  }

  END {
    for (i = 0; i < n; i++) { print buffer[i]; }
    if (length(parent_dir) > 0) {
      for (t in target_dirs) {
        if (t ~ /\$D$/) printf("\n%s \\", t) | "sort | uniq"
        printf("\n%s \\", target_dirs[t]) | "sort | uniq"
      }
      close("sort | uniq")
      printf(":\n\ttest -d $(@D) || mkdir $(@D)\n\ttouch $@\n\n")
      for (t in target_dirs) printf("%s: %s\n", t, target_dirs[t]) | "sort"
      close("sort")
    }
  }'
}

build_targets() {
  awk -v target_dir="$TARGET" -v filter_string="$1" '
  function is_target(target,    i) {
    for (i = 1; i <= nfilters; i++) { if (target ~ filters[i]) return 1; }
    return nfilters == 0
  }

  BEGIN {
    nfilters = (length(filter_string) > 0 ?
       split(filter_string, filters, /[[:space:]]{1,}/) : 0)
  }

  { line = line substr($0, 1, length($0) - /\\$/); }

  /[^\\]$/ {
    if (line !~ /^\t/) {
      sub(/#.*$/, "", line)
      gsub(/\$[{(][^{($:]*:[^({$})=]*=[^({$})]*[)}]/, "", line)
      if (line ~ /[^:=]{1,}:/) {
        n = split(line, targets, /[ \t:]{1,}/)
        for (i = 1; i <= n; i++) {
	  target = targets[i]
          if (target ~ /^\$[({]TARGET[})]/ && target !~ /\$D$/) {
	    sub(/^\$[({]TARGET[})]/, target_dir, target)
            if (is_target(target)) print target
          }
        }
      }
    }
    line = "";
  }' | LC_ALL=C sort | uniq
}

MAKE_ARGUMENTS=; SHOW_TARGETS=; MAKE_TARGETS=;
i=1
# Remove phony targets like "show:foo" or "make:bar" from "$@" and store in
# SHOW_TARGETS and MAKE_TARGETS
for ARG; do
  case "$ARG" in
  show:*) SHOW_TARGETS="$SHOW_TARGETS ${ARG#show:}";;
  make:*) MAKE_TARGETS="$MAKE_TARGETS ${ARG#make:}";;
  *) MAKE_ARGUMENTS="$MAKE_ARGUMENTS \"\${$i}\"";;
  esac
  i=$((i + 1))
done
eval "set -- $MAKE_ARGUMENTS"
for ARG; do
  case "$ARG" in
  CFLAGS=*|CPPFLAGS=*|LDFLAGS=*|LDLIBS=*|TARGET=*|SOURCE=*|BUILD_CONFIG=*|AR=*)
    export "$ARG";;
  esac
done
unset i ARG MAKE_ARGUMENTS

: ${BUILD_CONFIG:=${SOURCE:-.}/build.conf} ${AR:=ar}
readonly SHOW_TARGETS MAKE_TARGETS
readonly BUILD_CONFIG SOURCE=$(dirname "$BUILD_CONFIG")
readonly DIRECTORY_TARGET_FILE=.dir
export CFLAGS CPPFLAGS LDFLAGS LDLIBS

MAKEFILE_COMMANDS="\
build_module_rules
build_depend_rules
"

MODULE_COMMANDS="\
build_module_variables
build_module_generated_headers
build_module_targets
"

build_read_config
readonly MAKEFILE=$(build_makefile)

# Either run make or show Makefile
if [ "$MAKE_TARGETS" -o ! "$SHOW_TARGETS" ]; then
  echo "$MAKEFILE" | ${MAKE:-make} -rf- "$@" \
    $(if [ "$MAKE_TARGETS" ]; then
      echo "$MAKEFILE" | build_targets "${MAKE_TARGETS# }"
    fi)
else
  for ARG in $SHOW_TARGETS; do
    case "$ARG" in
    Makefile) echo "$MAKEFILE";;
    targets) echo "$MAKEFILE" | build_targets;;
    *) >&2 echo "$0: Unknown show option \"$ARG\""; exit 1;;
    esac
  done
fi
