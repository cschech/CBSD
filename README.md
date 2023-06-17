# Background 

[1] https://www.acsac.org/2002/papers/classic-multics-orig.pdf

[2] https://www.computer.org/csdl/magazine/sp/2010/06/msp2010060005/13rRUy08MDu

# Insecurity of the OpenBSD 7.3/amd64 distribution

The automatic and mandatory-by-default reordering of OpenBSD kernels is NOT transactional and as a result, a local unpatched exploit exists which allows tampering or replacement of the kernel. Arbitrary build artifacts are cyclically relinked with no data integrity or provenance being maintained or verified for the objects being consumed with respect to the running kernel before and during the execution of the mandatory kernel_reorder process in the supplied /etc/rc and /usr/libexec scripts. The reordering occurs at the end of installation process and also automatically every reboot cycle thereafter unless manually bypassed by a knowledgable party.

The kernel_reorder routine verifies a SHA256 signature for the linked kernel from last boot but does not verify the integrity or provenance of any objects kept in the kernel "link kit" installed in /usr/share/relink, so arbitrary objects can be injected and automatically relinked at the next startup. I have verified that it is indeed the case that both valid kernels with a different uname and kernels which cause data destruction due to over-tuning of a subset of the components which were compiled manually and copied into /usr/share/relink and crash the system after being booted once relinked but which do not match the build of the running kernel at the time they were copied into /usr/share/relink as working proof-of-concept exploits.

Install media are also open to tampering and exploitation as signed checksum data are not carried with the install sets inside the installation image and an improperly-encapsulated poorly-documented tarball of unverifiable (in the sense of SLSA) kernel objects is embedded in the base distribution and then relinked with a new random ordering of the objects cyclically between boot cycles.

Sites with a strong security posture are advised that this is a critical vulnerability and likely deliberate back door into the system. Additionally, OpenBSD leaks the state of the pseudorandom number generator to predictable locations on disk and in system memory at a fixed point during every start up and shutdown procedure. The lack of build process hardening has been on-going for over three years. Theo de Raadt is disinterested in improving or reviewing the design or providing any further clarification, as he has stated on the mailing list when shortfalls in the relinking process were reported over the past ~3 years. I hope that this can come to the attention of a third-party technical expert with standing in the computer security industry.

Workaround:

As the link kit is embedded in the base distribution and automatically relinked without an option to disable it in the provided installation script it requires manual removal at present.

Cf.

https://marc.info/?l=openbsd-bugs&m=159074964523007&w=2 (noted lack of idempotency)
https://marc.info/?l=openbsd-bugs&m=168688579123005&w=2 (noted lack of integrity or provenance verification and the consumption of invalid objects)

https://slsa.dev/spec/v1.0/levels#build-l2-hosted-build-platform:

"Track/Level Requirements 	            Focus
 Build L3 	  Hardened build platform 	 Tampering during the build"


# Addendum

The official response from Theo de Raadt is that the sha256 sums solve nothing, and that I am worried about "second or third-order problems", so I guess it doesn't matter. Into the trash it goes.
