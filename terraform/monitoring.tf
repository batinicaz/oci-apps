resource "oci_monitoring_alarm" "object_storage_size" {
  compartment_id        = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  display_name          = "${var.name}-storage-size"
  is_enabled            = true
  metric_compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  namespace             = "oci_objectstorage"
  severity              = "WARNING"

  destinations = [data.terraform_remote_state.oci_core.outputs.notification_topic_id]

  query = "StoredBytes[1h]{resourceId = \"${oci_objectstorage_bucket.this.name}\"}.max() > ${15 * 1024 * 1024 * 1024}"

  body                                          = "Object Storage bucket ${oci_objectstorage_bucket.this.name} has exceeded 15 GB (free tier limit: 20 GB)"
  message_format                                = "RAW"
  pending_duration                              = "PT1H"
  repeat_notification_duration                  = "PT24H"
  is_notifications_per_metric_dimension_enabled = false

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "${var.name}-storage-size"
  })
}

resource "oci_monitoring_alarm" "object_storage_count" {
  compartment_id        = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  display_name          = "${var.name}-object-count"
  is_enabled            = true
  metric_compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  namespace             = "oci_objectstorage"
  severity              = "WARNING"

  destinations = [data.terraform_remote_state.oci_core.outputs.notification_topic_id]

  query = "ObjectCount[1h]{resourceId = \"${oci_objectstorage_bucket.this.name}\"}.max() > 500"

  body                                          = "Object Storage bucket ${oci_objectstorage_bucket.this.name} has exceeded 500 objects - possible version leak or backup growth"
  message_format                                = "RAW"
  pending_duration                              = "PT1H"
  repeat_notification_duration                  = "PT24H"
  is_notifications_per_metric_dimension_enabled = false

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "${var.name}-object-count"
  })
}

resource "oci_monitoring_alarm" "feed_broken" {
  compartment_id        = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  display_name          = "${var.name}-feed-broken"
  is_enabled            = true
  metric_compartment_id = data.terraform_remote_state.oci_core.outputs.terraform_identity_compartment_id
  namespace             = "rss_feed_health"
  severity              = "CRITICAL"

  destinations = [data.terraform_remote_state.oci_core.outputs.notification_topic_id]

  query = "feed_broken[6h].min() > 0"

  is_notifications_per_metric_dimension_enabled = true
  pending_duration                              = "PT1M"
  message_format                                = "ONS_OPTIMIZED"
  notification_title                            = "{{dimensions.feed}}"
  alarm_summary                                 = "RSS feed {{dimensions.feed}} is {{status}}"
  body                                          = "Hourly FreshRSS feed check. FIRING: the feed returned a non-200, no items, or mostly failed full-text extraction on every check for 6 hours. OK: it has recovered."

  defined_tags = merge(local.default_tags, {
    "terraform.name" = "${var.name}-feed-broken"
  })
}
