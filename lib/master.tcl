# Expects "title" and "header" and "context_bar"

if { ![info exists title] } {
    set title ""
} 

if { ![info exists header] } {
    set header $title
}

if { ![info exists context_bar] } {
    set header $context_bar
}

ad_return_template
