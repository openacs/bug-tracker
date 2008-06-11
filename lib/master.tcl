# Expects "title" and "header" and "context_bar"

if { ![info exists title] } {
    set title ""
} 

if { ![info exists header] } {
    set header $title
}

if { ![info exists notification_link] } {
    set notification_link ""
}

template::head::add_css -href /resources/bug-tracker/bug-tracker.css -media all

ad_return_template
