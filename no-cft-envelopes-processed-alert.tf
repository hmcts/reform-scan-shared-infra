module "no-cft-envelopes-processed-alert" {
  source            = "git@github.com:hmcts/cnp-module-metric-alert"
  location          = "${azurerm_application_insights.appinsights.location}"
  app_insights_name = "${azurerm_application_insights.appinsights.name}"

  enabled    = "${var.env == "prod"}"
  alert_name = "No_cft_envelopes_processed_-_Blob_Router"
  alert_desc = "Triggers when Blob Router did not process single CFT envelope in last hour within SLA."

  app_insights_query = <<EOF
let range_end = bin(now(), 1h);
let data = datatable(metric: real) [
  0,
];
data
| project timestamp = now() - 20m, metric
| make-series sum(metric) default=0 on timestamp in range(range_end - 1h, range_end, 1m)
| mvexpand sum_metric, timestamp
| project-rename count_ = sum_metric
| union (traces
|   where timestamp > ago(2h)
|   where message startswith "No Envelopes created in CFT"
|   make-series count() default=0 on timestamp in range(range_end - 1h, range_end, 1m)
|   mvexpand count_, timestamp)
| project files = toint(count_), event_time = todatetime(timestamp)
| summarize ["# files"] = sum(files), last_event = max(event_time)
| extend day_of_week = toint(substring(tostring(dayofweek(last_event)), 0, 1))
| extend last_event_time = bin(last_event % 1d, 1m) + datetime("2020-03-03")
| project ["# files"],
    interval_start = last_event_time > datetime("2020-03-03 09:59:00"),
    interval_end = last_event_time < datetime("2020-03-03 18:01:00"),
    is_weekend = day_of_week == 0 or day_of_week == 6
| project files_are_processed = ["# files"] > 0
    or not (interval_start and interval_end)
    or is_weekend
| filter files_are_processed == false
EOF

  frequency_in_minutes       = 60
  time_window_in_minutes     = 60 // does not matter - set in query
  severity_level             = "4"
  action_group_name          = "${module.alert-action-group.action_group_name}"
  custom_email_subject       = "Blob Router - No CFT envelopes processed"
  trigger_threshold_operator = "GreaterThan"
  trigger_threshold          = 0
  resourcegroup_name         = "${azurerm_resource_group.rg.name}"
}
