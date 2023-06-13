# CBSD
Fork of OpenBSD (via simple examples) that patches problems with kernel relinking opening up undesirable regressions and local exploits, and that aims to provide a parallel build environment that's not self-hosted in OpenBSD and which also can be bootstrapped from the OpenBSD 7.3/amd64 release media easily with or without BSD make.

The OpenBSD "kernel relinking" process contains a flaw which can lead to both regressions and intentional problems because the signatures of the object files being relinked are not kept in sync with the kernel.

to fix this problem I propose a simple patch along these lines 

#       and enable POOL_DEBUG in sys/conf/GENERIC
#       A month or so before release, select STATUS "-beta"
#       and disable POOL_DEBUG in sys/conf/GENERIC

[...]

+#ost="CBSD"
+#osr="0.01"

+sha512 -h /var/db/obj.${id}.sha512 *.o lorder


in conf/newvars.sh 

and the removal of the "kernel reordering" in /etc/rc by default, or a check against

+sha512 -c /var/db/obj.${id}.sha512 *.o lorder 

in /etc/rc before proceeding with the re-ordering.

Sincerely,

C.W. Schech


