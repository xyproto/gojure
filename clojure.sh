#!/usr/bin/env bash

# Clojure script, from the Clojure project

# Version = 1.10.1.502

set -e

function join { local d=$1; shift; echo -n "$1"; shift; printf "%s" "${@/#/$d}"; }

# Extract opts
print_classpath=false
describe=false
verbose=false
trace=false
force=false
repro=false
tree=false
pom=false
resolve_tags=false
help=false
jvm_opts=()
resolve_aliases=()
classpath_aliases=()
jvm_aliases=()
main_aliases=()
all_aliases=()
while [ $# -gt 0 ]
do
  case "$1" in
    -J*)
      jvm_opts+=("${1:2}")
      shift
      ;;
    -R*)
      resolve_aliases+=("${1:2}")
      shift
      ;;
    -C*)
      classpath_aliases+=("${1:2}")
      shift
      ;;
    -O*)
      jvm_aliases+=("${1:2}")
      shift
      ;;
    -M*)
      main_aliases+=("${1:2}")
      shift
      ;;
    -A*)
      all_aliases+=("${1:2}")
      shift
      ;;
    -Sdeps)
      shift
      deps_data="${1}"
      shift
      ;;
    -Scp)
      shift
      force_cp="${1}"
      shift
      ;;
    -Spath)
      print_classpath=true
      shift
      ;;
    -Sverbose)
      verbose=true
      shift
      ;;
    -Strace)
      trace=true
      shift
      ;;
    -Sdescribe)
      describe=true
      shift
      ;;
    -Sforce)
      force=true
      shift
      ;;
    -Srepro)
      repro=true
      shift
      ;;
    -Stree)
      tree=true
      shift
      ;;
    -Spom)
      pom=true
      shift
      ;;
    -Sresolve-tags)
      resolve_tags=true
      shift
      ;;
    -S*)
      echo "Invalid option: $1"
      exit 1
      ;;
    -h|--help|"-?")
      if [[ ${#main_aliases[@]} -gt 0 ]] || [[ ${#all_aliases[@]} -gt 0 ]]; then
        break
      else
        help=true
        shift
      fi
      ;;
    *)
      break
      ;;
  esac
done

# Find java executable
set +e
JAVA_CMD=./gojure
set -e
if [[ ! -n "$JAVA_CMD" ]]; then
  if [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
    JAVA_CMD="$JAVA_HOME/bin/java"
  else
    >&2 echo "Couldn't find 'java'. Please set JAVA_HOME."
    exit 1
  fi
fi

if "$help"; then
  cat <<-END
	Version: 1.10.1.502

	Usage: clojure [dep-opt*] [init-opt*] [main-opt] [arg*]
	       clj     [dep-opt*] [init-opt*] [main-opt] [arg*]

	The clojure script is a runner for Clojure. clj is a wrapper
	for interactive repl use. These scripts ultimately construct and
	invoke a command-line of the form:

	java [java-opt*] -cp classpath clojure.main [init-opt*] [main-opt] [arg*]

	The dep-opts are used to build the java-opts and classpath:
	 -Jopt          Pass opt through in java_opts, ex: -J-Xmx512m
	 -Oalias...     Concatenated jvm option aliases, ex: -O:mem
	 -Ralias...     Concatenated resolve-deps aliases, ex: -R:bench:1.9
	 -Calias...     Concatenated make-classpath aliases, ex: -C:dev
	 -Malias...     Concatenated main option aliases, ex: -M:test
	 -Aalias...     Concatenated aliases of any kind, ex: -A:dev:mem
	 -Sdeps EDN     Deps data to use as the last deps file to be merged
	 -Spath         Compute classpath and echo to stdout only
	 -Scp CP        Do NOT compute or cache classpath, use this one instead
	 -Srepro        Ignore the ~/.clojure/deps.edn config file
	 -Sforce        Force recomputation of the classpath (don't use the cache)
	 -Spom          Generate (or update existing) pom.xml with deps and paths
	 -Stree         Print dependency tree
	 -Sresolve-tags Resolve git coordinate tags to shas and update deps.edn
	 -Sverbose      Print important path info to console
	 -Sdescribe     Print environment and command parsing info as data
	 -Strace        Write a trace.edn file that traces deps expansion

	init-opt:
	 -i, --init path     Load a file or resource
	 -e, --eval string   Eval exprs in string; print non-nil values
	 --report target     Report uncaught exception to "file" (default), "stderr", or "none",
	                     overrides System property clojure.main.report

	main-opt:
	 -m, --main ns-name  Call the -main function from namespace w/args
	 -r, --repl          Run a repl
	 path                Run a script from a file or resource
	 -                   Run a script from standard input
	 -h, -?, --help      Print this help message and exit

	For more info, see:
	 https://clojure.org/guides/deps_and_cli
	 https://clojure.org/reference/repl_and_main
END
  exit 0
fi

# Set dir containing the installed files
install_dir=/usr/share/clojure
tools_cp="$install_dir/libexec/clojure-tools-1.10.1.502.jar"

# Execute resolve-tags command
if "$resolve_tags"; then
  if [[ -e deps.edn ]]; then
    "$JAVA_CMD" -classpath "$tools_cp" clojure.main -m clojure.tools.deps.alpha.script.resolve-tags "--deps-file=deps.edn"
    exit 0
  else
    echo "deps.edn does not exist"
    exit 1
  fi
fi

# Determine user config directory
if [[ -n "$CLJ_CONFIG" ]]; then
  config_dir="$CLJ_CONFIG"
elif [[ -n "$XDG_CONFIG_HOME" ]]; then
  config_dir="$XDG_CONFIG_HOME/clojure"
else
  config_dir="$HOME/.clojure"
fi

# If user config directory does not exist, create it
if [[ ! -d "$config_dir" ]]; then
  mkdir -p "$config_dir"
fi
if [[ ! -e "$config_dir/deps.edn" ]]; then
  cp "$install_dir/example-deps.edn" "$config_dir/deps.edn"
fi

# Determine user cache directory
if [[ -n "$CLJ_CACHE" ]]; then
  user_cache_dir="$CLJ_CACHE"
elif [[ -n "$XDG_CACHE_HOME" ]]; then
  user_cache_dir="$XDG_CACHE_HOME/clojure"
else
  user_cache_dir="$config_dir/.cpcache"
fi

# Chain deps.edn in config paths. repro=skip config dir
config_project="deps.edn"
if "$repro"; then
  config_paths=("$install_dir/deps.edn" "deps.edn")
else
  config_user="$config_dir/deps.edn"
  config_paths=("$install_dir/deps.edn" "$config_dir/deps.edn" "deps.edn")
fi
config_str=$(printf ",%s" "${config_paths[@]}")
config_str=${config_str:1}

# Determine whether to use user or project cache
if [[ -f deps.edn ]]; then
  cache_dir=.cpcache
else
  cache_dir="$user_cache_dir"
fi

# Construct location of cached classpath file
val="$(join '' ${resolve_aliases[@]})|$(join '' ${classpath_aliases[@]})|$(join '' ${all_aliases[@]})|$(join '' ${jvm_aliases[@]})|$(join '' ${main_aliases[@]})|$deps_data"
for config_path in "${config_paths[@]}"; do
  if [[ -f "$config_path" ]]; then
    val="$val|$config_path"
  else
    val="$val|NIL"
  fi
done
ck=$(echo "$val" | cksum | cut -d" " -f 1)

libs_file="$cache_dir/$ck.libs"
cp_file="$cache_dir/$ck.cp"
jvm_file="$cache_dir/$ck.jvm"
main_file="$cache_dir/$ck.main"

# Print paths in verbose mode
if "$verbose"; then
  echo "version      = 1.10.1.502"
  echo "install_dir  = $install_dir"
  echo "config_dir   = $config_dir"
  echo "config_paths =" "${config_paths[@]}"
  echo "cache_dir    = $cache_dir"
  echo "cp_file      = $cp_file"
  echo
fi

# Check for stale classpath file
stale=false
if "$force" || "$trace" || [ ! -f "$cp_file" ]; then
  stale=true
else
  for config_path in "${config_paths[@]}"; do
    if [ "$config_path" -nt "$cp_file" ]; then
      stale=true
      break
    fi
  done
fi

# Make tools args if needed
if "$stale" || "$pom"; then
  tools_args=()
  if [[ -n "$deps_data" ]]; then
    tools_args+=("--config-data" "$deps_data")
  fi
  if [[ ${#resolve_aliases[@]} -gt 0 ]]; then
    tools_args+=("-R$(join '' ${resolve_aliases[@]})")
  fi
  if [[ ${#classpath_aliases[@]} -gt 0 ]]; then
    tools_args+=("-C$(join '' ${classpath_aliases[@]})")
  fi
  if [[ ${#jvm_aliases[@]} -gt 0 ]]; then
    tools_args+=("-J$(join '' ${jvm_aliases[@]})")
  fi
  if [[ ${#main_aliases[@]} -gt 0 ]]; then
    tools_args+=("-M$(join '' ${main_aliases[@]})")
  fi
  if [[ ${#all_aliases[@]} -gt 0 ]]; then
    tools_args+=("-A$(join '' ${all_aliases[@]})")
  fi
  if [[ -n "$force_cp" ]]; then
    tools_args+=("--skip-cp")
  fi
  if "$trace"; then
    tools_args+=("--trace")
  fi
fi

# If stale, run make-classpath to refresh cached classpath
if [[ "$stale" = true && "$describe" = false ]]; then
  if "$verbose"; then
    echo "Refreshing classpath"
  fi

  "$JAVA_CMD" -classpath "$tools_cp" clojure.main -m clojure.tools.deps.alpha.script.make-classpath2 --config-user "$config_user" --config-project "$config_project" --libs-file "$libs_file" --cp-file "$cp_file" --jvm-file "$jvm_file" --main-file "$main_file" "${tools_args[@]}"
fi

if "$describe"; then
  cp=
elif [[ -n "$force_cp" ]]; then
  cp="$force_cp"
else
  cp=$(cat "$cp_file")
fi

if "$pom"; then
  exec "$JAVA_CMD" -classpath "$tools_cp" clojure.main -m clojure.tools.deps.alpha.script.generate-manifest2 --config-user "$config_user" --config-project "$config_project" --gen=pom "${tools_args[@]}"
elif "$print_classpath"; then
  echo "$cp"
elif "$describe"; then
  for config_path in "${config_paths[@]}"; do
    if [[ -f "$config_path" ]]; then
      path_vector="$path_vector\"$config_path\" "
    fi
  done
  cat <<-END
	{:version "1.10.1.502"
	 :config-files [$path_vector]
	 :config-user "$config_user"
	 :config-project "$config_project"
	 :install-dir "$install_dir"
	 :config-dir "$config_dir"
	 :cache-dir "$cache_dir"
	 :force $force
	 :repro $repro
	 :resolve-aliases "$(join '' ${resolve_aliases[@]})"
	 :classpath-aliases "$(join '' ${classpath_aliases[@]})"
	 :jvm-aliases "$(join '' ${jvm_aliases[@]})"
	 :main-aliases "$(join '' ${main_aliases[@]})"
	 :all-aliases "$(join '' ${all_aliases[@]})"}
END
elif "$tree"; then
  exec "$JAVA_CMD" -classpath "$tools_cp" clojure.main -m clojure.tools.deps.alpha.script.print-tree --libs-file "$libs_file"
elif "$trace"; then
  echo "Writing trace.edn"
else
  set -f
  if [[ -e "$jvm_file" ]]; then
    jvm_cache_opts=($(cat "$jvm_file"))
  fi
  if [[ -e "$main_file" ]]; then
    main_cache_opts=($(cat "$main_file"))
  fi
  exec "$JAVA_CMD" "${jvm_cache_opts[@]}" "${jvm_opts[@]}" "-Dclojure.libfile=$libs_file" -classpath "$cp" clojure.main "${main_cache_opts[@]}" "$@"
fi
