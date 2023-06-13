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

A sanity check of a newly-installed kernel (e.g., surviving an intermediate reboot cycle ), before immediate relinking the next boot can reduce problems with untested kernels being built (or maliciously-constructed and then introduced into a system to later be loaded in as a "relinked kernel" which is not a permulation of the last one build or received from a distributed official kernel - and then immediately panicking when relinking in the lesser case and damaging or destroying the system or surreptitiously tampering with the kernel configuration and allowing a local root exploit on the next /etc/rc invocation should be avoided by correct design decisions and implementation.

Hoisting a minimal build script for the kernel and the objects is not difficult by careful dissection of the output of make or by trapping compiler and linker invocations during a build. Because make is incremental it is easy to then rebuild a new system with arbitary properties.

Having no diverse compiler choice for the base system or a simple base shell script that builds the complete system sequentially as a baseline keeps non-expert and non-interested parties from investigating how to modify the kernel to improve it. The complete stagnation of the build system and the complete removal of GCC which makes finding compiler regressions between different toolchains impossible at present without resorting to software archaeology is an odd part the situation.


Build systems of large projects are often intentionally obfuscated in industry (job security?). It is not difficult to build a kernel, just a 20 MB text listing of the same call to cc for each point in the source tree. Having a huge worldwide archive yet with only two rolling releases of less than 1 GB each to go back to as a user is a questionable practice too. Every release ever made on all architectures could easily be compiled and published as a torrent. Having old packages and ports is always valuable for comparison and for (re)bootstrapping GCC compilation for instance.

***

Further reading:

Multics lead the way with this, OpenBSD follows:

https://www.acsac.org/2002/papers/classic-multics-orig.pdf

" It is apparent that a wide range of considerations are pertinent to the engineering of security of information. Historically, the literature of computer systems has more narrowly defined the term protection to be just those security techniques that control the access of executing programs to stored information.3 An example of a protection technique is labeling of computer-stored files with lists of authorized users. Similarly, the term authentication is used for those security techniques that verify the identity of a person (or other external agent) making a request of a computer system. An example of an authentication technique is demanding a password. This paper concentrates on protection and authentication mechanisms, with only occasional reference to the other equally necessary security mechanisms. One should recognize that concentration on protection and authentication mechanisms provides a narrow view of information security, and that a narrow view is dangerous. The objective of a secure system is to prevent all unauthorized use of information, a negative kind of requirement. It is hard to prove that this negative requirement has been achieved, for one must demonstrate that every possible threat has been anticipated. Thus an expansive view of the problem is most appropriate to help ensure that no gaps appear in the strategy. In contrast, a narrow concentration on protection mechanisms, especially those logically impossible to defeat, may lead to false confidence in the system as a whole.4"

https://www.cs.virginia.edu/~evans/cs551/saltzer/





Sincerely,

C.W. Schech

