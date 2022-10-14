# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#===================================================================================================
#
# This PortGroup defines a debugoptimized variant, for ports not based on CMake, Meson, etc.
#
# Usage:
#   PortGroup               debugoptimized 1.0
#
#===================================================================================================

namespace eval debugoptimized {}

if { [variant_exists debugoptimized] } {
    error "pg_debugoptimized: variant 'debugoptimized' already exists"
}

default debugoptimized.configure \
    [list \
        cflags \
        cppflags \
        cxxflags \
        objcflags \
        objcxxflags \
        fflags \
        f90flags \
        fcflags \
    ]

default debugoptimized.flags.delete \
    [list]

default debugoptimized.flags.add \
    [list -g]

ui_debug "pg_debugoptimized: adding variant"
variant debugoptimized description {Enable debug flags and symbols while building optimized code} {}

proc debugoptimized::setup_debugoptimized {} {
    ui_debug "debugoptimized::setup_debugoptimized: configuring for debug optimized build"

    set conf_names   [option debugoptimized.configure]
    set flags_delete [option debugoptimized.flags.delete]
    set flags_add    [option debugoptimized.flags.add]

    foreach c ${conf_names} {
        foreach f ${flags_delete} {
            configure.${c}-delete ${f}
        }

        foreach f ${flags_add} {
            configure.${c}-append ${f}
        }
    }

    post-destroot {
        debugoptimized::post_destroot
    }
}

proc debugoptimized::post_destroot {} {
    global destroot prefix

    ui_debug "debugoptimized::post_destroot: Generating the .dSYM bundles"
    system -W ${destroot}${prefix} "find . -type f '(' -name '*.dylib' -or -name '*.so' ')' -exec dsymutil {} +"
}

proc debugoptimized::pg_callback {} {
    set debugoptimized_enabled [variant_isset debugoptimized]
    ui_debug "debugoptimized::pg_callback: debugoptimized enabled: ${debugoptimized_enabled}"

    if { ${debugoptimized_enabled} } {
        debugoptimized::setup_debugoptimized
    }
}

# callback after port is parsed
port::register_callback debugoptimized::pg_callback

variant debug conflicts debugoptimized description "Use debug or debugoptimized, not both" {}
variant debugoptimized conflicts debug description "Use debug or debugoptimized, not both" {}
