.macro jlabel label
    glabel \label
.endm

.macro glabel label
    .global \label
    \label:
.endm

.macro dlabel label
    .global \label
    \label:
.endm

.macro .def #
.endm



.macro move a, b
    addu \a, \b, $zero
.endm

.include "gte.inc"

