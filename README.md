Wed Jun 14 23:40:21 UTC 2023

# Abstract 

Every time a new version ("release" in OpenBSD parlance) of Unix is created, it needs to be stamped as authentic, otherwise it's just a glorified computer worm susceptible to attack as indicated by Paul Karger (the topic of Dennis Richie's popular ACM lecture) masquerading as an operating system that people are trying to do genetic engineering (or perhaps hopelessly, analysis) on. 

This avoids a circular specification of the operating system where it is defined as its implementation. As a demonstrative example the author provides (in this repository) a new version of the BSD operating system kernel (CBSD) that is not an OpenBSD kernel but which will be reordered by the OpenBSD 7.3 release reorder_kernel utility as it currently exists (which does not check that it has been stamped) and installed as a new kernel during the next boot, and a patch to the script that creates the new version of BSD during the build which adds such a stamp. As the objects provided in the link kit are opaque they should (at a minimum) be discarded and the system built from source, but it is not sufficient by itself in a self-hosted environment in the general case when considering sophisticated attackers. 

The core problem with OpenBSD's implementation of kernel reordering is that the operating system is viewed at the link-level as a collection of components and as a monolithic binary during runtime which are two seperate levels of abstraction, leading to this security flaw, where attempting to relink at runtime without checking that the objects match the stamp from the release allows relinking of an arbitrary computer program with the same link structure.

If the OpenBSD kernel_reorder utility instead checked the stamp created when the release was created, for all kernel objects /usr/share/relink/kernel/$BUILD, this security vulnerability would be closed.

# Summary 

The link kit distributed with OpenBSD when paired with the existing reorder_kernel function (which lacks such a check) as of OpenBSD 7.3 allows the installation of a rootkit for anyone with local access to the machine, or the creator of the link kit provided on the installation media, or by tampering with the installation media. A link kit that is stamped does not suffer from this class of vulnerability in the restricted case of tampering with local access to the machine or the installation media, but a trusted external build environment is required to rule out that the creator of the initial link kit did not install a trojan horse. As GCC support was conspicuously dropped, this difficult for those without access to historical copies of the release media and source distributions. OpenBSD's official installation media notably lacks the signature and checksum for the base installation sets.

# Areas for Further Study

The source of OpenBSD is tied to a specific bundled clang implementation that is self-hosted. Lack of an external build environment with first-party support makes it impossible to verify if the link kit provided with OpenBSD is not a trojan horse. GCC support was also dropped and eliminated from the source tree. Having both GCC and clang support for the kernel build process (that is self-hosted) would be an excellent first step toward support for a portable build environment hosted externally to the system.

Portable bootstrapping from another vendor's POSIX environment or a mobile programming system (the concept behind Waite's STAGE2) is instead desirable.


Cf. 

https://dwheeler.com/trusting-trust/

https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=31bb1c092dba2b1a692b87cd2ff859bb7ce735f7

--

Tue Jun 13 23:36:31 UTC 2023

# CBSD
Fork of OpenBSD (via simple examples) that patches problems with kernel relinking opening up undesirable regressions and local exploits, and that aims to provide a parallel build environment that's not self-hosted in OpenBSD and which also can be bootstrapped from the OpenBSD 7.3/amd64 release media easily with or without BSD make.

***

# Further reading:

Multics lead the way with this, OpenBSD follows:

https://www.acsac.org/2002/papers/classic-multics-orig.pdf

" It is apparent that a wide range of considerations are pertinent to the engineering of security of information. Historically, the literature of computer systems has more narrowly defined the term protection to be just those security techniques that control the access of executing programs to stored information.3 An example of a protection technique is labeling of computer-stored files with lists of authorized users. Similarly, the term authentication is used for those security techniques that verify the identity of a person (or other external agent) making a request of a computer system. An example of an authentication technique is demanding a password. This paper concentrates on protection and authentication mechanisms, with only occasional reference to the other equally necessary security mechanisms. One should recognize that concentration on protection and authentication mechanisms provides a narrow view of information security, and that a narrow view is dangerous. The objective of a secure system is to prevent all unauthorized use of information, a negative kind of requirement. It is hard to prove that this negative requirement has been achieved, for one must demonstrate that every possible threat has been anticipated. Thus an expansive view of the problem is most appropriate to help ensure that no gaps appear in the strategy. In contrast, a narrow concentration on protection mechanisms, especially those logically impossible to defeat, may lead to false confidence in the system as a whole.4"

https://www.cs.virginia.edu/~evans/cs551/saltzer/

# My initial bug report to Theo:

https://marc.info/?l=openbsd-bugs&m=159074964523007&w=2
