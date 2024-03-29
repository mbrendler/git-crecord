#! /usr/bin/env bash

set -euo pipefail

function assert-equal() {
  local expected=$1
  local actual=$2
  if test "$expected" != "$actual" ; then
    cat << EOF
expect:
$expected
but got:
$actual
EOF
    cat << 'EOF'
 ____             _
|  _ \ __ _ _ __ (_) ___
| |_) / _` | '_ \| |/ __|
|  __/ (_| | | | | | (__
|_|   \__,_|_| |_|_|\___|
EOF
    exit 1
  fi
}

function assert-diff(){
  local expected=$1
  assert-equal "$expected" "$(git diff | grep '^[+-][^+-]')"
}

function assert-status() {
  local expected=$1
  assert-equal "$expected" "$(git status -s)"
}

function run-git-crecord() {
  local keys=$1
  "$EXECUTABLE" -u "$@" <<<"$keys"
}

function run-git-crecord-reverse() {
  local keys=$1
  "$EXECUTABLE" -R <<<"$keys"
}

readonly HERE="$(dirname "$(readlink -m "${BASH_SOURCE[0]}")")"
readonly TEST_DIR=$HERE/tmp/__test__
readonly EXECUTABLE=$HERE/bin/git-crecord
readonly REPO_DIR=$TEST_DIR/repo

rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"

git init "$REPO_DIR" > /dev/null

pushd "$REPO_DIR" > /dev/null

touch a_file.txt

git add a_file.txt
git ci -m 'add a_file.txt' > /dev/null

cat > a_file.txt << 'EOF'
This is line 1.
This is the second line.
This is line 3.
This is line 4.
EOF


echo "add all -----------------------------------------------------------------"
run-git-crecord "s"
assert-diff ""

git reset > /dev/null

echo "add first line ----------------------------------------------------------"
run-git-crecord " ljj s"
assert-diff "+This is the second line.
+This is line 3.
+This is line 4."

git reset > /dev/null

echo "add another line --------------------------------------------------------"
run-git-crecord " ljjjj s"
assert-diff "+This is line 1.
+This is the second line.
+This is line 4."


git ci -a -m "add some lines" > /dev/null

sed -i '' '1,3d' a_file.txt

echo "delete all lines --------------------------------------------------------"
run-git-crecord "s"
assert-diff ""

git reset > /dev/null

echo "delete one line ---------------------------------------------------------"
run-git-crecord " ljjj s"
assert-diff "-This is line 1.
-This is line 3."

git reset --hard > /dev/null

# add some more lines:
cat >> a_file.txt << 'EOF'

This is line 5.
This is line 6.
This is line 7.
This is line 8.
This is line 9.

This is line 10.
This is line 11.
This is line 12.
EOF
git ci -a -m "add some more lines" > /dev/null

sed -i '' '2s/.*/This is line 2./' a_file.txt
sed -i '' '12s/.*/This is the tenth line./' a_file.txt
sed -i '' '13s/.*/This is the eleventh line./' a_file.txt

echo "multiple hunks ----------------------------------------------------------"
run-git-crecord "s"
assert-diff ""

git reset > /dev/null

echo "add lines of second hunk ------------------------------------------------"
run-git-crecord " ljjjj sq "
assert-diff "-This is the second line.
+This is line 2."

git reset > /dev/null

echo "add some lines of all hunks ---------------------------------------------"
run-git-crecord " ljjj jj jj j s"
assert-diff "-This is the second line.
-This is line 11."

git reset > /dev/null

echo "run git-crecord in a subdirectory directory -----------------------------"
mkdir -p "$REPO_DIR"/sub/sub2
pushd "$REPO_DIR"/sub > /dev/null
run-git-crecord "s"
assert-diff ""
popd > /dev/null # "$REPO_DIR"/sub

git reset > /dev/null

echo "add a untracked file ----------------------------------------------------"
echo "b_file line 1" > b_file.txt
run-git-crecord 'AG s'
git commit -m "add b_file" > /dev/null
assert-diff '-This is the second line.
+This is line 2.
-This is line 10.
-This is line 11.
+This is the tenth line.
+This is the eleventh line.'

echo "a not selected file -----------------------------------------------------"
echo "b_file line 2" >> b_file.txt
run-git-crecord "j s"
assert-diff "+b_file line 2"

echo "add untracked file from untracked directory -----------------------------"
echo "a line" > "$REPO_DIR/sub/sub2/sub-file.txt"
run-git-crecord "AG s"
assert-diff "+b_file line 2"
assert-status 'M  a_file.txt
 M b_file.txt
A  sub/sub2/sub-file.txt'

echo "test with +++ line ------------------------------------------------------"
echo "++++" >> b_file.txt
run-git-crecord "s"
assert-diff ""

echo "test unstage ------------------------------------------------------------"
echo new line1 > new.txt
echo new line2 >> new.txt
git add new.txt
run-git-crecord-reverse 'j k lj Gkljj s'
assert-status 'MM a_file.txt
M  b_file.txt
AM new.txt
?? sub/'
assert-diff '-This is the second line.
+This is line 2.
+new line2'

echo "test add empty files ----------------------------------------------------"
git add .
touch empty.txt
touch empty-untrached.txt
git add -N empty.txt
run-git-crecord 'AAs'
assert-status 'M  a_file.txt
M  b_file.txt
A  empty-untrached.txt
A  empty.txt
A  new.txt
A  sub/sub2/sub-file.txt'

echo "unstage empty file ------------------------------------------------------"
run-git-crecord-reverse 'AG s'
assert-status 'M  a_file.txt
M  b_file.txt
A  empty-untrached.txt
A  empty.txt
A  new.txt
?? sub/'

echo "move and modify file ----------------------------------------------------"
git reset --hard > /dev/null
git mv b_file.txt c_file.txt
echo another line > c_file.txt
run-git-crecord 's'
assert-status 'D  b_file.txt
A  c_file.txt
?? sub/'


popd > /dev/null # $REPO_DIR

cat << 'EOF'
  ___  _  __
 / _ \| |/ /
| | | | ' /
| |_| | . \
 \___/|_|\_\
EOF
