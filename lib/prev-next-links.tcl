# Prev/Next links
#
# Expects:
#   prev_url:onerow,optional
#   next_url:onerow,optional

multirow create links url value rownum

set rownum 0

foreach var { prev_url next_url } pretty { "[_ acs-kernel.common_Prev]" "[_ acs-kernel.common_Next]" } {
    if { [info exists $var] } {
        multirow append links [set $var] $pretty [incr rownum]
    }
}

ad_return_template
