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
