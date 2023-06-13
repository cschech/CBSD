Tue Jun 13 23:36:31 UTC 2023

# CBSD
Fork of OpenBSD (via simple examples) that patches problems with kernel relinking opening up undesirable regressions and local exploits, and that aims to provide a parallel build environment that's not self-hosted in OpenBSD and which also can be bootstrapped from the OpenBSD 7.3/amd64 release media easily with or without BSD make.

The OpenBSD "kernel relinking" process contains a flaw which can lead to both regressions and intentional problems because the signatures of the object files being relinked are not kept in sync with the kernel.

to fix this problem I propose a simple patch along these lines 

[...]

+#ost="CBSD"

+#osr="0.01"

+sha512 -h /var/db/obj.${id}.sha512 *.o lorder

cat >vers.c <<eof

[...]

in /sys/conf/newvars.sh.

as well as the removal of the "kernel reordering" in /etc/rc by default, or a check against

+sha512 -c /var/db/obj.${id}.sha512 *.o lorder 

in /etc/rc before proceeding with the re-ordering. Of course the checksums for both the kernel and the objects can just be surreptitiously updated to work around this mitigation, but that requires a different exploit path than injecting the wrong binaries without being detected.

Merely changing the compiler flags to clang for some of the emitted objects will cause the relinking to crash during "rm" and delete the root filesystem contents on boot without changing the program text of the inputs to cclang.

A sanity check of a newly-installed kernel (e.g., surviving an intermediate reboot cycle ), before immediate relinking the next boot can reduce problems with untested kernels being built and then immediately panicking when relinking.

This has been observed this month.



Sincerely,

C.W. Schech

