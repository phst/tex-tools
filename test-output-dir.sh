#!/bin/bash
#
# This is free and unencumbered software released into the public domain.
# 
# Anyone is free to copy, modify, publish, use, compile, sell, or distribute
# this software, either in source code form or as a compiled binary, for any
# purpose, commercial or non-commercial, and by any means.
# 
# In jurisdictions that recognize copyright laws, the author or authors of this
# software dedicate any and all copyright interest in the software to the
# public domain.  We make this dedication for the benefit of the public at
# large and to the detriment of our heirs and successors.  We intend this
# dedication to be an overt act of relinquishment in perpetuity of all present
# and future rights to this software under copyright law.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
# For more information, please refer to <http://unlicense.org/>.

# This script file checks whether SyncTeX and the filename recorder work in
# conjunction with a non-standard output directory.  It is intended for use
# with TeX Live 2010.

set -e
shopt -u nullglob

programs=(tex etex pdftex xetex luatex)

declare -i passed=0
declare -i failed=0

export program mode test_name

skip_test() {
    echo "SKIP: $program, $1"
}

pass_test() {
    echo "PASS: $program, $mode, $test_name"
    passed+=1
}

fail_test() {
    echo "FAIL: $program, $mode, $test_name"
    failed+=1
}

fail_subtest() {
    echo "FAIL: $program, $mode, $test_name, $1"
    success=0
}

export root_dir="$(mktemp -d -t tmp)"
export input_dir="$root_dir/input"
export output_dir="$root_dir/output"
export input_file=test.tex

code='\ifx\null\undefined\expandafter\dump\else\null\bye\fi'
flags=(--interaction=batchmode --output-directory=output --recorder)

mkdir -p "$input_dir" "$output_dir"

cd "$root_dir"
echo "Working directory: $PWD"

echo "$code" > "input/$input_file"
chmod -R a-w input
chmod a-w .

run_program() {
    rm -f output/*
    test_name=compilation
    local synctex_flags
    [[ $synctex == 1 ]] && synctex_flag='--synctex=-1' || synctex_flag=''
    "$program" "${flags[@]}" "$synctex_flag" "$@" > /dev/null && pass_test || fail_test
}

check_files() {
    # Test whether protocol, recorder and SyncTeX files are present
    test_name=log_file
    [[ -r output/test.log ]] && pass_test || fail_test
    test_name=recorder_file
    [[ -r output/test.fls ]] && pass_test || fail_test
    if [[ $synctex == 1 ]]
    then
        test_name=synctex_file
        [[ -r output/test.synctex ]] && pass_test || fail_test
    else
        skip_test 'SyncTeX not supported for this engine'
    fi
}

check_recorder() {
    # Test whether files recorded in the recorder file are present
    test_name=recorder_contents
    (
        set -e
        success=1
        [[ -r output/test.fls ]] || exit 1
        while read -r command argument
        do
            case "$command" in
                PWD)
                    cd "$argument" || fail_subtest "$command $argument" ;;
                INPUT|OUTPUT)
                    [[ -f "$argument" ]] || fail_subtest "$command $argument" ;;
            esac
        done < output/test.fls
        exit "$((1 - $success))"
    ) && pass_test || fail_test
}

check_synctex() {
    # Test whether files recorded in the SyncTeX file are accessible from within the output directory
    if [[ $synctex == 1 ]]
    then
        test_name=synctex_contents
        (
            set -e
            cd output
            [[ -r test.synctex ]] || exit 1
            success=1
            IFS=':'
            while read -r command number argument
            do
                if [[ $command == Input ]]
                then
                    [[ -f "$argument" ]] || fail_subtest "$command $argument"
                fi
            done < test.synctex
            exit "$((1 - $success))"
        ) && pass_test || fail_test
    else
        skip_test 'SyncTeX not supported for this engine'
    fi
}

check_format() {
    # Test whether a format was generated
    test_name=format
    [[ -r output/test.fmt ]] && pass_test || fail_test
}

run_tests() {
    synctex=0
    mode=ini
    run_program --ini "input/$input_file"
    check_files
    check_recorder
    check_format
    # The original "tex" program is the only one not to support SyncTeX
    [[ $program != tex ]] && synctex=1
    mode=file
    run_program "input/$input_file"
    check_files
    check_recorder
    check_synctex
    mode=cmdline
    # Executing code on the command line is non-deterministic without providing
    # an explicit job name
    run_program --jobname=test "$code"
    check_files
    check_recorder
    check_synctex
}

for program in "${programs[@]}"
do
    if which "$program" > /dev/null
    then
        run_tests
    else
        skip_test 'program not found'
    fi
done

echo "$passed tests passed, $failed tests failed"
exit "$((failed > 0))"
