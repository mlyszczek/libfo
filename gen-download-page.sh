#!/bin/sh

project='libfo'
out='www/downloads.html'
remote="https://distfiles.bofc.pl/${project}"
gpg="https://distfiles.bofc.pl/bofc-signing.pub.gpg"
asc="https://distfiles.bofc.pl/bofc-signing.pub.asc"

get_files_from_remote()
{
    remote="${1}"

    curl "${remote}/" -A "${project}-generator" 2>/dev/null | grep "a href=" | \
        grep -v 'a href=".."' | cut -f2 -d\" | cut -f1 -d/
}

# extract links to files
links="$(curl "${remote}/" -A "${project}-generator" 2>/dev/null \
    | grep "${project}-[0-9]*\.[0-9]*\.[0-9]*\." | sort -r)"

exec 6>&1
exec 1<>"${out}"

echo > "${out}"
echo "<h1 class=\"first\">downloads</h1>"
echo "<p>"
echo "Below you can find source files to download."
echo "<b>(s)</b> right of package name is a gpg signature. You can download"
echo "<a href=\"${gpg}\">gpg file</a> or"
echo "<a href=\"${asc}\">armored asc file</a> to verify files. You can also"
echo "look for key on public keyservers, fingerprint is<br><br>"
echo "&nbsp;&nbsp;&nbsp;&nbsp;63D0 C3DB 42AF 3B4F CF6E  7880 E84A 7E61 C785 0C62<br><br>"
echo "You can download key directly from keyserver with<br><br>"
echo "&nbsp;&nbsp;&nbsp;&nbsp;gpg --recv-keys 63D0C3DB42AF3B4FCF6E7880E84A7E61C7850C62<br><br>"
echo "Then you can verify downloaded image with command<br><br>"
echo "&nbsp;&nbsp;&nbsp;&nbsp;gpg --verify &lt;sig-file&gt; &lt;package-file&gt;"
echo "</p><p>"
echo "All files (including md5, sha256 and sha512 for all files) can also"
echo "be downloaded from: <a href=\"${remote}/\">${remote}</a><br>"
echo "</p>"
echo "<h1>git</h1>"
echo "<p>"
echo "git clone git@bofc.pl:${project}<br>"
echo "git clone git://bofc.pl/${project}<br>"
echo "git clone http://git.bofc.pl/${project}<br>"
echo "</p>"
echo "<h1>tarballs (source code)</h1>"
echo "<pre>"

files="$(get_files_from_remote "${remote}/" | \
    grep "${project}-[0-9]*\.[0-9]*\.[0-9][\.-]\(r[0-9]\)\?")"
versions="$(echo "${files}" | tr ' ' '\n' | rev | \
    cut -f1 -d- | rev | cut -f1-3 -d. | sort -Vur)"

for v in ${versions}
do
    printf "%-10s%s(%s|%s)  %s(%s|%s)  %s(%s|%s)\n" "${v}" \
        "<a href=\"${remote}/${project}-${v}.tar.gz\">tar.gz</a>" \
        "<a href=\"${remote}/${project}-${v}.tar.gz.sig\">s</a>" \
        "<a href=\"${remote}/${project}-${v}.tar.gz.sha1\">sha1</a>" \
        "<a href=\"${remote}/${project}-${v}.tar.bz2\">tar.bz2</a>" \
        "<a href=\"${remote}/${project}-${v}.tar.bz2.sig\">s</a>" \
        "<a href=\"${remote}/${project}-${v}.tar.bz2.sha1\">sha1</a>" \
        "<a href=\"${remote}/${project}-${v}.tar.xz\">tar.xz</a>" \
        "<a href=\"${remote}/${project}-${v}.tar.xz.sig\">s</a>" \
        "<a href=\"${remote}/${project}-${v}.tar.xz.sha1\">sha1</a>"
done

echo "</pre>"

exec 1>&6 6>&-
failed=0

for l in $(lynx -listonly -nonumbers -dump "${out}" | grep "https://distfiles")
do
    echo -n "checking ${l}... "
    curl -sSfl -A "${project}-generator" "${l}" >/dev/null

    if [ ${?} -eq 0 ]
    then
        echo "ok"
        continue
    fi

    failed=1
done

exit ${failed}
