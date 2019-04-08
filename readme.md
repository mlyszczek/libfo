[kursg-meta]: # (order: 1)

Synopsis
========

**libfo** is a tiny library that allows user to simulate errors of **POSIX** and
**libc** functions.

Description
===========

When testing software it's often that ones find it very hard or even impossible
to test some error conditions, especially when it comes to **POSIX** or **libc**
functions. Now how would you test if **socket**() fails? You would have to first
create tons of file descriptors so kernel wouldn't allocate you anymore. It also
might be hard to simulate error of **write**() function in some scenarios.

Now thanks to **libfo** your problem can be solved really easy. **libfo**
consists only of 2 (yes, *two*) functions, and one of them is init function.
Library does not required you to make **any** changed to production code, all
magic is done in test suite.

* [fo_init](https://libfo.kurwinet.pl/manuals/fo_init.1.html)(3) - initializes
  everything, need to be called as early as possible, best to call it right
  after **main**().
* [fo_fail](https://libfo.kurwinet.pl/manuals/fo_fail.1.html)(3) - configures
  how, when and what function should fail.

Small example:

~~~{.c}
/* production-file.c
 */

int store_to_file(const char *f, const char *s)
{
    int fd;
    int w;

    if ((fd = open(f, O_CREAT | O_TRUNC | O_RDWR, 0666)) < 0)
    {
        perror("open()");
        return -1;
    }

    w = write(fd, s, strlen(s));
    if (w == -1)
    {
        /* write() error
         */

         run_diagnostics();
         return -1;
    }

    if (w != strlen(s))
    {
        /* incomplete write
         */

         close(fd);
         unlink(f);
         return -1;
    }

    if (write(fd, "\n", 1) != 1)
    {
        /* failed to store newline
         */

         close(fd);
         unlink(f);
         return -1;
    }

    return 0;
}

/* test-suite.c
 */
void foo(void)
{
    /* open() is very easy to check, just pass file that doesn't
     * exit and expect function to return -1 and ENOENT errno
     */
    mt_ferr(store_to_file("/file/that/doesnt/exist", "message"), ENOENT);

    /* install point of failure. After fo_fail(), next write() will
     * fail returning -1 and errno will be set to EIO.
     */
    fo_fail(fo_write, 1, -1, EIO);
    mt_ferr(store_to_file("/tmp/file", "message"), EIO);

    /* now let's emulate partial write. write() will return with
     * value 4, and errno set to ENOSPC, emulating that there is
     * not enough space on disk.
     */
    fo_fail(fo_write, 1, 4, ENOSPC);
    mt_fail(store_to_file("/tmp/file", "message") == 4);
    mt_fail(errno == ENOSPC);

     /* by setting countdown (second argument) we can configure
      * when write() shall fail. Setting it to 1, will cause first
      * (and only first) call to write fail. We can sent it to 2,
      * causing first write() to succed and second to return error.
      * So now we can simulate correct data write, but fail to
      * store last new line character
      */
    fo_fail(fo_write, 2, -1, ENOSPC);
    mt_ferr(store_to_file("/tmp/file", "message"), ENOSPC);
}
~~~

Now testing such code could be very, if not impossible to test. It could be
really difficult to make **write**() to return -1 once **open**() succeed. And
not testing such scenario might be painful - notice there is little bug there,
when file descriptor is not closed when **write**() returns -1.

Of course, one needs to also realize its limitations. Notice that when partial
write error is simulated, POSIX **write**() will not be called, and even though
**write**() returns 4 (which leads program to belive some data were stored) no
data were really stored, because no real **write**() has been called at all that
time. This however could be solved by modifying **write**() functions in
**fo.c** file to call **write**() with *count* 4, and then return.

Usage
=====

Convinced? I'm glad. I don't like repeating myself, so to know more about
library itself and how to use it, please check
[libfo](https://libfo.kurwinet.pl/manuals/libfo.7.html)(7) manual page.

Installing
==========

Package can be installed to system with classic (which accepts DESTDIR envvar)

~~~
make install
~~~

This will install only **fogen** program and manual pages for quick access.

Downloads
=========

Released prebuild libraries and source tarballs can be downloaded from
[https://libfo.kurwinet.pl/downloads.html](https://libfo.kurwinet.pl/downloads.html)

Dependencies
============

Generated code is c99 compliant but requires **RTLD_NEXT** special handle for
dlsym which may not be supported on all operating systems.

License
=======

Library is licensed under BSD 2-clause license. See LICENSE file for details.
So yeah, feel free to use it anyway you see fit.

Contact
=======

Michał Łyszczek <michal.lyszczek@bofc.pl>

* [mtest](http://mtest.kurwinet.pl) unit test framework **libfo** uses
* [git repository](http://git.kurwinet.pl/libfo) to browse code online
