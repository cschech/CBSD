
PHDRS {
	text PT_LOAD FILEHDR PHDRS;
	rodata PT_LOAD;
	data PT_LOAD;
	bss PT_LOAD;
}

SECTIONS {
	.text : ALIGN(4096) {
		LONG(0xcccccccc);
		. += 10071;
		. = ALIGN(4096);
		endboot = .;
		PROVIDE (endboot = .);
		. = ALIGN(4096);
		. += 3413;
		. = ALIGN(16);
		*(.text .text.*)
	} :text =0xcccccccc

	.rodata : {
		LONG(0xcccccccc);
		. += 3111;
		. = ALIGN(16);
		*(.rodata .rodata.*)
	} :rodata =0xcccccccc

	.data : {
		LONG(0xcccccccc);
		. = . + 1383;	/* fragment of page */
		. = ALIGN(16);
		*(.data .data.*)
	} :data =0xcccccccc

	.bss : {
		. = . + 4025;	/* fragment of page */
		. = ALIGN(16);
		*(.bss .bss.*)
	} :bss
}
