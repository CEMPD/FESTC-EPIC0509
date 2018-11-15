#! /bin/sh
FESTC_HOME=.
cd $FESTC_HOME/plugins/bootstrap

if [ "`uname -m`" = "ia64" ]; then
  JAVA=/usr/java/jdk1.6.0_13/bin/java
  JAVAMAXMEM="-Xmx6000M"
else
  JAVA=../../jre/bin/java
  JAVAMAXMEM="-Xmx1024M"
fi

# Limit the number of default spawned threads (eca):
JAVAOPTS="-XX:+UseParallelGC -XX:ParallelGCThreads=1"

JAVACMD="$JAVA $JAVAOPTS $JAVAMAXMEM -classpath ./bootstrap.jar:./lib/saf.core.runtime.jar:./lib/jpf.jar:./lib/jpf-boot.jar:../core/lib/* saf.core.runtime.Boot"

$JAVACMD $*
