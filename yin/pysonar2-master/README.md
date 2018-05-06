## PySonar2 - an advanced static analyzer for Python

To understand it, please refer to my blog post:

    http://yinwang0.wordpress.com/2010/09/12/pysonar


### How to build

PySonar 1.0 was part of Jython, and PySonar2 still depend on Jython's parser
(the situation may change soon). So you need to download Jython's source code
and compile PySonar2 with it.


1. Download Jython

        hg clone http://hg.python.org/jython

2. Checkout this repo, replace everything inside _src/org/python/indexer_ (which
   is PySonar 1.0) with the content of this repo

3. Delete the tests for the old indexer

        rm -rf tests/java/org/python/indexer

4. Build Jython

        ant jar-complete

5. Finished. PySonar2 is now inside _dist/jython.jar_.


### How to run?

PySonar2 is mainly designed as a library for Python IDEs and other tools, but
for your understanding of the library's usage, a demo program is built (most
credits go to Steve Yegge). To run it, use the following command line:

    java -classpath dist/jython.jar org.python.indexer.demos.HtmlDemo /usr/lib/python2.7 /usr/lib/python2.7

You should find some interactive HTML files inside the _html_ directory
generated after this process.

Note: PySonar2 doesn't need much memory to do analysis (1GB is probably enough),
but for generating the HTML files, you may need a lot of memory (~4GB for
Python 2.5 standard lib). This is due to the highlighting I added without using
more sophisticated ways of doing it. The situation may change soon.
